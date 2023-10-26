package com.okode.okta;
import android.annotation.SuppressLint;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKeys;

import com.okta.oidc.storage.OktaStorage;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.HashMap;
import java.util.Map;

/**
 * A sample on how to replace the default SharedPreferenceStorage with the encrypted version
 * from the androidx library. If the storage is already encrypting the data, make sure to disable
 * encryption by providing a empty encryption manager like {@link NoEncryption} and set this storage
 * in {@link com.okta.oidc.Okta.WebAuthBuilder#withStorage(OktaStorage)}
 */
public class SecureShareStorage implements OktaStorage {

    private static final String PROVIDER_URI_SUFFIX = ".providers.secureshare/secshare";
    private static final String PROTOCOL = "content://";
    private static final String FILENAME = "secshare";
    private Context context;
    private SharedPreferences prefs;

    public SecureShareStorage(Context context) throws GeneralSecurityException, IOException {
        this(context, null);
        this.context = context;
    }


    public SecureShareStorage(Context context, String prefName) throws GeneralSecurityException, IOException {
        String masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC);
        prefs = EncryptedSharedPreferences.create(
                FILENAME,
                masterKeyAlias,
                context,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        );
    }

    @SuppressLint("ApplySharedPref")
    @Override
    public void save(@NonNull String key, @NonNull String value) {
        SharedPreferences.Editor sharedPrefsEditor = prefs.edit();
        sharedPrefsEditor.clear();
        sharedPrefsEditor.putString(key, value);
        sharedPrefsEditor.apply();
    }

    @Nullable
    @Override
    public String get(@NonNull String key) {
        Map<String, String> result = new HashMap<>();
        Uri uri = Uri.parse(PROTOCOL + "com.mapfre.tarjetadesalud" + PROVIDER_URI_SUFFIX);
        Cursor cursor = this.context.getContentResolver().query(uri, null, null, null, null);
        if (cursor != null && cursor.moveToFirst()) {
            for(int i=0; i<cursor.getColumnCount(); i++) {
                result.put(cursor.getColumnName(i), cursor.getString(i));
            }
        }
        return result.get(key);
    }


    @SuppressLint("ApplySharedPref")
    @Override
    public void delete(@NonNull String key) {
        SharedPreferences.Editor sharedPrefsEditor = prefs.edit();
        sharedPrefsEditor.clear();
        sharedPrefsEditor.remove(key);
        sharedPrefsEditor.apply();
    }

    public Map<String, String> retrieve()  {
        Map<String, String> result = new HashMap<>();
        for (Map.Entry<String, ?> entry : prefs.getAll().entrySet()) {
            result.put(entry.getKey(), entry.getValue().toString());
        }
        return result;
    }

}
