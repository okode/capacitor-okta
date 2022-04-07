import { registerPlugin } from '@capacitor/core';

import type { OktaPlugin } from './definitions';

const Okta = registerPlugin<OktaPlugin>('Okta', {
  web: () => import('./web').then(m => new m.OktaWeb()),
});

export * from './definitions';
export { Okta };
