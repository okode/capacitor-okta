import { WebPlugin } from '@capacitor/core';
import type { AuthStateDetails, OktaPlugin } from './definitions';
export declare class OktaWeb extends WebPlugin implements OktaPlugin {
    signInWithBrowser(): Promise<AuthStateDetails>;
    signOut(): Promise<AuthStateDetails>;
    getUser(): Promise<{
        [key: string]: any;
    }>;
    getAuthStateDetails(): Promise<AuthStateDetails>;
}
