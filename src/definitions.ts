import type { PluginListenerHandle } from "@capacitor/core";

export interface OktaPlugin {
  signIn(params: Record<string, string>): Promise<void>;
  signOut(): Promise<{ value: number }>;
  getUser(): Promise<{ [key: string]: any }>;
  addListener(eventName: 'initSuccess', listenerFunc: (data: AuthStateDetails) => void): PluginListenerHandle;
  // Only fired on ios
  addListener(eventName: 'initError', listenerFunc: (error: { description?: string }) => void): PluginListenerHandle;
  addListener(eventName: 'authState', listenerFunc: (data: AuthStateDetails) => void): PluginListenerHandle;
}

export interface AuthStateDetails {
  isAuthenticated: boolean;
  accessToken?: string;
  refreshToken?: string;
  idToken?: string;
}