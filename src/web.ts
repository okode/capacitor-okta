import { WebPlugin } from '@capacitor/core';

import type { OktaPlugin } from './definitions';

export class OktaWeb extends WebPlugin implements OktaPlugin {

  signIn(): Promise<void> {
    return Promise.reject('Method not implemented.');
  }

  signOut(): Promise<void> {
    return Promise.reject('Method not implemented.');
  }

  register(): Promise<void> {
    return Promise.reject('Method not implemented.');
  }

  recoveryPassword(): Promise<void> {
    return Promise.reject('Method not implemented.');
  }

  enableBiometric(): Promise<void> {
    return Promise.reject('Method not implemented.');
  }

  disableBiometric(): Promise<void> {
    return Promise.reject('Method not implemented.');
  }

  restartBiometric(): Promise<void> {
    return Promise.reject('Method not implemented.');
  }

  getBiometricStatus(): Promise<{ isBiometricSupported: boolean; isBiometricEnabled: boolean; }> {
    return Promise.reject('Method not implemented.');
  }

}
