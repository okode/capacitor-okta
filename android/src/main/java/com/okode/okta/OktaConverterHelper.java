package com.okode.okta;

import static android.content.ContentValues.TAG;

import android.util.Log;

import com.getcapacitor.JSObject;
import com.okta.oidc.Tokens;
import com.okta.oidc.clients.sessions.SessionClient;
import com.okta.oidc.net.response.UserInfo;
import com.okta.oidc.util.AuthorizationException;

import org.json.JSONException;

public class OktaConverterHelper {

    private OktaConverterHelper() {}

    public static JSObject convertAuthState(SessionClient session) {
        JSObject state = new JSObject();
        if (session == null) { return state; }
        try {
            Tokens tokens = session.getTokens();
            if (tokens == null) { return state; }
            state.put("accessToken", tokens.getAccessToken());
        } catch (AuthorizationException e) {
            Log.w(TAG, "Error converting session: ", e);
            return state;
        }
        return state;
    }

    public static JSObject convertError(String error, String message, String code) {
      JSObject e = new JSObject();
      e.put("error", error);
      e.put("message", message);
      e.put("code", code);
      return e;
    }

}
