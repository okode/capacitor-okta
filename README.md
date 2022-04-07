# capacitor-okta

Okta plugin

## Install

```bash
npm install capacitor-okta
npx cap sync
```

## API

<docgen-index>

* [`signInWithBrowser()`](#signinwithbrowser)
* [`signOut()`](#signout)
* [`getUser()`](#getuser)
* [`getAuthStateDetails()`](#getauthstatedetails)
* [`addListener('initSuccess', ...)`](#addlistenerinitsuccess)
* [`addListener('initError', ...)`](#addlisteneriniterror)
* [`addListener('authState', ...)`](#addlistenerauthstate)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### signInWithBrowser()

```typescript
signInWithBrowser() => Promise<AuthStateDetails>
```

**Returns:** <code>Promise&lt;<a href="#authstatedetails">AuthStateDetails</a>&gt;</code>

--------------------


### signOut()

```typescript
signOut() => Promise<AuthStateDetails>
```

**Returns:** <code>Promise&lt;<a href="#authstatedetails">AuthStateDetails</a>&gt;</code>

--------------------


### getUser()

```typescript
getUser() => Promise<{ [key: string]: any; }>
```

**Returns:** <code>Promise&lt;{ [key: string]: any; }&gt;</code>

--------------------


### getAuthStateDetails()

```typescript
getAuthStateDetails() => Promise<AuthStateDetails>
```

**Returns:** <code>Promise&lt;<a href="#authstatedetails">AuthStateDetails</a>&gt;</code>

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


#### AuthStateDetails

| Prop               | Type                 |
| ------------------ | -------------------- |
| **`isAuthorized`** | <code>boolean</code> |
| **`accessToken`**  | <code>string</code>  |
| **`refreshToken`** | <code>string</code>  |
| **`idToken`**      | <code>string</code>  |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |

</docgen-api>
