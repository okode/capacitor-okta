package com.okode.okta;

import android.app.Activity;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;

import java.util.concurrent.Executor;

public class Biometric extends AppCompatActivity {

  private Executor executor;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.biometric_layout);
    if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.P){
      executor = this.getMainExecutor();
    }else{
      executor = new Executor() {
        @Override
        public void execute(Runnable command) {
          new Handler().post(command);
        }
      };
    }

    BiometricPrompt.PromptInfo.Builder builder = new BiometricPrompt.PromptInfo.Builder()
      .setTitle("Acceso biométrico")
      .setNegativeButtonText("Cancelar");
    BiometricPrompt.PromptInfo promptInfo = builder.build();
    BiometricPrompt biometricPrompt = new BiometricPrompt(this, executor, new BiometricPrompt.AuthenticationCallback() {
      @Override
      public void onAuthenticationError(int errorCode, @NonNull CharSequence errString) {
        super.onAuthenticationError(errorCode, errString);
        finishActivity(false, errorCode, errString.toString());
      }

      @Override
      public void onAuthenticationSucceeded(@NonNull BiometricPrompt.AuthenticationResult result) {
        super.onAuthenticationSucceeded(result);
        finishActivity(true, null, null);
      }
    });
    biometricPrompt.authenticate(promptInfo);
  }

  public void finishActivity(Boolean success, Integer errorCode, String errorDetails) {
      Intent intent = new Intent();
      setResult(RESULT_CANCELED, intent);
      if (success) {
        setResult(RESULT_OK, intent);
      }
      if (errorCode != null) {
        intent.putExtra("errorCode", String.valueOf(errorCode));
      }
      if (errorDetails != null) {
        intent.putExtra("errorMessage", errorDetails);
      }
      finish();
    }

  public static Boolean isAvailable(Activity activity) {
    BiometricManager biometricManager = BiometricManager.from(activity);
    return biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) == BiometricManager.BIOMETRIC_SUCCESS;
  }

}
