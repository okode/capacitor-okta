package com.okode.okta

import android.app.Activity
import android.content.DialogInterface
import android.hardware.biometrics.BiometricPrompt
import android.widget.Toast

import com.getcapacitor.JSObject

import com.okta.authfoundation.AuthFoundationDefaults
import com.okta.authfoundation.client.OidcClient
import com.okta.authfoundation.client.OidcClientResult
import com.okta.authfoundation.client.OidcConfiguration
import com.okta.authfoundation.client.SharedPreferencesCache
import com.okta.authfoundation.credential.Credential
import com.okta.authfoundation.credential.CredentialDataSource.Companion.createCredentialDataSource
import com.okta.authfoundationbootstrap.CredentialBootstrap
import com.okta.webauthenticationui.WebAuthenticationClient.Companion.createWebAuthenticationClient

import okhttp3.HttpUrl.Companion.toHttpUrl

import java.io.IOException
import java.security.GeneralSecurityException


class Okta {

  private var configured: Boolean = false
  private var credential: Credential? = null
  private var storage: Storage? = null
  private var endSessionUri: String = ""
  private var redirectUri: String = ""

  @Throws(GeneralSecurityException::class, IOException::class)
  suspend fun configureSDK(activity: Activity, clientId: String, uri: String,
                           scopes: String, endSessionUri: String, redirectUri: String,
                           cleanStorage: Boolean) {
    if (configured) { return }
    AuthFoundationDefaults.cache = SharedPreferencesCache.create(activity)
    val oidcConfiguration = OidcConfiguration(
      clientId = clientId,
      defaultScope = scopes
    )
    val url = uri + "/.well-known/openid-configuration";
    val client = OidcClient.createFromDiscoveryUrl(oidcConfiguration, url.toHttpUrl())
    CredentialBootstrap.initialize(client.createCredentialDataSource(activity))
    credential = CredentialBootstrap.defaultCredential()
    storage = Storage(activity)
    this.endSessionUri = endSessionUri
    this.redirectUri = redirectUri
    if (cleanStorage) {
      resetBiometric()
      credential?.storeToken(null)
    }
    configured = true
  }

  suspend fun signIn(activity: Activity, params: JSObject, signInInBrowser: Boolean): String? {
    var token: String? = null

    if (!signInInBrowser && credential?.getAccessTokenIfValid() != null) {
      return credential?.token?.accessToken
    }

    when (val result = CredentialBootstrap.oidcClient.createWebAuthenticationClient().login(activity, redirectUri, Helper.convertParams(params))) {
      is OidcClientResult.Error -> {
        throw Exception(result.exception)
      }
      is OidcClientResult.Success -> {
        if (!Biometric.isAvailable(activity) && isBiometricEnabled() && Biometric.errorCode != BiometricPrompt.BIOMETRIC_ERROR_LOCKOUT) {
          disableBiometric(false)
          showToast(activity, "El acceso biométrico se ha deshabilitado")
        }
        showBiometricDialog(activity);
        credential?.storeToken(result.result)
        token = result.result.accessToken
      }
    }
    return token
  }

  suspend fun signOut(activity: Activity, signOutOfBrowser: Boolean, resetBiometric: Boolean) {
    val idToken = credential?.token?.idToken ?: ""
    credential?.storeToken(null)
    if (resetBiometric) { resetBiometric() }
    if (!signOutOfBrowser) { return }

    when (val result = CredentialBootstrap.oidcClient.createWebAuthenticationClient().logoutOfBrowser(activity, endSessionUri, idToken)
    ) {
      is OidcClientResult.Error -> {
        throw Exception(result.exception)
      }
      is OidcClientResult.Success -> {
      }
    }
    return
  }

  fun enableBiometric() {
    storage?.setBiometric(true)
  }

  suspend fun disableBiometric(deleteTokens: Boolean) {
    if (deleteTokens) { credential?.storeToken(null) }
    storage?.setBiometric(false)
  }

  fun resetBiometric() {
    storage?.deleteBiometric()
  }

  suspend fun refreshToken(): String? {
    var token: String? = null
    when (val result = credential?.refreshToken()) {
      is OidcClientResult.Error -> {
        throw Exception(result.exception)
      }
      is OidcClientResult.Success -> {
        credential?.storeToken(result.result)
        token = result.result.accessToken
      }
      else -> {
        throw Exception()
      }
    }
    return token
  }

  fun isBiometricEnabled(): Boolean {
    return storage?.getBiometric() ?: false
  }

  fun hasRefreshToken(): Boolean {
    return credential?.token?.refreshToken != null
  }

  /* UI */

  private fun showBiometricDialog(activity: Activity) {
    if (storage?.getBiometric() != null || !Biometric.isAvailable(activity)) { return }
    val builder: android.app.AlertDialog.Builder = android.app.AlertDialog.Builder(activity)
    builder.setTitle("Acceso biométrico")
    builder.setMessage("¿Quieres utilizar el biométrico para futuros accesos?")
      .setPositiveButton("Aceptar", DialogInterface.OnClickListener { dialog, id ->
        storage?.setBiometric(true)
        dialog.dismiss()
      })
      .setNegativeButton("Cancelar", DialogInterface.OnClickListener { dialog, id ->
        storage?.setBiometric(false)
        dialog.dismiss()
      })
    activity.runOnUiThread { builder.create().show() }
  }

  private fun showToast(activity: Activity, text: String) {
    val duration = Toast.LENGTH_LONG
    activity.runOnUiThread { Toast.makeText(activity, text, duration).show() }
  }

}
