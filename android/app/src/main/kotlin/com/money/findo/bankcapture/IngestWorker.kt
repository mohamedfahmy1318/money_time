package com.money.findo.bankcapture

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.Operation
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit

/**
 * Delivers queued SMS to `POST /bank-sync/ingest` with the ingest token —
 * never the user JWT, which is usually expired in the background and whose
 * refresh could race the foreground app.
 *
 * Retries reuse each item's Idempotency-Key and body, so a timeout never
 * books a message twice. Outcomes follow the integration guide: 202 removes
 * the item; 401 keeps the queue until the app re-issues the token; 409
 * NOT_CONNECTED drops it and stops capture; 4xx input errors drop the item;
 * 429, 5xx and network errors retry with backoff.
 */
class IngestWorker(context: Context, params: WorkerParameters) : Worker(context, params) {

    private enum class Outcome { DELIVERED, DROP, TOKEN_REVOKED, DISCONNECTED, UPGRADE, RETRY }

    override fun doWork(): Result {
        val config = CaptureConfig(applicationContext)
        val queue = CaptureQueue(applicationContext)
        val baseUrl = config.baseUrl ?: return Result.success()
        val stamp = config.tokenStamp
        val token = config.token ?: return Result.success()
        if (config.needsToken) return Result.success()
        val appVersion = CaptureConfig.appVersion(applicationContext)

        var delivered = 0
        for (item in queue.all()) {
            // Cancelled (sign-out / disconnect cleared everything): stop
            // touching prefs that may just have been wiped.
            if (isStopped) return Result.success()
            when (post(baseUrl, token, appVersion, config, item)) {
                Outcome.DELIVERED -> {
                    queue.remove(item.key)
                    delivered++
                }
                Outcome.DROP -> queue.remove(item.key)
                Outcome.TOKEN_REVOKED -> {
                    // A re-issue that raced this run already replaced the
                    // token and queued another drain behind us; only a 401 on
                    // the token still stored means it was really revoked.
                    if (config.markNeedsToken(stamp)) BankCapturePlugin.notifyNeedsToken()
                    return done(delivered)
                }
                Outcome.DISCONNECTED -> {
                    queue.clear()
                    config.clear()
                    return done(delivered)
                }
                Outcome.UPGRADE -> return done(delivered)
                Outcome.RETRY -> {
                    if (delivered > 0) BankCapturePlugin.notifyCaptured()
                    return Result.retry()
                }
            }
        }
        return done(delivered)
    }

    private fun done(delivered: Int): Result {
        if (delivered > 0) BankCapturePlugin.notifyCaptured()
        return Result.success()
    }

    private fun post(
        baseUrl: String,
        token: String,
        appVersion: String,
        config: CaptureConfig,
        item: QueuedSms,
    ): Outcome {
        val payload = JSONObject()
            .put("sender", item.sender)
            .put("body", item.body)
            .put("received_at", iso(item.timestampMs))
            .put("channel", "android_sms")
            .toString()
            .toByteArray(Charsets.UTF_8)

        val connection = try {
            URL("$baseUrl/bank-sync/ingest").openConnection() as HttpURLConnection
        } catch (e: IOException) {
            return Outcome.RETRY
        }
        return try {
            connection.apply {
                requestMethod = "POST"
                connectTimeout = 5_000
                readTimeout = 10_000
                doOutput = true
                setRequestProperty("Authorization", "Bearer $token")
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Accept", "application/json")
                setRequestProperty("Idempotency-Key", item.key)
                setRequestProperty("Accept-Language", config.language)
                setRequestProperty("X-Platform", "android")
                setRequestProperty("X-App-Version", appVersion)
                setRequestProperty("X-Device-Id", config.deviceId)
                setFixedLengthStreamingMode(payload.size)
            }
            connection.outputStream.use { it.write(payload) }

            val status = connection.responseCode
            val errorCode = if (status >= 400) errorCode(connection) else null
            when {
                status in 200..299 -> Outcome.DELIVERED
                status == 401 -> Outcome.TOKEN_REVOKED
                status == 409 && errorCode == "NOT_CONNECTED" -> Outcome.DISCONNECTED
                status == 426 -> Outcome.UPGRADE
                status == 429 || status >= 500 -> Outcome.RETRY
                // 400/409 mismatch/413/422 (SENDER_NOT_LINKED, VALIDATION_FAILED):
                // resending the same request can't succeed.
                else -> Outcome.DROP
            }
        } catch (e: IOException) {
            Outcome.RETRY
        } finally {
            connection.disconnect()
        }
    }

    private fun errorCode(connection: HttpURLConnection): String? = try {
        val text = connection.errorStream?.bufferedReader()?.use { it.readText() }
        text?.let { JSONObject(it).optJSONObject("error")?.optString("code") }
    } catch (e: Exception) {
        null
    }

    private fun iso(timestampMs: Long): String =
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
            .apply { timeZone = TimeZone.getTimeZone("UTC") }
            .format(Date(timestampMs))

    companion object {
        private const val UNIQUE_WORK = "money_time_bank_sms_ingest"

        /** Appends behind a running drain so an SMS arriving mid-run isn't missed. */
        fun enqueue(context: Context): Operation {
            val request = OneTimeWorkRequestBuilder<IngestWorker>()
                .setConstraints(
                    Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build(),
                )
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
                .build()
            return WorkManager.getInstance(context.applicationContext)
                .enqueueUniqueWork(UNIQUE_WORK, ExistingWorkPolicy.APPEND_OR_REPLACE, request)
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context.applicationContext).cancelUniqueWork(UNIQUE_WORK)
        }
    }
}
