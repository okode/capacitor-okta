package com.okode.okta

import android.app.Activity
import android.content.Intent
import androidx.activity.result.ActivityResult
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.ActivityCallback
import com.getcapacitor.annotation.CapacitorPlugin

@CapacitorPlugin(name = "Okta")
class OktaPlugin : Plugin() {
    private val implementation = Okta()
    @PluginMethod
    suspend fun configure(call: PluginCall) {
        try {
            val clientId = call.data.getString("clientId", "")
            val uri = call.data.getString("uri", "")
            val scopes = call.data.getString("scopes", "")
            val endSessionUri = call.data.getString("endSessionUri", "")
            val redirectUri = call.data.getString("redirectUri", "")
            implementation.configureSDK(activity, clientId!!, uri!!, scopes!!, endSessionUri!!, redirectUri)
            call.resolve()
        } catch (e: Exception) {
            call.reject(e.toString(), e)
        }
    }

    @PluginMethod
    suspend fun signIn(call: PluginCall) {
        val token = implementation.signIn(activity)
        val res = JSObject()
        res.put("token", token)
        call.resolve(res)
    }

}