'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var core = require('@capacitor/core');

const Okta = core.registerPlugin('Okta', {
    web: () => Promise.resolve().then(function () { return web; }).then(m => new m.OktaWeb()),
});

class OktaWeb extends core.WebPlugin {
    signInWithBrowser() {
        return Promise.reject('Method not implemented.');
    }
    refreshToken() {
        return Promise.reject('Method not implemented.');
    }
    signOut() {
        return Promise.reject('Method not implemented.');
    }
    getUser() {
        return Promise.reject('Method not implemented.');
    }
    getAuthStateDetails() {
        return Promise.reject('Method not implemented.');
    }
}

var web = /*#__PURE__*/Object.freeze({
    __proto__: null,
    OktaWeb: OktaWeb
});

exports.Okta = Okta;
//# sourceMappingURL=plugin.cjs.js.map
