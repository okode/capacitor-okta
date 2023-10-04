import type { PluginListenerHandle } from "@capacitor/core";
export interface OktaPlugin {
    signInWithBrowser(): Promise<void>;
    refreshToken(): Promise<AuthStateDetails>;
    signOut(): Promise<{
        value: number;
    }>;
    getUser(): Promise<{
        [key: string]: any;
    }>;
    getAuthStateDetails(): Promise<AuthStateDetails>;
    addListener(eventName: 'initSuccess', listenerFunc: (data: AuthStateDetails) => void): PluginListenerHandle;
    addListener(eventName: 'initError', listenerFunc: (error: {
        description?: string;
    }) => void): PluginListenerHandle;
    addListener(eventName: 'authState', listenerFunc: (data: AuthStateDetails) => void): PluginListenerHandle;
}
export interface AuthStateDetails {
    isAuthenticated: boolean;
    accessToken?: string;
    refreshToken?: string;
    idToken?: string;
}
