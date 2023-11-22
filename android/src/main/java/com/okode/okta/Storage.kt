package com.okode.okta

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import org.json.JSONObject
import java.io.IOException
import java.security.GeneralSecurityException


class Storage {

  /* Keys */
  private val BIOMETRIC_ENABLED_KEY = "okta_biometric_enabled"
  private val BIOMETRIC_ERROR_KEY = "okta_biometric_error"

  private val FILE_NAME = "okta_storage"
  private var prefs: SharedPreferences

  @Throws(GeneralSecurityException::class, IOException::class)
  constructor(context: Context) {
    val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
    prefs = EncryptedSharedPreferences.create(
                FILE_NAME,
                masterKeyAlias,
                context,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
  }

  /* Biometric */
  fun setBiometric(enabled: Boolean) { save(BIOMETRIC_ENABLED_KEY, enabled.toString()) }
  fun getBiometric(): Boolean? { return get(BIOMETRIC_ENABLED_KEY)?.toBoolean() }
  fun deleteBiometric() { delete(BIOMETRIC_ENABLED_KEY) }
  fun setBiometricError(error: String) { save(BIOMETRIC_ERROR_KEY, error.toString()) }
  fun getBiometricError(): String? { return get(BIOMETRIC_ERROR_KEY) }
  fun deleteBiometricError() { delete(BIOMETRIC_ERROR_KEY) }

  private fun save(key: String, value: String) {
    with(prefs.edit()) {
      putString(key, value)
      apply()
    }
  }

  private operator fun get(key: String): String? {
    return prefs.getString(key, null)
  }

  private fun delete(key: String) {
    with(prefs.edit()) {
      remove(key)
      apply()
    }
  }

}
