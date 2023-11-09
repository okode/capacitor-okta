import { WebPlugin } from '@capacitor/core';

import type { BiometricState, OktaPlugin } from './definitions';

export class OktaWeb extends WebPlugin implements OktaPlugin {

  configure(): Promise<void> {
    throw new Error('Method not implemented.');
  }

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

  enableBiometric(): Promise<BiometricState> {
    return Promise.reject('Method not implemented.');
  }

  disableBiometric(): Promise<BiometricState> {
    return Promise.reject('Method not implemented.');
  }

  resetBiometric(): Promise<BiometricState> {
    return Promise.reject('Method not implemented.');
  }

  getBiometricStatus(): Promise<BiometricState> {
    return Promise.reject('Method not implemented.');
  }

}
