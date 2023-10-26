package com.okode.okta;

import android.app.Activity;
import android.app.KeyguardManager;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.activity.result.ActivityResult;

import com.getcapacitor.JSObject;
import com.getcapacitor.NativePlugin;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.okta.oidc.clients.sessions.SessionClient;
import com.okta.oidc.net.response.UserInfo;
import com.okta.oidc.Tokens;

@CapacitorPlugin(name = "Okta")

public class OktaPlugin extends Plugin implements OktaAuthStateChangeListener {
    private Okta implementation = new Okta();
    private SessionClient session = null;
    @Override
    public void load() {
        super.load();
        implementation.setAuthStateChangeListener(this);
        session = implementation.configureSDK(getActivity());
        notifyListeners("initSuccess", OktaConverterHelper.convertAuthState(session), true);
    }

    @ActivityCallback
    protected void biometricResult(PluginCall call, ActivityResult result) {
      if (call == null) { return; }
      implementation.signInWithBiometric(call, getActivity(), result, new Okta.OktaRequestCallback<Void>() {
        @Override
        public void onSuccess(Void data) {
          call.resolve();
        }

        @Override
        public void onError(String error, Exception e) {
          call.reject(error, e);
        }
      });
    }

    @PluginMethod
    public void signIn(PluginCall call) {
        if (session.isAuthenticated() && implementation.isKeyguardSecure(getActivity())) {
          this.showKeyguard(call);
        }
        implementation.signIn(getActivity(), call.getData(), new Okta.OktaRequestCallback<Void>() {
            @Override
            public void onSuccess(Void data) {
                call.resolve();
            }

            @Override
            public void onError(String error, Exception e) {
                call.reject(error, e);
            }
        });
    }

    @PluginMethod
    public void signOut(PluginCall call) {
        implementation.signOut(getActivity(), new Okta.OktaRequestCallback<Integer>() {
            @Override
            public void onSuccess(Integer data) {
                JSObject res = new JSObject();
                res.put("value", data);
                call.resolve(res);
            }

            @Override
            public void onError(String error, Exception e) {
                call.reject(error, e);
            }
        });
    }

    @PluginMethod
    public void getUser(PluginCall call) {
        implementation.getUser(new Okta.OktaRequestCallback<UserInfo>() {
            @Override
            public void onSuccess(UserInfo user) {
                call.resolve(OktaConverterHelper.convertUser(user));
            }

            @Override
            public void onError(String error, Exception e) {
                call.reject(error, e);
            }
        });
    }

    @Override
    public void onOktaAuthStateChange(SessionClient session) {
        notifyListeners("authState", OktaConverterHelper.convertAuthState(session), true);
    }

    private void showKeyguard(PluginCall call) {
      if (!this.session.isAuthenticated()) { return; }
      KeyguardManager keyguardManager =
        (KeyguardManager) getActivity().getSystemService(Context.KEYGUARD_SERVICE);
      Intent intent = null;
      if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
        intent = keyguardManager.createConfirmDeviceCredentialIntent("Confirm credentials", "");
      }
      if (intent != null) {
        startActivityForResult(call, intent, "biometricResult");
      }
    }

}
