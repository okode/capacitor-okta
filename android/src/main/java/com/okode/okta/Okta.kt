package com.okode.okta

import android.app.Activity
import android.content.DialogInterface
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

  private var credential: Credential? = null
  private var storage: Storage? = null

  @Throws(GeneralSecurityException::class, IOException::class)
  suspend fun configureSDK(activity: Activity, clientId: String, uri: String, scopes: String, endSessionUri: String, redirectUri: String) {
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
    storage?.setOktaConfig(Helper.configToJSON(clientId, uri, scopes, endSessionUri, redirectUri))
  }

  suspend fun signIn(activity: Activity, params: JSObject, promptLogin: Boolean): String? {
    var token: String? = null
    val redirectUri = storage?.getOktaConfig()?.getString("redirectUri") ?: ""
    if (promptLogin) { params.put("promptLogin", "login") }
    when (val result = CredentialBootstrap.oidcClient.createWebAuthenticationClient().login(activity, redirectUri, Helper.convertParams(params))) {
      is OidcClientResult.Error -> {
        throw Exception(result.exception)
      }
      is OidcClientResult.Success -> {
        showBiometricDialog(activity);
        token = result.result.accessToken
      }
    }
    return token
  }

  suspend fun refreshToken(): String? {
    var token: String? = null
    when (val result = credential?.refreshToken()) {
      is OidcClientResult.Error -> {
        throw Exception(result.exception)
      }
      is OidcClientResult.Success -> {
        token = result.result.accessToken
      }
      else -> {
        throw Exception()
      }
    }
    return token
  }

  fun isBiometricEnabled(): Boolean {
    return storage?.getBiometric() != null && storage?.getBiometric()!!;
  }

  fun hasRefreshToken(): Boolean {
    return credential?.token?.refreshToken != null
  }

  fun enableBiometric() {
    storage?.setBiometric(true)
  }

  fun disableBiometric() {
    storage?.setBiometric(false)
  }

  fun resetBiometric() {
    storage?.deleteBiometric()
  }

  private fun showBiometricDialog(activity: Activity) {
    if (storage?.getBiometric() != null) { return }
    val builder: android.app.AlertDialog.Builder = android.app.AlertDialog.Builder(activity)
    builder.setTitle("Acceso biométrico")
    builder.setMessage("¿Quieres utilizar el biométrico para futuros accesos?")
      .setPositiveButton("Aceptar", DialogInterface.OnClickListener { dialog, id ->
        storage?.setBiometric(true)
        dialog.dismiss()
      })
      .setNegativeButton("Cancelar", DialogInterface.OnClickListener { dialog, id ->
        storage?.setBiometric(true)
        dialog.dismiss()
      })
    activity.runOnUiThread { builder.create().show() }
  }



}
