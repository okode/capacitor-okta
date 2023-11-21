package com.okode.okta

import android.app.Activity.RESULT_OK

import android.content.Intent
import android.util.Log
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
    GlobalScope.launch {
      try {
        var promptLogin = call.getBoolean("promptLogin") ?: false
        if (!promptLogin && implementation.hasRefreshToken() && implementation.isBiometricEnabled()) {
          verifyIdentity(call)
          return@launch
        }
        var params = call.getObject("params") ?: JSObject()
        val token = implementation.signIn(activity, params, promptLogin)
        call.resolve(Helper.convertTokenResponse(token))
      } catch (e: Exception) { call.reject(e.toString(), e) }
    }
  }

  @PluginMethod
  fun register(call: PluginCall) {
    GlobalScope.launch {
      try {
        var params = call.getObject("params") ?: JSObject()
        params.put("t", "register");
        val token = implementation.signIn(activity, params, true)
        call.resolve(Helper.convertTokenResponse(token))
      } catch (e: Exception) { call.reject(e.toString(), e) }
    }
  }

  @PluginMethod
  fun recoveryPassword(call: PluginCall) {
    GlobalScope.launch {
      try {
        var params = call.getObject("params") ?: JSObject()
        params.put("t", "resetPassWidget");
        val token = implementation.signIn(activity, params, true)
        call.resolve(Helper.convertTokenResponse(token))
      } catch (e: Exception) { call.reject(e.toString(), e) }
    }
  }

  @PluginMethod
  fun enableBiometric(call: PluginCall) {
    implementation.enableBiometric()
    getBiometricStatus(call)
  }

  @PluginMethod
  fun disableBiometric(call: PluginCall) {
    implementation.disableBiometric()
    getBiometricStatus(call)
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
  private fun biometricResult(call: PluginCall?, result: ActivityResult) {
    GlobalScope.launch {
      if (call == null) { return@launch }
      if (result.getResultCode() === RESULT_OK) {
        try {
          val token = implementation.refreshToken()
          call.resolve(Helper.convertTokenResponse(token))
        } catch (e: Exception) {
          call.data.put("promptLogin", true);
          signIn(call)
        }
        return@launch
      }
      call.data.put("promptLogin", true);
      signIn(call)
    }
  }

  private fun verifyIdentity(call: PluginCall) {
    val intent = Intent(context, Biometric::class.java)
    startActivityForResult(call, intent, "biometricResult")
  }

}
