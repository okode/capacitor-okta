import { WebPlugin } from '@capacitor/core';
import type { BiometricState, OktaPlugin } from './definitions';
export declare class OktaWeb extends WebPlugin implements OktaPlugin {
    configure(): Promise<void>;
    signIn(): Promise<{
        token: string;
    }>;
    signOut(): Promise<void>;
    register(): Promise<{
        token: string;
    }>;
    recoveryPassword(): Promise<{
        token: string;
    }>;
    enableBiometric(): Promise<BiometricState>;
    disableBiometric(): Promise<BiometricState>;
    resetBiometric(): Promise<BiometricState>;
    getBiometricStatus(): Promise<BiometricState>;
}
