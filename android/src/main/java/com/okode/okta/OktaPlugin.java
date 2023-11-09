package com.okode.okta;

import android.app.KeyguardManager;
import android.content.Context;
import android.content.Intent;

import androidx.activity.result.ActivityResult;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.okta.oidc.clients.sessions.SessionClient;

@CapacitorPlugin(name = "Okta")

public class OktaPlugin extends Plugin implements OktaAuthStateChangeListener {
    private Okta implementation = new Okta();
    private SessionClient session = null;

    @PluginMethod
    public void configure(PluginCall call) {
      implementation.setAuthStateChangeListener(this);
      try {
        String clientId = call.getData().getString("clientId");
        String uri = call.getData().getString("uri");
        String scopes = call.getData().getString("scopes");
        String endSessionUri = call.getData().getString("endSessionUri");
        String redirectUri = call.getData().getString("redirectUri");
        session = implementation.configureSDK(getActivity(), clientId, uri, scopes, endSessionUri, redirectUri);
        call.resolve();
      } catch (Exception e) {
        call.reject(e.toString(), e);
      }
    }

    @PluginMethod
    public void signIn(PluginCall call) {
      Boolean promptLogin = call.getBoolean("promptLogin", false);
      if (!promptLogin && implementation.isBiometricEnabled(getActivity()) && session.isAuthenticated()) {
        this.showKeyguard(call);
      }
      JSObject params = call.getObject("params", new JSObject());
      if (promptLogin) { params.put("prompt", "login"); }
      implementation.signIn(getActivity(), params, promptLogin, new Okta.OktaRequestCallback<Void>() {
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
    public void register(PluginCall call) {
      JSObject params = call.getData();
      params.put("prompt", "login");
      params.put("t", "register");
      implementation.signIn(getActivity(), params, true, new Okta.OktaRequestCallback<Void>() {
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
    public void recoveryPassword(PluginCall call) {
      JSObject params = call.getData();
      params.put("prompt", "login");
      params.put("t", "resetPassWidget");
      implementation.signIn(getActivity(), params, true, new Okta.OktaRequestCallback<Void>() {
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
    public void enableBiometric(PluginCall call) {
      implementation.enableBiometric();
      call.resolve(getBiometricStatus());
    }

    @PluginMethod
    public void disableBiometric(PluginCall call) {
      implementation.disableBiometric();
      call.resolve(getBiometricStatus());
    }

    @PluginMethod
    public void resetBiometric(PluginCall call) {
      implementation.resetBiometric();
      call.resolve(getBiometricStatus());
    }

    @PluginMethod
    public void getBiometricStatus(PluginCall call) {
      call.resolve(getBiometricStatus());
    }

    @Override
    public void onOktaAuthStateChange(SessionClient session) {
        notifyListeners("authState", OktaConverterHelper.convertAuthState(session), true);
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

    private JSObject getBiometricStatus() {
      JSObject res = new JSObject();
      res.put("isBiometricEnabled", implementation.isBiometricEnabled(getActivity()));
      res.put("isBiometricSupported", implementation.isBiometricSupported(getActivity()));
      return res;
    }
}
