package com.example.money_time.bankcapture

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** One captured SMS waiting for delivery, with its own Idempotency-Key. */
internal data class QueuedSms(
    val key: String,
    val sender: String,
    val body: String,
    val timestampMs: Long,
)

/**
 * Persistent delivery queue. Each SMS is written here (with a fresh
 * Idempotency-Key) before any network call, so a process death or an
 * offline phone never loses one; the worker removes it once the server
 * confirms. Shared by the receiver and the worker in the same process.
 */
internal class CaptureQueue(context: Context) {
    private val prefs = context.applicationContext
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun add(item: QueuedSms) = synchronized(LOCK) {
        val items = read().toMutableList()
        if (items.none { it.key == item.key }) items.add(item)
        // Bounded both ways: a phone stuck on a revoked token for months
        // shouldn't keep a pile of old bank texts around.
        val oldest = System.currentTimeMillis() - MAX_AGE_MS
        write(items.filter { it.timestampMs >= oldest }.takeLast(MAX_ITEMS))
    }

    fun all(): List<QueuedSms> = synchronized(LOCK) { read() }

    fun remove(key: String) = synchronized(LOCK) {
        write(read().filterNot { it.key == key })
    }

    fun size(): Int = synchronized(LOCK) { read().size }

    fun clear() = synchronized(LOCK) {
        prefs.edit().remove(KEY_ITEMS).commit()
        Unit
    }

    private fun read(): List<QueuedSms> {
        val raw = prefs.getString(KEY_ITEMS, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { i ->
                val o = array.getJSONObject(i)
                QueuedSms(
                    key = o.getString("key"),
                    sender = o.getString("sender"),
                    body = o.getString("body"),
                    timestampMs = o.getLong("ts"),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun write(items: List<QueuedSms>) {
        val array = JSONArray()
        items.forEach {
            array.put(
                JSONObject()
                    .put("key", it.key)
                    .put("sender", it.sender)
                    .put("body", it.body)
                    .put("ts", it.timestampMs),
            )
        }
        // commit(): the receiver's process may die right after onReceive.
        prefs.edit().putString(KEY_ITEMS, array.toString()).commit()
    }

    private companion object {
        const val PREFS = "money_time_bank_queue"
        const val KEY_ITEMS = "items"
        const val MAX_ITEMS = 500
        const val MAX_AGE_MS = 30L * 24 * 60 * 60 * 1000
        val LOCK = Any()
    }
}
