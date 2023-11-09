import { WebPlugin } from '@capacitor/core';
import type { BiometricState, OktaPlugin } from './definitions';
export declare class OktaWeb extends WebPlugin implements OktaPlugin {
    configure(): Promise<void>;
    signIn(): Promise<void>;
    signOut(): Promise<void>;
    register(): Promise<void>;
    recoveryPassword(): Promise<void>;
    enableBiometric(): Promise<BiometricState>;
    disableBiometric(): Promise<BiometricState>;
    resetBiometric(): Promise<BiometricState>;
    getBiometricStatus(): Promise<BiometricState>;
}
