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
  private val CONFIG_KEY = "okta_biometric"

  private val FILE_NAME = "com.okode.okta.storage"
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
    try {
      prefs.edit().putString(key, value).commit()
    } catch (e: Exception) { }
  }

  private operator fun get(key: String): String? {
    try {
      return prefs.getString(key, null)
    } catch (e: Exception) { }
    return null
  }

  private fun delete(key: String) {
    try {
      prefs.edit().remove(key).commit()
    } catch (e: Exception) { }
  }
}
