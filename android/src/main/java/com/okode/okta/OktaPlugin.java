package com.okode.okta;

import android.Manifest;
import android.app.Activity;
import android.app.KeyguardManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.activity.result.ActivityResult;

import androidx.biometric.BiometricManager;
import androidx.core.app.ActivityCompat;

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

import java.io.IOException;
import java.security.GeneralSecurityException;

@CapacitorPlugin(name = "Okta")

public class OktaPlugin extends Plugin implements OktaAuthStateChangeListener {
    private Okta implementation = new Okta();
    private SessionClient session = null;
    @Override
    public void load() {
        super.load();
        implementation.setAuthStateChangeListener(this);
        try {
            session = implementation.configureSDK(getActivity());
        } catch (GeneralSecurityException e) {
            throw new RuntimeException(e);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
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
        Boolean biometric = call.getBoolean("biometric", false);
        if (biometric && session.isAuthenticated() && implementation.isKeyguardSecure(getActivity())) {
          this.showKeyguard(call);
        }
        implementation.signIn(getActivity(), call.getObject("params", null), new Okta.OktaRequestCallback<Void>() {
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
        notifyListeners("authState", OktaConverterHelper.convertAuthState(session, checkBiometricSupport()), true);
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

    private Boolean checkBiometricSupport() {
        BiometricManager biometricManager = BiometricManager.from(getActivity());
        return biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) == BiometricManager.BIOMETRIC_SUCCESS;
    }

}
