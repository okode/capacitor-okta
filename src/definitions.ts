import type { PluginListenerHandle } from "@capacitor/core";

export interface OktaPlugin {
  signInWithBrowser(): Promise<AuthStateDetails>;
  signOut(): Promise<AuthStateDetails>;
  getUser(): Promise<{ [key: string]: any }>;
  getAuthStateDetails(): Promise<AuthStateDetails>;
  addListener(eventName: 'initSuccess', listenerFunc: (data: AuthStateDetails) => void): PluginListenerHandle;
  addListener(eventName: 'initError', listenerFunc: (error: { description?: string }) => void): PluginListenerHandle;
  addListener(eventName: 'authState', listenerFunc: (data: AuthStateDetails) => void): PluginListenerHandle;
}

export interface AuthStateDetails {
  isAuthorized: boolean;
  accessToken?: string;
  refreshToken?: string;
  idToken?: string;
}