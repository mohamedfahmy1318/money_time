package com.example.money_time.bankcapture

import android.content.Context
import android.provider.Telephony
import java.util.Locale

/**
 * Reads bank SMS already on the device for the wizard's "import the last 30
 * days" (needs READ_SMS). Only rows from [senders] are returned. The device
 * inbox already stores multipart messages joined.
 */
internal object SmsInbox {
    fun read(context: Context, sinceMs: Long, senders: Set<String>): List<Map<String, Any>> {
        val rows = mutableListOf<Map<String, Any>>()
        val projection = arrayOf(
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
            Telephony.Sms.DATE_SENT,
        )
        context.contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            projection,
            "${Telephony.Sms.DATE} >= ?",
            arrayOf(sinceMs.toString()),
            "${Telephony.Sms.DATE} DESC",
        )?.use { cursor ->
            var scanned = 0
            // Newest first; a 30-day window on a busy phone is a few thousand
            // rows at most, so this only guards against pathological inboxes.
            while (cursor.moveToNext() && scanned++ < MAX_ROWS) {
                val address = cursor.getString(0)?.trim() ?: continue
                if (address.lowercase(Locale.ROOT) !in senders) continue
                val body = cursor.getString(1)?.trim().orEmpty()
                if (body.isEmpty()) continue
                val received = cursor.getLong(2)
                val sent = cursor.getLong(3)
                rows.add(
                    mapOf(
                        "sender" to address,
                        "body" to body.take(2000),
                        // Same choice as the live receiver — see SmsTime.
                        "timestampMs" to SmsTime.pick(sentMs = sent, receivedMs = received),
                    ),
                )
            }
        }
        return rows
    }

    private const val MAX_ROWS = 10_000
}
