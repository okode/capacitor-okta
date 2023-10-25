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

        state.put("isAuthenticated", session.isAuthenticated());

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

    public static JSObject convertUser(UserInfo user) {
        JSObject userJson = new JSObject();
        if (user == null) { return userJson; }
        try {
            return JSObject.fromJSONObject(user.getRaw());
        } catch (JSONException e) {
            Log.e(TAG, "Error converting user info");
            return userJson;
        }
    }

}
