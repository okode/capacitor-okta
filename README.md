# capacitor-okta

Okta plugin

## Install

```bash
npm install capacitor-okta
npx cap sync
```

## API

<docgen-index>

* [`signIn(...)`](#signin)
* [`signOut()`](#signout)
* [`register(...)`](#register)
* [`recoveryPassword(...)`](#recoverypassword)
* [`enableBiometric()`](#enablebiometric)
* [`disableBiometric()`](#disablebiometric)
* [`resetBiometric()`](#resetbiometric)
* [`getBiometricStatus()`](#getbiometricstatus)
* [`configure(...)`](#configure)
* [`addListener('authState', ...)`](#addlistenerauthstate)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### signIn(...)

```typescript
signIn(options?: { params?: Record<string, string> | undefined; signInInBrowser?: boolean | undefined; } | undefined) => Promise<void>
```

| Param         | Type                                                                                                 |
| ------------- | ---------------------------------------------------------------------------------------------------- |
| **`options`** | <code>{ params?: <a href="#record">Record</a>&lt;string, string&gt;; signInInBrowser?: boolean; }</code> |

--------------------


### signOut()

```typescript
signOut() => Promise<void>
```

--------------------


### register(...)

```typescript
register(params?: Record<string, string> | undefined) => Promise<void>
```

| Param        | Type                                                            |
| ------------ | --------------------------------------------------------------- |
| **`params`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code> |

--------------------


### recoveryPassword(...)

```typescript
recoveryPassword(params?: Record<string, string> | undefined) => Promise<void>
```

| Param        | Type                                                            |
| ------------ | --------------------------------------------------------------- |
| **`params`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code> |

--------------------


### enableBiometric()

```typescript
enableBiometric() => Promise<BiometricState>
```

**Returns:** <code>Promise&lt;<a href="#biometricstate">BiometricState</a>&gt;</code>

--------------------


### disableBiometric()

```typescript
disableBiometric() => Promise<BiometricState>
```

**Returns:** <code>Promise&lt;<a href="#biometricstate">BiometricState</a>&gt;</code>

--------------------


### resetBiometric()

```typescript
resetBiometric() => Promise<BiometricState>
```

**Returns:** <code>Promise&lt;<a href="#biometricstate">BiometricState</a>&gt;</code>

--------------------


### getBiometricStatus()

```typescript
getBiometricStatus() => Promise<BiometricState>
```

**Returns:** <code>Promise&lt;<a href="#biometricstate">BiometricState</a>&gt;</code>

--------------------


### configure(...)

```typescript
configure(config: OktaConfig) => Promise<void>
```

| Param        | Type                                              |
| ------------ | ------------------------------------------------- |
| **`config`** | <code><a href="#oktaconfig">OktaConfig</a></code> |

--------------------


### addListener('authState', ...)

```typescript
addListener(eventName: 'authState', listenerFunc: (data: AuthState) => void) => PluginListenerHandle
```

| Param              | Type                                                               |
| ------------------ | ------------------------------------------------------------------ |
| **`eventName`**    | <code>'authState'</code>                                           |
| **`listenerFunc`** | <code>(data: <a href="#authstate">AuthState</a>) =&gt; void</code> |

**Returns:** <code><a href="#pluginlistenerhandle">PluginListenerHandle</a></code>

--------------------


### Interfaces


#### BiometricState

| Prop                       | Type                 |
| -------------------------- | -------------------- |
| **`isBiometricSupported`** | <code>boolean</code> |
| **`isBiometricEnabled`**   | <code>boolean</code> |


#### OktaConfig

| Prop                | Type                |
| ------------------- | ------------------- |
| **`clientId`**      | <code>string</code> |
| **`uri`**           | <code>string</code> |
| **`scopes`**        | <code>string</code> |
| **`endSessionUri`** | <code>string</code> |
| **`redirectUri`**   | <code>string</code> |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### AuthState

| Prop              | Type                |
| ----------------- | ------------------- |
| **`accessToken`** | <code>string</code> |


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{
 [P in K]: T;
 }</code>

</docgen-api>

## CHANGELOG

- 1.1.0 Capacitor 5
- 1.0.0 ... 1.0.9 Capacitor 4