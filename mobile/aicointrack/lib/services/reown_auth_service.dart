import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../config/constants.dart';

/// Handles "Sign in with Wallet" via Reown AppKit (WalletConnect v2) + SIWE.
///
/// Primary wallet authentication service using Reown AppKit.
/// Call [ReownAuthService.init] once at app start (in main.dart),
/// then [ReownAuthService.loginWithWallet] from the login page.
class ReownAuthService {
  static ReownAppKitModal? _appKitModal;
  static bool _initialized = false;

  // ── Initialise once at app start ────────────────────────────────────────────

  static Future<void> init(BuildContext context) async {
    if (_initialized) return;

    // SIWE requires EVM-only; remove Solana so One-Click Auth is enabled.
    ReownAppKitModalNetworks.removeSupportedNetworks('solana');

    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: AppConstants.REOWN_PROJECT_ID,
      metadata: const PairingMetadata(
        name: AppConstants.APP_NAME,
        description: AppConstants.APP_DESCRIPTION,
        url: AppConstants.APP_URL,
        icons: [AppConstants.APP_ICON_URL],
        redirect: Redirect(
          // Deep-link back to this app after wallet approval.
          native: 'aicointrack://',
          universal: AppConstants.APP_URL,
        ),
      ),
      siweConfig: SIWEConfig(
        // --- Nonce ----------------------------------------------------------
        getNonce: () async {
          // In production call your backend: await ApiService.getSiweNonce();
          // For now we use the built-in generator so no backend round-trip is needed.
          return SIWEUtils.generateNonce();
        },

        // --- Message params -------------------------------------------------
        getMessageParams: () async {
          return SIWEMessageArgs(
            domain: Uri.parse(AppConstants.APP_URL).authority,
            uri: AppConstants.APP_URL,
            statement: 'Sign in to ${AppConstants.APP_NAME}',
            methods: MethodsConstants.allMethods,
          );
        },

        // --- Build the EIP-4361 message -------------------------------------
        createMessage: (SIWECreateMessageArgs args) {
          return SIWEUtils.formatMessage(args);
        },

        // --- Verify the signed message --------------------------------------
        verifyMessage: (SIWEVerifyMessageArgs args) async {
          try {
            final chainId = SIWEUtils.getChainIdFromMessage(args.message);
            final address = SIWEUtils.getAddressFromMessage(args.message);

            final cacaoSignature = args.cacao != null
                ? args.cacao!.s
                : CacaoSignature(
                    t: CacaoSignature.EIP191,
                    s: args.signature,
                  );

            // Verify the signature cryptographically.
            final valid = await SIWEUtils.verifySignature(
              address,
              args.message,
              cacaoSignature,
              chainId,
              AppConstants.REOWN_PROJECT_ID,
            );

            if (!valid) return false;

            // Authenticate against your backend (same /auth/wallet endpoint).
            final data = await ApiService.walletLogin(
              address: address,
              signature: args.signature,
              message: args.message,
            );

            final jwt = data['jwt'] ?? data['accessToken'];
            if (jwt == null) return false;
            await TokenService.saveJwt(jwt as String);

            // Optionally sign into Firebase with a custom token if the backend
            // returned one.
            final firebaseToken = data['firebase_custom_token'] as String?;
            if (firebaseToken != null && firebaseToken.isNotEmpty) {
              try {
                await AuthService.signInWithCustomToken(firebaseToken);
              } catch (e) {
                debugPrint('Firebase custom token sign-in skipped: $e');
              }
            }

            return true;
          } catch (e) {
            debugPrint('SIWE verifyMessage error: $e');
            return false;
          }
        },

        // --- Return the session after sign-in --------------------------------
        getSession: () async {
          try {
            if (_appKitModal == null || _appKitModal!.session == null) {
              return null;
            }
            final chainId =
                _appKitModal!.selectedChain?.chainId ?? '8453'; // Base
            final namespace =
                ReownAppKitModalNetworks.getNamespaceForChainId(chainId);
            final address = _appKitModal!.session!.getAddress(namespace);
            if (address == null) return null;
            return SIWESession(address: address, chains: [chainId]);
          } catch (e) {
            debugPrint('SIWE getSession error: $e');
            return null;
          }
        },

        // --- Sign out -------------------------------------------------------
        signOut: () async {
          await TokenService.clearJwt();
          return true;
        },

        onSignIn: (SIWESession session) {
          debugPrint('✓ Reown SIWE sign-in: ${session.address}');
        },
        onSignOut: () {
          debugPrint('✓ Reown SIWE sign-out');
        },
      ),
    );

    await _appKitModal!.init();
    _initialized = true;
    debugPrint('✓ ReownAppKit initialized');
  }

  // ── Public helpers ──────────────────────────────────────────────────────────

  static ReownAppKitModal? get modal => _appKitModal;
  static bool get isInitialized => _initialized;

  /// Opens the Reown AppKit connect/sign modal.
  /// Returns `true` when the user successfully authenticated.
  static Future<bool> loginWithWallet(BuildContext context) async {
    if (_appKitModal == null) {
      throw StateError(
          'ReownAuthService.init() must be called before loginWithWallet()');
    }
    try {
      await _appKitModal!.openModalView();
      // The SIWE flow runs inside the modal; check whether we got a session.
      return _appKitModal!.session != null;
    } catch (e) {
      debugPrint('Reown login error: $e');
      return false;
    }
  }

  /// Disconnect the current wallet session.
  static Future<void> disconnect() async {
    if (_appKitModal != null && _appKitModal!.session != null) {
      await _appKitModal!.disconnect();
    }
    await TokenService.clearJwt();
  }
}