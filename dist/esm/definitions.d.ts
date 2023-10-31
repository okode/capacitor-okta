import type { PluginListenerHandle } from "@capacitor/core";
export interface OktaPlugin {
    signIn(options: {
        params?: Record<string, string>;
        biometric?: boolean;
    }): Promise<void>;
    signOut(): Promise<void>;
    register(params: Record<string, string>): Promise<void>;
    recoveryPassword(params: Record<string, string>): Promise<void>;
    addListener(eventName: 'authState', listenerFunc: (data: AuthState) => void): PluginListenerHandle;
}
export interface AuthState {
    accessToken?: string;
    isBiometricSupported: boolean;
    isBiometricEnabled: boolean;
}
