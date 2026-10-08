package com.example.money_time.bankcapture

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.telephony.SmsMessage
import java.util.UUID

/**
 * Live capture: every incoming SMS passes through here, even with the app
 * killed. Only messages from the linked banks' senders are kept — personal
 * texts are never stored or sent. Multipart SMS are joined into one body,
 * queued with a fresh Idempotency-Key, and handed to [IngestWorker].
 */
class BankSmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        val config = CaptureConfig(context)
        if (!config.isConfigured) return

        // Never let a malformed PDU or corrupt prefs crash the process on
        // every incoming text: an exception here is dropped, not fatal.
        val queued = try {
            collect(intent, config)
        } catch (e: Exception) {
            emptyList()
        }
        if (queued.isEmpty()) return

        // Persisting and scheduling happen off the main thread, and goAsync
        // keeps the process alive until WorkManager has written the request.
        val pending = goAsync()
        Thread {
            try {
                val queue = CaptureQueue(context)
                queued.forEach(queue::add)
                IngestWorker.enqueue(context).result.get()
            } catch (e: Exception) {
                // Already in the queue: the next SMS or app open delivers it.
            } finally {
                pending.finish()
            }
        }.start()
    }

    /** The linked banks' messages in this broadcast, multipart joined. */
    private fun collect(intent: Intent, config: CaptureConfig): List<QueuedSms> {
        val parts = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return emptyList()
        val bySender = LinkedHashMap<String, MutableList<SmsMessage>>()
        for (part in parts) {
            val address = part.originatingAddress ?: part.displayOriginatingAddress ?: continue
            if (!config.matchesSender(address)) continue
            bySender.getOrPut(address) { mutableListOf() }.add(part)
        }
        val now = System.currentTimeMillis()
        return bySender.mapNotNull { (sender, messageParts) ->
            val body = messageParts.joinToString("") { it.messageBody ?: "" }.trim()
            if (body.isEmpty()) return@mapNotNull null
            QueuedSms(
                key = UUID.randomUUID().toString(),
                sender = sender.trim(),
                body = body.take(MAX_BODY),
                // Service-centre time (the scan reads the same value,
                // date_sent) unless it is ahead of the clock — see SmsTime.
                timestampMs = SmsTime.pick(
                    sentMs = messageParts.first().timestampMillis,
                    receivedMs = now,
                ),
            )
        }
    }

    private companion object {
        const val MAX_BODY = 2000
    }
}
