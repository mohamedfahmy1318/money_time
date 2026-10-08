package com.example.money_time.bankcapture

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.Executors

/**
 * `money_time/bank_capture` — the Dart side arms, updates and clears the
 * background capture here, and reads the device inbox for the 30-day scan.
 * Native → Dart: `onCaptured` after a delivery, `onNeedsToken` when the
 * server revoked the token (only while the app is running).
 */
object BankCapturePlugin : MethodChannel.MethodCallHandler {
    private const val CHANNEL = "money_time/bank_capture"

    private var channel: MethodChannel? = null
    private var appContext: Context? = null
    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()

    fun attach(messenger: BinaryMessenger, context: Context) {
        appContext = context.applicationContext
        channel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(this) }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    fun notifyCaptured() = main.post { channel?.invokeMethod("onCaptured", null) }

    fun notifyNeedsToken() = main.post { channel?.invokeMethod("onNeedsToken", null) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = appContext ?: return result.error("UNAVAILABLE", "Not attached", null)
        val config = CaptureConfig(context)
        when (call.method) {
            "configure" -> {
                try {
                    config.configure(
                        baseUrl = call.argument<String>("baseUrl") ?: return result.error("ARGS", "baseUrl", null),
                        token = call.argument<String>("ingestToken") ?: return result.error("ARGS", "ingestToken", null),
                        senders = call.argument<List<String>>("senders") ?: emptyList(),
                        deviceId = call.argument<String>("deviceId") ?: "",
                        language = call.argument<String>("language") ?: "ar",
                    )
                } catch (e: Exception) {
                    // Keystore trouble: the app re-issues the token later.
                    return result.error("KEYSTORE_FAILED", e.javaClass.simpleName, null)
                }
                // Anything held back by a revoked token goes out now.
                if (CaptureQueue(context).size() > 0) IngestWorker.enqueue(context)
                result.success(null)
            }
            "updateSenders" -> {
                config.update(
                    senders = call.argument<List<String>>("senders") ?: emptyList(),
                    language = call.argument<String>("language"),
                )
                result.success(null)
            }
            "clear" -> {
                IngestWorker.cancel(context)
                CaptureQueue(context).clear()
                config.clear()
                result.success(null)
            }
            "flush" -> {
                if (config.isConfigured) IngestWorker.enqueue(context)
                result.success(null)
            }
            "status" -> result.success(
                mapOf(
                    "configured" to config.isConfigured,
                    "queued" to CaptureQueue(context).size(),
                    "needsToken" to config.needsToken,
                ),
            )
            "readInbox" -> {
                val sinceMs = (call.argument<Number>("sinceMs") ?: 0).toLong()
                val senders = (call.argument<List<String>>("senders") ?: emptyList())
                    .map { it.trim().lowercase(Locale.ROOT) }
                    .toSet()
                io.execute {
                    try {
                        val rows = SmsInbox.read(context, sinceMs, senders)
                        main.post { result.success(rows) }
                    } catch (e: SecurityException) {
                        main.post { result.error("PERMISSION_DENIED", e.message, null) }
                    } catch (e: Exception) {
                        main.post { result.error("READ_FAILED", e.message, null) }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }
}
