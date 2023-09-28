import { WebPlugin } from '@capacitor/core';
import type { AuthStateDetails, OktaPlugin } from './definitions';
export declare class OktaWeb extends WebPlugin implements OktaPlugin {
    signInWithBrowser(): Promise<void>;
    signInWithRefreshToken(): Promise<void>;
    signOut(): Promise<{
        value: number;
    }>;
    getUser(): Promise<{
        [key: string]: any;
    }>;
    getAuthStateDetails(): Promise<AuthStateDetails>;
}
