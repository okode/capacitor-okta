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
  private final static String CONFIG_FILE_NAME = "okta_oidc_config";
  private final static String BIOMETRIC_KEY = "okta_biometric";
  protected static final int REQUEST_CODE_CREDENTIALS = 1000;

  private WebAuthClient webAuthClient;
  private OktaAuthStateChangeListener authStateChangeListener;
  private EncryptedSharedPreferenceStorage sharedPreferences;

  public SessionClient configureSDK(Activity activity) throws GeneralSecurityException, IOException {
    sharedPreferences = new EncryptedSharedPreferenceStorage(activity);
    int configFile = activity.getResources().getIdentifier(
      CONFIG_FILE_NAME, "raw", activity.getPackageName());
    OIDCConfig config = new OIDCConfig.Builder()
      .withJsonFile(activity, configFile)
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
    checkBiometric(activity);
    return webAuthClient.getSessionClient();
  }

  public void signIn(Activity activity, JSObject params, Boolean promptLogin, OktaRequestCallback<Void> callback) {
    if (webAuthClient == null) {
      callback.onError("No auth client initialized", null);
      return;
    }

    try {
      if (!promptLogin && !isBiometricEnabled(activity) && !this.getAuthState().getTokens().isAccessTokenExpired()) {
        notifyAuthStateChange();
        return;
      }
    } catch (Exception e) { }

    AuthenticationPayload.Builder payload = new AuthenticationPayload.Builder();
    try {
      Iterator<String> keys = params.keys();
      while (keys.hasNext()) {
        String key = keys.next();
        payload.addParameter(key, params.get(key).toString());
      }
    } catch (JSONException e) { }

    webAuthClient.signIn(activity, payload.build());
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
      this.webAuthClient.handleActivityResult(Okta.REQUEST_CODE_CREDENTIALS, result.getResultCode(), null);
      JSObject params = call.getObject("params", new JSObject());
      params.put("prompt", "login");
      signIn(activity, params, false, callback);
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
        signIn(activity, call.getData(), false, callback);
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

  protected boolean isBiometricEnabled(Activity activity) {
    try {
      return sharedPreferences.get(BIOMETRIC_KEY).equals("true")
        && isBiometricSupported(activity)
        && isKeyguardSecure(activity);
    } catch (Exception e){
      return false;
    }
  }

  protected boolean isBiometricConfigured() {
    return sharedPreferences.get(BIOMETRIC_KEY) != null;
  }

  protected Boolean isBiometricSupported(Activity activity) {
    BiometricManager biometricManager = BiometricManager.from(activity);
    return biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) == BiometricManager.BIOMETRIC_SUCCESS;
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

  private void checkBiometric(Activity activity) {
    try {
      Boolean biometricEnabled = sharedPreferences.get(BIOMETRIC_KEY).equals("true");
      if (!isBiometricSupported(activity) && biometricEnabled) {
        resetBiometric();
      }
    } catch (Exception e) { }
  }

  public interface OktaRequestCallback<T> {
    void onSuccess(T data);
    void onError(String error, Exception e);
  }

}
