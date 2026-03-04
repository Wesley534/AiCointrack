# CoinTrack Auth Architecture

Unified authentication across **Google Sign-In**, **Email/Password**, and **Base Wallet** — all linking to one user record.

## Overview

- **Firebase** = Auth layer (who you are)
- **Backend (MySQL)** = Data layer (budgets, transactions, goals)
- **One user record** per person, identified by `firebase_uid` and optional `wallet_address`

## User Model (MySQL)

```python
# users table
firebase_uid       # Links to Firebase
email              # nullable for wallet-only users
wallet_address     # 0x... on Base
wallet_created_by_system
auth_providers     # ["google"], ["email"], ["wallet"]
```

## Backend Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/auth/firebase` | POST | Google or Email/Password login. Body: `{ "idToken": "..." }` |
| `/api/v1/auth/wallet` | POST | Miniapp/Flutter wallet SIWE. Body: `{ address, signature, message }` |
| `/api/v1/auth/link-wallet` | POST | Link wallet to existing Firebase account |
| `/api/v1/auth/me` | GET | Current user (JWT required) |
| `/api/v1/auth/create-wallet` | POST | Create smart wallet (placeholder; integrate Privy) |

## Flows

### Flow 1 — Google Sign-In (Flutter)
1. User taps "Get Started" or "Sign in with Google"
2. Firebase Google OAuth → ID token
3. POST `/auth/firebase` with `idToken`
4. Backend verifies, creates/updates user, returns JWT + user
5. Flutter stores JWT in SharedPreferences; all API calls use JWT

### Flow 2 — Email/Password (Flutter)
1. User taps "Sign in with email" → `EmailLoginPage`
2. `AuthService.createUserWithEmail()` or `signInWithEmail()`
3. Firebase returns ID token
4. `HomePage` calls `registerUserWithBackend()` → POST `/auth/firebase`
5. Same as above: JWT stored, used for API calls

### Flow 3 — Base Wallet (Miniapp)
1. User opens miniapp in Base app; wallet auto-injected
2. SIWE message signed with wallet
3. POST `/auth/wallet` with `{ address, signature, message }`
4. Backend verifies SIWE, finds/creates user, returns JWT (+ `firebase_custom_token` if available)
5. Miniapp stores JWT in localStorage; uses for API calls

### Flow 4 — Miniapp User Opens Flutter
1. User has account from miniapp (wallet-only)
2. In Flutter: "Continue with Base Wallet" → explain to use Base miniapp first
3. (Future) WalletConnect → SIWE → POST `/auth/wallet` → `firebase_custom_token`
4. Flutter: `AuthService.signInWithCustomToken(firebase_custom_token)`

## Setup

### Backend
- Add `siwe` and `eth-account` to `requirements.txt` (done)
- Run migration: `alembic upgrade head`
- Firebase service account needed for `create_custom_token` (wallet → Flutter flow)
- Enable Email/Password and Google in Firebase Console
- **Base Account (ERC-6492)** — if wallet verify fails for smart wallets:
  - `cd backend/scripts && npm install`
  - Ensure `node` is on PATH; verification will fall back to Viem

### Miniapp (Base App)
- Set `NEXT_PUBLIC_API_URL` in `.env.local` to your backend (e.g. `https://api.cointrack.xyz`)
- Uses SIWE (Sign-In with Ethereum) per [Base docs](https://docs.base.org/base-account/guides/authenticate-users)
- Fetches nonce from `GET /api/v1/auth/nonce` before sign-in
- JWT stored as `pocketpal_jwt` in localStorage
- For Base Account (smart wallet) / ERC-6492: install Node fallback in backend (see below)

### Flutter
- `shared_preferences` for JWT storage
- `AppConstants.BACKEND_URL` must point to backend
- Ensure Firebase Email/Password and Google providers are enabled
