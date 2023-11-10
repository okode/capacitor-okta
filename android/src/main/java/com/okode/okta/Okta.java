package com.okode.okta;

import static android.app.Activity.RESULT_OK;
import static android.content.ContentValues.TAG;

import android.app.Activity;
import android.app.KeyguardManager;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.Color;
import android.util.Log;

import androidx.activity.result.ActivityResult;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.biometric.BiometricManager;

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
  protected static final int REQUEST_CODE_CREDENTIALS = 1000;

  private WebAuthClient webAuthClient;
  private OktaAuthStateChangeListener authStateChangeListener;
  private EncryptedSharedPreferenceStorage sharedPreferences;
  private Boolean forceLogin = false;

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
    checkForForceLogin(activity);
    if (forceLogin) { promptLogin = true; }
    if (!promptLogin && !isBiometricEnabled() && !isAccessTokenExpired()) {
      notifyAuthStateChange();
      return;
    }
    if (promptLogin) { params.put("prompt", "login"); }
    webAuthClient.signIn(activity, getPayload(params));
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
        callback.onSuccess(result);
        if (webAuthClient.getSessionClient() != null) {
          webAuthClient.getSessionClient().clear();
        }
        resetBiometric();
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

  public void resetBiometric() {
    sharedPreferences.delete(BIOMETRIC_KEY);
  }

  public SessionClient getAuthState() {
    return getSession();
  }

  public void setAuthStateChangeListener(OktaAuthStateChangeListener listener) {
    this.authStateChangeListener = listener;
  }

  public void signInWithBiometric(PluginCall call, Activity activity, ActivityResult result, OktaRequestCallback<Void> callback) {
    if (result.getResultCode() != RESULT_OK) {
      JSObject params = call.getObject("params", new JSObject());
      callback.onError("BIOMETRIC_ERROR_CODE_" + result.getResultCode(), null);
      signIn(activity, params, true, callback);
      return;
    }
    this.refreshToken(new OktaRequestCallback<Tokens>() {
      @Override
      public void onSuccess(@NonNull Tokens result) {
        notifyAuthStateChange();
        call.resolve();
      }
      @Override
      public void onError(String error, Exception exception) {
        signIn(activity, call.getData(), true, callback);
        call.reject(error, exception);
      }
    });
  }

  private void refreshToken(OktaRequestCallback<Tokens> callback) {
    if (webAuthClient == null) {
      callback.onError("No auth client initialized", null);
      return;
    }
    webAuthClient.getSessionClient().refreshToken(new RequestCallback<Tokens, AuthorizationException>() {
      @Override
      public void onSuccess(@NonNull Tokens result) {
        callback.onSuccess(result);
      }

      @Override
      public void onError(String error, AuthorizationException exception) {
        callback.onError(error, exception);
      }
    });
  }

  private void setAuthCallback(Activity activity) {
    webAuthClient.registerCallback(
      new ResultCallback<AuthorizationStatus, AuthorizationException>() {
        @Override
        public void onSuccess(@NonNull AuthorizationStatus status) {
          if (status == AuthorizationStatus.AUTHORIZED) {
            if (forceLogin) { forceLogin = false; }
            if (!isBiometricConfigured() && isBiometricSupported(activity)) {
              activity.runOnUiThread(new Runnable() {
                public void run() {
                  showBiometricDialog(activity);
                }
              });
            }
            notifyAuthStateChange();
          } else if (status == AuthorizationStatus.SIGNED_OUT) {
            notifyAuthStateChange();
          }
        }

        @Override
        public void onCancel() {
          Log.i(TAG, "Auth cancelled");
        }

        @Override
        public void onError(@Nullable String msg, @Nullable AuthorizationException error) {
          Log.e(TAG, String.format("Error: %s : %s", error.error, error.errorDescription));
        }
      }, activity);
  }

  private SessionClient getSession() {
    return webAuthClient != null ? webAuthClient.getSessionClient() : null;
  }

  private void notifyAuthStateChange() {
    authStateChangeListener.onOktaAuthStateChange(getSession());
  }

  protected boolean isKeyguardSecure(Activity activity) {
    KeyguardManager keyguardManager =
      (KeyguardManager) activity.getSystemService(Context.KEYGUARD_SERVICE);
    return keyguardManager.isKeyguardSecure();
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

  protected Boolean isBiometricSupported(Activity activity) {
    return isBiometricAvailable(activity) && isKeyguardSecure(activity);
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
    builder.create().show();
  }

  private Boolean isBiometricAvailable(Activity activity) {
    BiometricManager biometricManager = BiometricManager.from(activity);
    return biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) == BiometricManager.BIOMETRIC_SUCCESS;
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
    } catch (AuthorizationException e) {
      return true;
    }
  }

  private void checkForForceLogin(Activity activity) {
    if (isBiometricEnabled() && !isBiometricSupported(activity)) {
      forceLogin = true;
    } else {
      forceLogin = false;
    }
  }

  public interface OktaRequestCallback<T> {
    void onSuccess(T data);
    void onError(String error, Exception e);
  }

}
