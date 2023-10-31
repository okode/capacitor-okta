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
    throw new Error('Method not implemented.');
  }

}
