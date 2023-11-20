package com.okode.okta;

import static android.content.ContentValues.TAG;

import android.util.Log;

import com.getcapacitor.JSObject;

import org.json.JSONException;

public class OktaConverterHelper {

    private OktaConverterHelper() {}

    public static JSObject convertError(String error, String message, String code) {
      JSObject e = new JSObject();
      e.put("error", error);
      e.put("message", message);
      e.put("code", code);
      return e;
    }

}
