package com.example.money_time.bankcapture

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Encrypts the ingest token with an AES-256/GCM key that never leaves the
 * Android Keystore, so the token at rest in shared preferences is useless
 * without this device's hardware-backed key.
 */
internal object TokenCipher {
    private const val KEYSTORE = "AndroidKeyStore"
    private const val KEY_ALIAS = "money_time_bank_ingest_token"
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private const val TAG_BITS = 128

    fun encrypt(plain: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val sealed = cipher.doFinal(plain.toByteArray(Charsets.UTF_8))
        return encode(cipher.iv) + ":" + encode(sealed)
    }

    /** `null` when the value is unreadable (key reset by a restore, tampering). */
    fun decrypt(stored: String): String? = try {
        val (iv, sealed) = stored.split(":", limit = 2)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(TAG_BITS, decode(iv)))
        String(cipher.doFinal(decode(sealed)), Charsets.UTF_8)
    } catch (e: Exception) {
        null
    }

    private fun key(): SecretKey {
        val keyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        (keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry)?.let {
            return it.secretKey
        }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    private fun encode(bytes: ByteArray) = Base64.encodeToString(bytes, Base64.NO_WRAP)

    private fun decode(text: String) = Base64.decode(text, Base64.NO_WRAP)
}
