package com.okode.okta;

import com.okta.oidc.clients.sessions.SessionClient;

public interface OktaListener {
    void onOktaAuthStateChange(SessionClient session);
    void onOktaError(String error, String message, String code);
}
