package com.okode.okta;

import static android.content.ContentValues.TAG;

import android.app.Activity;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.okta.oidc.AuthorizationStatus;
import com.okta.oidc.OIDCConfig;
import com.okta.oidc.RequestCallback;
import com.okta.oidc.ResultCallback;
import com.okta.oidc.clients.sessions.SessionClient;
import com.okta.oidc.clients.web.WebAuthClient;
import com.okta.oidc.net.response.UserInfo;
import com.okta.oidc.storage.SharedPreferenceStorage;
import com.okta.oidc.util.AuthorizationException;
import com.okta.oidc.Tokens;

import java.util.concurrent.Executors;

public class Okta {

    private final static String FIRE_FOX = "org.mozilla.firefox";
    private final static String CHROME_BROWSER = "com.android.chrome";
    private final static String CONFIG_FILE_NAME = "okta_oidc_config";

    private WebAuthClient webAuthClient;
    private OktaAuthStateChangeListener authStateChangeListener;

    public SessionClient configureSDK(Activity activity) {
        int configFile = activity.getResources().getIdentifier(
                CONFIG_FILE_NAME, "raw", activity.getPackageName());
        OIDCConfig config = new OIDCConfig.Builder()
                .withJsonFile(activity, configFile)
                .create();
        webAuthClient = new com.okta.oidc.Okta.WebAuthBuilder()
                .withConfig(config)
                .withContext(activity)
                .withStorage(new SharedPreferenceStorage(activity))
                .withCallbackExecutor(Executors.newSingleThreadExecutor())
                .supportedBrowsers(CHROME_BROWSER, FIRE_FOX)
                .setRequireHardwareBackedKeyStore(false) // required for emulators
                .create();
        setAuthCallback(activity);
        refreshSesion();
        return webAuthClient.getSessionClient();
    }

    public void signInWithBrowser(Activity activity, OktaRequestCallback<Void> callback) {
        if (webAuthClient == null) {
            callback.onError("No auth client initialized", null);
            return;
        }
        webAuthClient.signIn(activity, null);
        callback.onSuccess(null);
    }

    public void refreshToken(OktaRequestCallback<Tokens> callback) {
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
                  notifyAuthStateChange();
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

    private void refreshSesion() {
        if (webAuthClient == null) { return; }
        try {
            Tokens tokens = webAuthClient.getSessionClient().getTokens();
            if (tokens.isAccessTokenExpired() && tokens.getRefreshToken() != null) {
                refreshToken(new OktaRequestCallback<Tokens>() {
                    @Override
                    public void onSuccess(@NonNull Tokens result) {
                        notifyAuthStateChange();
                    }
                    @Override
                    public void onError(String error, Exception exception) {
                        notifyAuthStateChange();
                    }
                });
                return;
            }
            notifyAuthStateChange();
        } catch (Exception e) {
            notifyAuthStateChange();
        }
    }

    public interface OktaRequestCallback<T> {
        void onSuccess(T data);
        void onError(String error, Exception e);
    }

}
