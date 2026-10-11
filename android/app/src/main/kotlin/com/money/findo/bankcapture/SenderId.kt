package com.money.findo.bankcapture

import java.util.Locale

/**
 * Sender ids vary in case, spacing and punctuation between phones and message
 * types (`BanqueMisr` / `Banque Misr`, `BanK-AlAhly`): compare the canonical
 * form — lower-case letters and digits only. The server, iOS and the Flutter
 * `Bank` entity apply the same rule.
 */
object SenderId {
    fun canonical(sender: String?): String =
        sender.orEmpty().lowercase(Locale.ROOT).filter { it.isLetterOrDigit() }
}
