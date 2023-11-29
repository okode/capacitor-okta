package com.okode.okta

import com.getcapacitor.JSObject

class Helper {

  companion object {

    fun convertParams(params: JSObject): HashMap<String, String> {
      val keys = params.keys()
      val urlParams = HashMap<String, String>()
      while (keys.hasNext()) {
        val key = keys.next()
        val value = params.getString(key)
        if (value != null) urlParams.put(key, value)
      }
      return urlParams
    }

    fun convertTokenResponse(token: String?): JSObject {
      val res = JSObject()
      res.put("token", token)
      return res
    }

    fun convertBiometricStatus(isBiometricEnabled: Boolean, isBiometricAvailable: Boolean): JSObject {
      val res = JSObject()
      res.put("isBiometricEnabled", isBiometricEnabled)
      res.put("isBiometricAvailable", isBiometricAvailable)
      return res
    }

    fun convertError(error: String?, message: String?, code: String?): JSObject? {
      val e = JSObject()
      e.put("error", error)
      e.put("message", message)
      e.put("code", code)
      return e
    }
  }

}
