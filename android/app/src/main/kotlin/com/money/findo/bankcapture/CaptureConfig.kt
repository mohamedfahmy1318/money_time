package com.money.findo.bankcapture

import android.content.Context
import android.content.pm.PackageManager
import org.json.JSONArray
import org.json.JSONException
import java.util.Locale

/**
 * Everything the background capture needs without Flutter running: where to
 * post, the (Keystore-encrypted) ingest token, the linked banks' sender ids
 * and the request headers. Written by the app through the method channel.
 */
internal class CaptureConfig(context: Context) {
    private val prefs = context.applicationContext
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    val baseUrl: String? get() = prefs.getString(KEY_BASE_URL, null)

    /** Decrypts through the Keystore — only the worker needs this. */
    val token: String?
        get() = prefs.getString(KEY_TOKEN, null)?.let(TokenCipher::decrypt)

    /**
     * The stored ciphertext, unique per [configure] (random IV). The worker
     * keeps the one it started with so a 401 from a token that was replaced
     * meanwhile doesn't flag the fresh one as revoked.
     */
    val tokenStamp: String? get() = prefs.getString(KEY_TOKEN, null)

    val deviceId: String get() = prefs.getString(KEY_DEVICE_ID, "") ?: ""
    val language: String get() = prefs.getString(KEY_LANGUAGE, "ar") ?: "ar"

    /** Lower-cased, trimmed sender ids of the linked banks. */
    val senders: Set<String>
        get() {
            val raw = prefs.getString(KEY_SENDERS, null) ?: return emptySet()
            return try {
                val array = JSONArray(raw)
                (0 until array.length()).map { array.getString(it) }.toSet()
            } catch (e: JSONException) {
                emptySet()
            }
        }

    /** The server rejected the stored token; the app decides what to do. */
    val needsToken: Boolean get() = prefs.getBoolean(KEY_NEEDS_TOKEN, false)

    /** Flags the token revoked — unless it is no longer the one in [stamp]. */
    fun markNeedsToken(stamp: String?): Boolean {
        if (stamp == null || tokenStamp != stamp) return false
        prefs.edit().putBoolean(KEY_NEEDS_TOKEN, true).apply()
        return true
    }

    /** Cheap (no Keystore round-trip): runs for every SMS the phone gets. */
    val isConfigured: Boolean get() = baseUrl != null && prefs.contains(KEY_TOKEN)

    /** Exact, trimmed, case-insensitive — the same match the server applies. */
    fun matchesSender(address: String?): Boolean {
        val normalized = address?.trim()?.lowercase(Locale.ROOT) ?: return false
        return normalized.isNotEmpty() && normalized in senders
    }

    /** Throws when the Keystore can't seal the token (the caller reports it). */
    fun configure(
        baseUrl: String,
        token: String,
        senders: List<String>,
        deviceId: String,
        language: String,
    ) {
        val sealed = TokenCipher.encrypt(token)
        prefs.edit()
            .putString(KEY_BASE_URL, baseUrl.trimEnd('/'))
            .putString(KEY_TOKEN, sealed)
            .putString(KEY_SENDERS, normalized(senders))
            .putString(KEY_DEVICE_ID, deviceId)
            .putString(KEY_LANGUAGE, language)
            .putBoolean(KEY_NEEDS_TOKEN, false)
            .apply()
    }

    /** Linked senders and UI language follow the app without a new token. */
    fun update(senders: List<String>, language: String?) {
        prefs.edit()
            .putString(KEY_SENDERS, normalized(senders))
            .apply { if (language != null) putString(KEY_LANGUAGE, language) }
            .apply()
    }

    fun clear() {
        prefs.edit().clear().apply()
    }

    private fun normalized(senders: List<String>): String =
        JSONArray(senders.map { it.trim().lowercase(Locale.ROOT) }.filter { it.isNotEmpty() }.distinct())
            .toString()

    companion object {
        private const val PREFS = "money_time_bank_capture"
        private const val KEY_BASE_URL = "base_url"
        private const val KEY_TOKEN = "ingest_token"
        private const val KEY_SENDERS = "senders"
        private const val KEY_DEVICE_ID = "device_id"
        private const val KEY_LANGUAGE = "language"
        private const val KEY_NEEDS_TOKEN = "needs_token"

        /**
         * `X-App-Version` as the Flutter side sends it (`version+buildNumber`),
         * read at request time so an app update is never reported with the
         * version that connected — the server's minimum-version check would
         * otherwise answer 426 for good.
         */
        fun appVersion(context: Context): String = try {
            val info = context.packageManager.getPackageInfo(context.packageName, 0)
            val code = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                info.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                info.versionCode.toLong()
            }
            "${info.versionName ?: "0.0.0"}+$code"
        } catch (e: PackageManager.NameNotFoundException) {
            "0.0.0+0"
        }
    }
}
