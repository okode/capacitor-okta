'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var core = require('@capacitor/core');

const Okta = core.registerPlugin('Okta', {
    web: () => Promise.resolve().then(function () { return web; }).then(m => new m.OktaWeb()),
});

class OktaWeb extends core.WebPlugin {
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
        return Promise.reject('Method not implemented.');
    }
    enableBiometric() {
        return Promise.reject('Method not implemented.');
    }
    disableBiometric() {
        return Promise.reject('Method not implemented.');
    }
    resetBiometric() {
        return Promise.reject('Method not implemented.');
    }
    getBiometricStatus() {
        return Promise.reject('Method not implemented.');
    }
}

var web = /*#__PURE__*/Object.freeze({
    __proto__: null,
    OktaWeb: OktaWeb
});

exports.Okta = Okta;
//# sourceMappingURL=plugin.cjs.js.map
