package com.okode.okta;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.okta.oidc.clients.sessions.SessionClient;
import com.okta.oidc.net.response.UserInfo;

@CapacitorPlugin(name = "Okta")
public class OktaPlugin extends Plugin implements OktaAuthStateChangeListener {

    private Okta implementation = new Okta();

    @Override
    public void load() {
        super.load();
        implementation.setAuthStateChangeListener(this);
        SessionClient session = implementation.configureSDK(getActivity());
        notifyListeners("initSuccess", OktaConverterHelper.convertAuthState(session), true);
    }

    @PluginMethod
    public void signInWithBrowser(PluginCall call) {
        implementation.signInWithBrowser(getActivity(), new Okta.OktaRequestCallback<Void>() {
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

    @PluginMethod
    public void getAuthStateDetails(PluginCall call) {
        SessionClient session = implementation.getAuthState();
        call.resolve(OktaConverterHelper.convertAuthState(session));
    }

    @Override
    public void onOktaAuthStateChange(SessionClient session) {
        notifyListeners("authState", OktaConverterHelper.convertAuthState(session), true);
    }

}
