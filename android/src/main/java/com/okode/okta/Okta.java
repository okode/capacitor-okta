package com.okode.okta;

import android.app.Activity;
import android.content.DialogInterface;
import android.graphics.Color;

import androidx.activity.result.ActivityResult;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;

import com.getcapacitor.PluginCall;
import com.okta.oidc.AuthenticationPayload;
import com.okta.oidc.AuthorizationStatus;
import com.okta.oidc.OIDCConfig;
import com.okta.oidc.RequestCallback;
import com.okta.oidc.ResultCallback;
import com.okta.oidc.clients.sessions.SessionClient;
import com.okta.oidc.clients.web.WebAuthClient;
import com.okta.oidc.util.AuthorizationException;
import com.okta.oidc.Tokens;

import com.getcapacitor.JSObject;

import org.json.JSONException;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Iterator;
import java.util.concurrent.Executors;

public class Okta {

  private final static String FIRE_FOX = "org.mozilla.firefox";
  private final static String CHROME_BROWSER = "com.android.chrome";
  private final static String BIOMETRIC_KEY = "okta_biometric";
  private WebAuthClient webAuthClient;
  private OktaListener oktaListener;
  private EncryptedSharedPreferenceStorage sharedPreferences;
  private Boolean resetBiometric = false;

  public SessionClient configureSDK(Activity activity, String clientId, String uri, String scopes, String endSessionUri, String redirectUri) throws GeneralSecurityException, IOException {
    sharedPreferences = new EncryptedSharedPreferenceStorage(activity);
    OIDCConfig config = new OIDCConfig.Builder()
       .clientId(clientId)
       .discoveryUri(uri)
       .scopes(scopes)
       .endSessionRedirectUri(endSessionUri)
       .redirectUri(redirectUri)
       .create();
    webAuthClient = new com.okta.oidc.Okta.WebAuthBuilder()
      .withConfig(config)
      .withContext(activity)
      .withCallbackExecutor(Executors.newSingleThreadExecutor())
      .withStorage(sharedPreferences)
      .supportedBrowsers(CHROME_BROWSER, FIRE_FOX)
      .setRequireHardwareBackedKeyStore(false) // required for emulators
      .withTabColor(Color.parseColor("#FFFFFF"))
      .create();
    setAuthCallback(activity);
    return webAuthClient.getSessionClient();
  }

  public void signIn(Activity activity, JSObject params, Boolean promptLogin, OktaRequestCallback<Void> callback) {
    if (webAuthClient == null) {
      callback.onError("No auth client initialized", null);
      return;
    }
     if (!promptLogin && !isBiometricEnabled() && !isAccessTokenExpired()) {
      notifyAuthStateChange();
      return;
    }
    signInWithBrowser(promptLogin, params, activity);
    callback.onSuccess(null);
  }

  public void signOut(Activity activity, OktaRequestCallback<Integer> callback) {
    if (webAuthClient == null) {
      callback.onError("No auth client initialized", null);
      return;
    }
    webAuthClient.signOut(activity, new RequestCallback<Integer, AuthorizationException>() {
      @Override
      public void onSuccess(@NonNull Integer result) {
        if (webAuthClient.getSessionClient() != null) {
          webAuthClient.getSessionClient().clear();
        }
        resetBiometric();
        callback.onSuccess(result);
      }

      @Override
      public void onError(String error, AuthorizationException exception) {
        callback.onError(error, exception);
      }
    });
  }

  public void enableBiometric() {
    sharedPreferences.save(BIOMETRIC_KEY, "true");
  }

  public void disableBiometric() {
    sharedPreferences.save(BIOMETRIC_KEY, "false");
  }

  public void resetBiometric() { sharedPreferences.delete(BIOMETRIC_KEY); }

  public SessionClient getAuthState() {
    return getSession();
  }

  public void setOktaListener(OktaListener listener) {
    this.oktaListener = listener;
  }
  public void setResetBiometric(Boolean resetBiometric) {
    this.resetBiometric = resetBiometric;
  }

  public void signInWithBiometric(PluginCall call, Activity activity, ActivityResult result) {
    if (webAuthClient == null) {
      call.reject("No auth client initialized");
      return;
    }
    JSObject params = call.getObject("params", new JSObject());
    webAuthClient.getSessionClient().refreshToken(new RequestCallback<Tokens, AuthorizationException>() {
      @Override
      public void onSuccess(@NonNull Tokens result) {
        notifyAuthStateChange();
        call.resolve();
      }

      @Override
      public void onError(String error, AuthorizationException exception) {
        notifyError("REFRESH_ERROR", error, null);
        signInWithBrowser(true, params, activity);
        call.resolve();
      }
    });
  }

  private void signInWithBrowser(Boolean promptLogin, JSObject params, Activity activity) {
    if (promptLogin) { params.put("prompt", "login"); }
    webAuthClient.signIn(activity, getPayload(params));
  }

  protected boolean isBiometricEnabled() {
    try {
      return sharedPreferences.get(BIOMETRIC_KEY).equals("true");
    } catch (Exception e){
      return false;
    }
  }

  protected boolean isBiometricConfigured() {
    return sharedPreferences.get(BIOMETRIC_KEY) != null;
  }

  protected void notifyError(String error, String message, String code) {
    oktaListener.onOktaError(error, message, code);
  }

  private void setAuthCallback(Activity activity) {
    webAuthClient.registerCallback(
      new ResultCallback<AuthorizationStatus, AuthorizationException>() {
        @Override
        public void onSuccess(@NonNull AuthorizationStatus status) {
          if (status != AuthorizationStatus.AUTHORIZED) {
            notifyError("NO_AUTHORIZED", "", "");
            return;
          }
          if (!isBiometricConfigured() && Biometric.isAvailable(activity)) {
            showBiometricDialog(activity);
          }
          if (resetBiometric) { resetBiometric(); }
          notifyAuthStateChange();
        }

        @Override
        public void onCancel() {
        }

        @Override
        public void onError(@Nullable String msg, @Nullable AuthorizationException error) {
          notifyError("AUHTORIZATION_ERROR", msg, String.valueOf(error.code));
        }
      }, activity);
  }

  private SessionClient getSession() {
    return webAuthClient != null ? webAuthClient.getSessionClient() : null;
  }

  private void notifyAuthStateChange() {
    oktaListener.onOktaAuthStateChange(getSession());
  }

  private void showBiometricDialog(Activity activity) {
    AlertDialog.Builder builder = new AlertDialog.Builder(activity);
    builder.setTitle("Acceso biométrico");
    builder.setMessage("¿Quieres utilizar el biométrico para futuros accesos?")
      .setPositiveButton("Aceptar", new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialog, int id) {
          enableBiometric();
          dialog.dismiss();
        }
      })
      .setNegativeButton("Cancelar", new DialogInterface.OnClickListener() {
        public void onClick(DialogInterface dialog, int id) {
          disableBiometric();
          dialog.dismiss();
        }
      });

    activity.runOnUiThread(new Runnable() {
      public void run() {
        builder.create().show();
      }
    });
  }

  private AuthenticationPayload getPayload(JSObject params) {
    AuthenticationPayload.Builder payload = new AuthenticationPayload.Builder();
    try {
      Iterator<String> keys = params.keys();
      while (keys.hasNext()) {
        String key = keys.next();
        payload.addParameter(key, params.get(key).toString());
      }
      return payload.build();
    } catch (JSONException e) {
      return payload.build();
    }
  }

  private Boolean isAccessTokenExpired() {
    try {
      return this.getAuthState().getTokens().isAccessTokenExpired();
    } catch (Exception e) {
      return true;
    }
  }

  public interface OktaRequestCallback<T> {
    void onSuccess(T data);
    void onError(String error, Exception e);
  }

}
