package com.okode.okta

import com.getcapacitor.JSObject
import org.json.JSONObject

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

    fun configToJSON(clientId: String, uri: String, scopes: String,
                     endSessionUri: String, redirectUri: String): JSONObject {
      val json = JSONObject()
      json.put("clientId", clientId)
      json.put("uri", uri)
      json.put("scopes", scopes)
      json.put("endSessionUri", endSessionUri)
      json.put("redirectUri", redirectUri)
      return json
    }

    fun convertTokenResponse(token: String?): JSObject {
      val res = JSObject()
      res.put("token", token)
      return res
    }

  }

}
