package com.okode.okta

import android.app.Activity
import java.io.IOException
import java.security.GeneralSecurityException

import com.okta.authfoundation.AuthFoundationDefaults
import com.okta.authfoundation.client.OidcClient
import com.okta.authfoundation.client.OidcClientResult
import com.okta.authfoundation.client.OidcConfiguration
import com.okta.authfoundation.client.SharedPreferencesCache
import com.okta.authfoundation.credential.Credential
import com.okta.authfoundation.credential.CredentialDataSource.Companion.createCredentialDataSource
import com.okta.authfoundationbootstrap.CredentialBootstrap
import com.okta.webauthenticationui.WebAuthenticationClient.Companion.createWebAuthenticationClient
import okhttp3.HttpUrl.Companion.toHttpUrl

class Okta {
    private var credential: Credential? = null

    @Throws(GeneralSecurityException::class, IOException::class)
    suspend fun configureSDK(activity: Activity, clientId: String, uri: String, scopes: String, endSessionUri: String, redirectUri: String?) {
        AuthFoundationDefaults.cache = SharedPreferencesCache.create(activity)
        val oidcConfiguration = OidcConfiguration(
                clientId = clientId,
                defaultScope = scopes
        )
        val client = OidcClient.createFromDiscoveryUrl(oidcConfiguration, uri.toHttpUrl())
        CredentialBootstrap.initialize(client.createCredentialDataSource(activity))
        credential= CredentialBootstrap.defaultCredential()
    }

    suspend fun signIn(activity: Activity): String {
        val webAuthenticationClient = CredentialBootstrap.oidcClient.createWebAuthenticationClient()
        when (val result = webAuthenticationClient.login(activity, "com.mapfre.tarjetadesalud:/callback")) {
            is OidcClientResult.Error -> {

            }
            is OidcClientResult.Success -> {
                credential?.storeToken(token = result.result)
                return result.result.accessToken
            }
        }
        return ""
    }

}