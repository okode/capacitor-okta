import { WebPlugin } from '@capacitor/core';

import type { AuthStateDetails, OktaPlugin } from './definitions';

export class OktaWeb extends WebPlugin implements OktaPlugin {

  signInWithBrowser(): Promise<void> {
    return Promise.reject('Method not implemented.');
  }

  signOut(): Promise<{ value: number }> {
    return Promise.reject('Method not implemented.');
  }

  getUser(): Promise<{ [key: string]: any; }> {
    return Promise.reject('Method not implemented.');
  }

  getAuthStateDetails(): Promise<AuthStateDetails> {
    return Promise.reject('Method not implemented.');
  }

}
