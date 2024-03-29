import type { PluginListenerHandle } from "@capacitor/core";
export interface OktaPlugin {
    signIn(options?: {
        signInInBrowser?: boolean;
        document?: string;
        params?: Record<string, string>;
    }): Promise<{
        token: string;
    }>;
    signOut(options?: {
        signOutOfBrowser?: boolean;
        resetBiometric?: boolean;
    }): Promise<void>;
    register(params?: Record<string, string>): Promise<{
        token: string;
    }>;
    recoveryPassword(params?: Record<string, string>): Promise<{
        token: string;
    }>;
    enableBiometric(): Promise<BiometricState>;
    disableBiometric(): Promise<BiometricState>;
    resetBiometric(): Promise<BiometricState>;
    getBiometricStatus(): Promise<BiometricState>;
    configure(options: {
        config: OktaConfig;
        cleanStorage?: boolean;
    }): Promise<void>;
    addListener(eventName: 'error', listenerFunc: (data: OktaError) => void): PluginListenerHandle;
}
export interface OktaError {
    error: string;
    message: string;
    code: string;
}
export interface BiometricState {
    isBiometricAvailable: boolean;
    isBiometricEnabled: boolean;
}
export interface OktaConfig {
    clientId: string;
    uri: string;
    scopes: string;
    endSessionUri: string;
    redirectUri: string;
}
