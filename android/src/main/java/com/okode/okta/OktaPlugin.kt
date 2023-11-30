package com.okode.okta

import android.R
import android.app.Activity.RESULT_OK
import android.content.Intent
import androidx.activity.result.ActivityResult
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.ActivityCallback
import com.getcapacitor.annotation.CapacitorPlugin
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch


@CapacitorPlugin(name = "Okta")
class OktaPlugin : Plugin() {

  private val implementation = Okta()

  @PluginMethod
  fun configure(call: PluginCall) {
    GlobalScope.launch {
      try {
        val clientId = call.data.getString("clientId") ?: ""
        val uri = call.data.getString("uri", "") ?: ""
        val scopes = call.data.getString("scopes", "") ?: ""
        val endSessionUri = call.data.getString("endSessionUri", "") ?: ""
        val redirectUri = call.data.getString("redirectUri", "") ?: ""
        implementation.configureSDK(activity, clientId, uri, scopes, endSessionUri, redirectUri)
        call.resolve()
      } catch (e: Exception) { call.reject(e.toString(), e) }
    }
  }

  @PluginMethod
  fun signIn(call: PluginCall) {
    var signInInBrowser = call.getBoolean("signInInBrowser") ?: false
    if (!signInInBrowser && implementation.hasRefreshToken() && implementation.isBiometricEnabled()) {
      verifyIdentity(call)
      return
    }
    signInWithBrowser(call, call.getObject("params") ?: JSObject(), signInInBrowser)
  }

  @PluginMethod
  fun signOut(call: PluginCall) {
    var signOutOfBrowser = call.getBoolean("signOutOfBrowser") ?: false
    var resetBiometric = call.getBoolean("resetBiometric") ?: false
    GlobalScope.launch {
      try {
        implementation.signOut(activity, signOutOfBrowser, resetBiometric)
        call.resolve()
      } catch (e: Exception) { call.reject(e.toString(), e) }
    }
  }


  @PluginMethod
  fun register(call: PluginCall) {
    var params = call.getObject("params") ?: JSObject()
    params.put("t", "register");
    signInWithBrowser(call, params, true)
  }

  @PluginMethod
  fun recoveryPassword(call: PluginCall) {
    var params = call.getObject("params") ?: JSObject()
    params.put("t", "resetPassWidget");
    signInWithBrowser(call, params, true)
  }

  @PluginMethod
  fun enableBiometric(call: PluginCall) {
    implementation.enableBiometric()
    getBiometricStatus(call)
  }

  @PluginMethod
  fun disableBiometric(call: PluginCall) {
    GlobalScope.launch {
      implementation.disableBiometric(true)
      getBiometricStatus(call)
    }
  }

  @PluginMethod
  fun resetBiometric(call: PluginCall) {
    implementation.resetBiometric()
    getBiometricStatus(call)
  }

  @PluginMethod
  fun getBiometricStatus(call: PluginCall) {
    call.resolve(Helper.convertBiometricStatus(implementation.isBiometricEnabled(), Biometric.isAvailable(activity)))
  }

  @ActivityCallback
  private fun biometricResult(call: PluginCall, result: ActivityResult) {
    GlobalScope.launch {
      var forceLogin = false
      if (result.resultCode !== RESULT_OK) {
        val data = result.data
        notifyError(
          "BIOMETRIC_ERROR",
          data?.getStringExtra("errorMessage") ?: "",
          data?.getStringExtra("errorCode") ?: ""
        )
        signInWithBrowser(call, call.getObject("params") ?: JSObject(), true)
        return@launch
      }
      signInWithRefresh(call)
    }
  }

  private fun signInWithBrowser(call: PluginCall, params: JSObject, signInInBrowser: Boolean) {
    GlobalScope.launch {
      try {
        if (signInInBrowser) { params.put("prompt", "login") }
        val document = call.data.getString("document")
        if (document != null) { params.put("login_hint", document) }
          val token = implementation.signIn(activity, params, signInInBrowser)
        call.resolve(Helper.convertTokenResponse(token))
      } catch (e: Exception) { call.reject(e.toString(), e) }
    }
  }

  private fun signInWithRefresh(call: PluginCall) {
    GlobalScope.launch {
      try {
        val token = implementation.refreshToken()
        call.resolve(Helper.convertTokenResponse(token))
      } catch (e: Exception) {
        notifyError("REFRESH_ERROR", e.localizedMessage, "")
        signInWithBrowser(call, call.getObject("params") ?: JSObject(), false)
      }
    }
  }

  private fun verifyIdentity(call: PluginCall) {
    val intent = Intent(context, Biometric::class.java)
    startActivityForResult(call, intent, "biometricResult")
  }

  private fun notifyError(error: String, message: String, code: String) {
    notifyListeners("error", Helper.convertError(error, message, code), true)
  }

}
