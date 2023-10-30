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
* [`getUser()`](#getuser)
* [`addListener('initSuccess', ...)`](#addlistenerinitsuccess)
* [`addListener('initError', ...)`](#addlisteneriniterror)
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
signOut() => Promise<{ value: number; }>
```

**Returns:** <code>Promise&lt;{ value: number; }&gt;</code>

--------------------


### getUser()

```typescript
getUser() => Promise<{ [key: string]: any; }>
```

**Returns:** <code>Promise&lt;{ [key: string]: any; }&gt;</code>

--------------------


### addListener('initSuccess', ...)

```typescript
addListener(eventName: 'initSuccess', listenerFunc: (data: AuthStateDetails) => void) => PluginListenerHandle
```

| Param              | Type                                                                             |
| ------------------ | -------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'initSuccess'</code>                                                       |
| **`listenerFunc`** | <code>(data: <a href="#authstatedetails">AuthStateDetails</a>) =&gt; void</code> |

**Returns:** <code><a href="#pluginlistenerhandle">PluginListenerHandle</a></code>

--------------------


### addListener('initError', ...)

```typescript
addListener(eventName: 'initError', listenerFunc: (error: { description?: string; }) => void) => PluginListenerHandle
```

| Param              | Type                                                       |
| ------------------ | ---------------------------------------------------------- |
| **`eventName`**    | <code>'initError'</code>                                   |
| **`listenerFunc`** | <code>(error: { description?: string; }) =&gt; void</code> |

**Returns:** <code><a href="#pluginlistenerhandle">PluginListenerHandle</a></code>

--------------------


### addListener('authState', ...)

```typescript
addListener(eventName: 'authState', listenerFunc: (data: AuthStateDetails) => void) => PluginListenerHandle
```

| Param              | Type                                                                             |
| ------------------ | -------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'authState'</code>                                                         |
| **`listenerFunc`** | <code>(data: <a href="#authstatedetails">AuthStateDetails</a>) =&gt; void</code> |

**Returns:** <code><a href="#pluginlistenerhandle">PluginListenerHandle</a></code>

--------------------


### Interfaces


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### AuthStateDetails

| Prop                       | Type                 |
| -------------------------- | -------------------- |
| **`accessToken`**          | <code>string</code>  |
| **`isBiometricSupported`** | <code>boolean</code> |


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>

</docgen-api>
