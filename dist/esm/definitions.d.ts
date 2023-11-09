import type { PluginListenerHandle } from "@capacitor/core";
export interface OktaPlugin {
    signIn(options?: {
        params?: Record<string, string>;
        promptLogin?: boolean;
    }): Promise<void>;
    signOut(): Promise<void>;
    register(params?: Record<string, string>): Promise<void>;
    recoveryPassword(params?: Record<string, string>): Promise<void>;
    enableBiometric(): Promise<BiometricState>;
    disableBiometric(): Promise<BiometricState>;
    resetBiometric(): Promise<BiometricState>;
    getBiometricStatus(): Promise<BiometricState>;
    configure(config: OktaConfig): Promise<void>;
    addListener(eventName: 'authState', listenerFunc: (data: AuthState) => void): PluginListenerHandle;
}
export interface AuthState {
    accessToken?: string;
}
export interface BiometricState {
    isBiometricSupported: boolean;
    isBiometricEnabled: boolean;
}
export interface OktaConfig {
    clientId: string;
    uri: string;
    scopes: string;
    endSessionUri: string;
    redirectUri: string;
}
