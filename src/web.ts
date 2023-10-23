import { WebPlugin } from '@capacitor/core';

import type { OktaPlugin } from './definitions';

export class OktaWeb extends WebPlugin implements OktaPlugin {

  signIn(): Promise<void> {
    return Promise.reject('Method not implemented.');
  }

  signOut(): Promise<{ value: number }> {
    return Promise.reject('Method not implemented.');
  }

  getUser(): Promise<{ [key: string]: any; }> {
    return Promise.reject('Method not implemented.');
  }

}
