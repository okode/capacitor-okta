package com.okode.okta;

import com.okta.oidc.clients.sessions.SessionClient;

public interface OktaAuthStateChangeListener {
    void onOktaAuthStateChange(SessionClient session);
}
