import { registerPlugin } from '@capacitor/core';
const Okta = registerPlugin('Okta', {
    web: () => import('./web').then(m => new m.OktaWeb()),
});
export * from './definitions';
export { Okta };
//# sourceMappingURL=index.js.map