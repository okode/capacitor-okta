#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(OktaPlugin, "Okta",
           CAP_PLUGIN_METHOD(signInWithBrowser, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(signInWithRefreshToken, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(signOut, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getUser, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getAuthStateDetails, CAPPluginReturnPromise);
)
