import { WebPlugin } from '@capacitor/core';
export class OktaWeb extends WebPlugin {
    signIn() {
        return Promise.reject('Method not implemented.');
    }
    signOut() {
        return Promise.reject('Method not implemented.');
    }
    register() {
        return Promise.reject('Method not implemented.');
    }
    recoveryPassword() {
        throw new Error('Method not implemented.');
    }
}
//# sourceMappingURL=web.js.map