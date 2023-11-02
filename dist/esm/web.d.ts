import { WebPlugin } from '@capacitor/core';
import type { BiometricState, OktaPlugin } from './definitions';
export declare class OktaWeb extends WebPlugin implements OktaPlugin {
    signIn(): Promise<void>;
    signOut(): Promise<void>;
    register(): Promise<void>;
    recoveryPassword(): Promise<void>;
    enableBiometric(): Promise<BiometricState>;
    disableBiometric(): Promise<BiometricState>;
    restartBiometric(): Promise<BiometricState>;
    getBiometricStatus(): Promise<BiometricState>;
}
