#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(OktaPlugin, "Okta",
           CAP_PLUGIN_METHOD(signIn, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(signOut, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(register, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(recoveryPassword, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(enableBiometric, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(disableBiometric, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(resetBiometric, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(getBiometricStatus, CAPPluginReturnPromise);
)
