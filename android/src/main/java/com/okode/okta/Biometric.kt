package com.okode.okta

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import androidx.appcompat.app.AppCompatActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.biometric.BiometricPrompt.PromptInfo
import java.util.concurrent.Executor

class Biometric : AppCompatActivity() {
    private var executor: Executor? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.biometric_layout)
        executor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            this.mainExecutor
        } else {
            Executor { command -> Handler().post(command) }
        }
        val builder = PromptInfo.Builder()
                .setTitle("Acceso biométrico")
                .setNegativeButtonText("Cancelar")
        val promptInfo = builder.build()
        val biometricPrompt = BiometricPrompt(this, executor!!, object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                finishActivity(false, errorCode, errString.toString())
            }

            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                finishActivity(true, null, null)
            }
        })
        biometricPrompt.authenticate(promptInfo)
    }

    fun finishActivity(success: Boolean, errorCode: Int?, errorDetails: String?) {
        val intent = Intent()
        setResult(Activity.RESULT_CANCELED, intent)
        if (success) {
            setResult(Activity.RESULT_OK, intent)
        }
        if (errorCode != null) {
            intent.putExtra("errorCode", errorCode.toString())
            if (!isBiometricSupported(errorCode)) {
                intent.putExtra("isBiometricSupported", false)
            }
        }
        if (errorDetails != null) {
            intent.putExtra("errorMessage", errorDetails)
        }
        finish()
    }

    companion object {
        @JvmStatic
        fun isAvailable(activity: Activity): Boolean {
            val biometricManager = BiometricManager.from(activity)
            return biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) == BiometricManager.BIOMETRIC_SUCCESS
        }

        private fun isBiometricSupported(error: Int): Boolean {
            return when (error) {
                BiometricPrompt.ERROR_NO_BIOMETRICS, BiometricPrompt.ERROR_HW_NOT_PRESENT, BiometricPrompt.ERROR_LOCKOUT_PERMANENT, BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL -> false
                else -> true
            }
        }
    }
}
