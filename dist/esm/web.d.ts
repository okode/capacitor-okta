import { WebPlugin } from '@capacitor/core';
import type { OktaPlugin } from './definitions';
export declare class OktaWeb extends WebPlugin implements OktaPlugin {
    signIn(): Promise<void>;
    signOut(): Promise<void>;
    register(): Promise<void>;
    recoveryPassword(): Promise<void>;
    enableBiometric(): Promise<void>;
    disableBiometric(): Promise<void>;
    restartBiometric(): Promise<void>;
    getBiometricStatus(): Promise<{
        isBiometricSupported: boolean;
        isBiometricEnabled: boolean;
    }>;
}
