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
* [`addListener('authState', ...)`](#addlistenerauthstate)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### signIn(...)

```typescript
signIn(options: { params?: Record<string, string>; biometric?: boolean; }) => Promise<void>
```

| Param         | Type                                                                                               |
| ------------- | -------------------------------------------------------------------------------------------------- |
| **`options`** | <code>{ params?: <a href="#record">Record</a>&lt;string, string&gt;; biometric?: boolean; }</code> |

--------------------


### signOut()

```typescript
signOut() => Promise<void>
```

--------------------


### register(...)

```typescript
register(params: Record<string, string>) => Promise<void>
```

| Param        | Type                                                            |
| ------------ | --------------------------------------------------------------- |
| **`params`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code> |

--------------------


### recoveryPassword(...)

```typescript
recoveryPassword(params: Record<string, string>) => Promise<void>
```

| Param        | Type                                                            |
| ------------ | --------------------------------------------------------------- |
| **`params`** | <code><a href="#record">Record</a>&lt;string, string&gt;</code> |

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


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### AuthState

| Prop                       | Type                 |
| -------------------------- | -------------------- |
| **`accessToken`**          | <code>string</code>  |
| **`isBiometricSupported`** | <code>boolean</code> |
| **`isBiometricEnabled`**   | <code>boolean</code> |


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>

</docgen-api>
