import type { PluginListenerHandle } from "@capacitor/core";

export interface OktaPlugin {
  signIn(params: Record<string, string>): Promise<void>;
  signOut(): Promise<void>;
  register(params: Record<string, string>): Promise<void>;
  recoveryPassword(params: Record<string, string>): Promise<void>;
  enableBiometric(): Promise<void>;
  disabledBiometric(): Promise<void>;
  restartBiometric(): Promise<void>;
  getBiometricStatus(): Promise<{ isBiometricSupported: boolean, isBiometricEnabled: boolean }>;
  addListener(eventName: 'authState', listenerFunc: (data: AuthState) => void): PluginListenerHandle;
}

export interface AuthState {
  accessToken?: string;
  isBiometricSupported: boolean;
  isBiometricEnabled: boolean;
}
