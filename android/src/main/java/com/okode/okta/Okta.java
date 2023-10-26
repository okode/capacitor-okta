package com.okode.okta;

import static android.app.Activity.RESULT_OK;
import static android.content.ContentValues.TAG;

import static com.okta.oidc.util.AuthorizationException.EncryptionErrors.ILLEGAL_BLOCK_SIZE;

import android.app.Activity;
import android.app.KeyguardManager;
import android.content.Context;
import android.graphics.Color;
import android.util.Log;

import androidx.activity.result.ActivityResult;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.getcapacitor.PluginCall;
import com.okta.oidc.AuthenticationPayload;
import com.okta.oidc.AuthorizationStatus;
import com.okta.oidc.OIDCConfig;
import com.okta.oidc.RequestCallback;
import com.okta.oidc.ResultCallback;
import com.okta.oidc.clients.sessions.SessionClient;
import com.okta.oidc.clients.web.WebAuthClient;
import com.okta.oidc.net.response.UserInfo;
import com.okta.oidc.storage.security.GuardedEncryptionManager;
import com.okta.oidc.util.AuthorizationException;
import com.okta.oidc.Tokens;

import com.getcapacitor.JSObject;

import org.json.JSONException;

import java.util.Iterator;
import java.util.concurrent.Executors;

public class Okta {

  private final static String FIRE_FOX = "org.mozilla.firefox";
  private final static String CHROME_BROWSER = "com.android.chrome";
  private final static String CONFIG_FILE_NAME = "okta_oidc_config";
  protected static final int REQUEST_CODE_CREDENTIALS = 1000;

  private WebAuthClient webAuthClient;
  private OktaAuthStateChangeListener authStateChangeListener;
  private GuardedEncryptionManager keyguardEncryptionManager;

  public SessionClient configureSDK(Activity activity) {
    int configFile = activity.getResources().getIdentifier(
      CONFIG_FILE_NAME, "raw", activity.getPackageName());
    OIDCConfig config = new OIDCConfig.Builder()
      .withJsonFile(activity, configFile)
      .create();
    com.okta.oidc.Okta.WebAuthBuilder webBuilder = new com.okta.oidc.Okta.WebAuthBuilder();
    webBuilder
      .withConfig(config)
      .withContext(activity)
      .withCallbackExecutor(Executors.newSingleThreadExecutor())
      .supportedBrowsers(CHROME_BROWSER, FIRE_FOX)
      .setRequireHardwareBackedKeyStore(false) // required for emulators
      .withTabColor(Color.parseColor("#FFFFFF"));
    if (this.isKeyguardSecure(activity)) {
      keyguardEncryptionManager = new GuardedEncryptionManager(activity, Integer.MAX_VALUE);
      if (keyguardEncryptionManager.getCipher() == null) { keyguardEncryptionManager.recreateCipher(); }
      webBuilder.withEncryptionManager(keyguardEncryptionManager);
    } else {
      webBuilder.withEncryptionManager(new NoEncryption());
    }
    webAuthClient = webBuilder.create();
    setAuthCallback(activity);
    return webAuthClient.getSessionClient();
  }

  public void signIn(Activity activity, JSObject params, OktaRequestCallback<Void> callback) {
    if (webAuthClient == null) {
      callback.onError("No auth client initialized", null);
      return;
    }

    AuthenticationPayload.Builder payload = new AuthenticationPayload.Builder();
    try {
      Iterator<String> keys = params.keys();
      while (keys.hasNext()) {
        String key = keys.next();
        payload.addParameter(key, params.get(key).toString());
      }
    } catch (JSONException e) { callback.onError(e.getMessage(), e); }

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
      }

      @Override
      public void onError(String error, AuthorizationException exception) {
        callback.onError(error, exception);
      }
    });
  }

  public void getUser(OktaRequestCallback<UserInfo> callback) {
    if (getSession() == null) {
      callback.onError("No auth session initialized", null);
      return;
    }
    getSession().getUserProfile(new RequestCallback<UserInfo, AuthorizationException>() {
      @Override
      public void onSuccess(@NonNull UserInfo user) {
        callback.onSuccess(user);
      }

      @Override
      public void onError(String error, AuthorizationException exception) {
        callback.onError(error, exception);
      }
    });
  }

  public SessionClient getAuthState() {
    return getSession();
  }

  public void setAuthStateChangeListener(OktaAuthStateChangeListener listener) {
    this.authStateChangeListener = listener;
  }

  public void signInWithBiometric(PluginCall call, Activity activity, ActivityResult result, OktaRequestCallback<Void> callback) {
    if (result.getResultCode() != RESULT_OK) {
      webAuthClient.getSessionClient().clear();
      this.webAuthClient.handleActivityResult(Okta.REQUEST_CODE_CREDENTIALS, result.getResultCode(), null);
      signIn(activity, call.getData(), callback);
      return;
    }
    if (keyguardEncryptionManager.getCipher() == null) {
      keyguardEncryptionManager.recreateCipher();
    }
    this.refreshToken(new OktaRequestCallback<Tokens>() {
      @Override
      public void onSuccess(@NonNull Tokens result) {
        notifyAuthStateChange();
        call.resolve();
      }
      @Override
      public void onError(String error, Exception exception) {
        webAuthClient.getSessionClient().clear();
        signIn(activity, call.getData(), callback);
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
            Log.i(TAG, "Auth success");
            notifyAuthStateChange();
          } else if (status == AuthorizationStatus.SIGNED_OUT) {
            Log.i(TAG, "Sign out from Okta success");
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

  public interface OktaRequestCallback<T> {
    void onSuccess(T data);
    void onError(String error, Exception e);
  }

}
