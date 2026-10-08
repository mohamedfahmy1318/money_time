package com.example.money_time.bankcapture

/**
 * Which SMS timestamp to report as `received_at`.
 *
 * The service-centre time (`SmsMessage.timestampMillis`, the provider's
 * `date_sent`) is preferred: the live receiver and the 30-day scan both see
 * the same value, so the server's minute-level duplicate check matches across
 * the two paths. Some SMSCs stamp it with a wrong zone offset, though (the
 * emulator's modem ignores Cairo DST, for one). A send time ahead of the
 * device clock is impossible, so that case falls back to the device time —
 * `System.currentTimeMillis()` in the receiver, the provider's `date` in the
 * scan, which the default SMS app set at the same moment.
 */
internal object SmsTime {
    private const val MAX_AHEAD_MS = 5 * 60 * 1000L

    fun pick(sentMs: Long, receivedMs: Long): Long =
        if (sentMs > 0 && sentMs <= receivedMs + MAX_AHEAD_MS) sentMs else receivedMs
}
