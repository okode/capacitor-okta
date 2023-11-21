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
  private val BIOMETRIC_KEY = "okta_biometric"

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
  fun setBiometric(value: Boolean) { save(BIOMETRIC_KEY, value.toString()) }
  fun getBiometric(): Boolean? { return get(BIOMETRIC_KEY)?.toBoolean() }
  fun deleteBiometric() { delete(BIOMETRIC_KEY) }

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
