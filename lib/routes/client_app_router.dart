import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/presentation/client_screens/auth/client_login_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/cart/add_to_cart.dart';
import 'package:hotel_management_system/presentation/client_screens/cart/check_out_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/categories/all_food_items_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/home/client_shell.dart';
import 'package:hotel_management_system/presentation/client_screens/menu_screens/my_profile_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/menu_screens/order_history_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/onboarding/on_boarding_screen.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';

/// Centralized GoRouter configuration for the Client App
class ClientAppRouter {
  static String? _businessKeyFromClientHost(Uri uri) {
    final host = uri.host.trim().toLowerCase();
    if (host.isEmpty) return null;

    // Expected host format: businessname-client.dineflowx.com
    const suffix = '.dineflowx.com';
    if (!host.endsWith(suffix)) return null;

    final left = host.substring(0, host.length - suffix.length);
    if (left.isEmpty || !left.endsWith('-client')) return null;

    final key = left.substring(0, left.length - '-client'.length).trim();
    return key.isEmpty ? null : key;
  }

  static final GoRouter router = GoRouter(
    initialLocation: FirebaseAuth.instance.currentUser == null
        ? '/${ClientAppRoutes.onBoarding}'
        : '/${ClientAppRoutes.shell}',
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final onboardingPath = '/${ClientAppRoutes.onBoarding}';
      final loginPath = '/${ClientAppRoutes.login}';
      final shellPath = '/${ClientAppRoutes.shell}';

      final atOnboarding = state.matchedLocation == onboardingPath;
      final atLogin = state.matchedLocation == loginPath;

      if (isLoggedIn && (atOnboarding || atLogin)) {
        return shellPath;
      }

      return null;
    },
    routes: [
      // Root: if opened from businessname-client.dineflowx.com, resolve tenant.
      GoRoute(
        path: '/',
        builder: (context, state) {
          final businessKey = _businessKeyFromClientHost(state.uri);
          if (businessKey != null) {
            return _BusinessPathClientEntry(
              businessKey: businessKey,
              branchId: state.uri.queryParameters['branchId'],
              tableId: state.uri.queryParameters['tableId'],
            );
          }

          // Fallback for direct root opens without business-specific host.
          return OnBoardingScreen();
        },
      ),

      /// ✅ Onboarding
      GoRoute(
        path: '/${ClientAppRoutes.onBoarding}',
        name: ClientAppRoutes.onBoarding,
        builder: (context, state) => OnBoardingScreen(),
      ),
      GoRoute(
        path: '/${ClientAppRoutes.checkOut}',
        name: ClientAppRoutes.checkOut,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final items = (extra['items'] as List<OrderItem>?) ?? [];
          final totalAmount = extra['totalAmount'] as double? ?? 0.0;

          return CheckOutScreen(items: items, totalAmount: totalAmount);
        },
      ),
      GoRoute(
        path: '/${ClientAppRoutes.orderHistory}',
        name: ClientAppRoutes.orderHistory,
        builder: (context, state) => OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/${ClientAppRoutes.shell}',
        name: ClientAppRoutes.shell,
        builder: (context, state) {
          final tableId = state.uri.queryParameters['tableId'];
          final businessId = state.uri.queryParameters['businessId'];
          final branchId = state.uri.queryParameters['branchId'];
          return ClientHomeShell(
            tableId: tableId,
            businessId: businessId,
            branchId: branchId,
          );
        },
      ),

      /// ✅ Login
      GoRoute(
        path: '/${ClientAppRoutes.login}',
        name: ClientAppRoutes.login,
        builder: (context, state) => const ClientLoginScreen(),
      ),

      /// ✅ Other independent screens
      GoRoute(
        path: '/${ClientAppRoutes.allFoodItems}',
        name: ClientAppRoutes.allFoodItems,
        builder: (context, state) {
          // Extract tableId from query parameters
          final tableId = state.uri.queryParameters['tableId'] ?? '';
          return AllFoodItemsScreen(
            tableId: tableId, // Provide default or handle null
          );
        },
      ),
      GoRoute(
        path: '/${ClientAppRoutes.cartScreen}',
        name: ClientAppRoutes.cartScreen,
        builder: (context, state) {
          final tableId = state.uri.queryParameters['tableId'];
          final businessId = state.uri.queryParameters['businessId'] ?? '';
          final branchId = state.uri.queryParameters['branchId'] ?? '';
          return AddToCartScreen(
            businessId: businessId,
            branchId: branchId,
            tableId: tableId,
          );
        },
      ),
      GoRoute(
        path: '/${ClientAppRoutes.myProfile}',
        name: ClientAppRoutes.myProfile,
        builder: (context, state) => MyProfileScreen(),
      ),

      // Public per-business client paths.
      // Keep these after static paths so routes like /addToCartScreen
      // are not accidentally captured as a business key.
      GoRoute(
        path: '/:businessKey',
        builder: (context, state) {
          return _BusinessPathClientEntry(
            businessKey: state.pathParameters['businessKey'] ?? '',
            businessIdHint: state.uri.queryParameters['businessId'],
            branchId: state.uri.queryParameters['branchId'],
            tableId: state.uri.queryParameters['tableId'],
          );
        },
      ),
      GoRoute(
        path: '/:businessKey/clientapp',
        builder: (context, state) {
          return _BusinessPathClientEntry(
            businessKey: state.pathParameters['businessKey'] ?? '',
            businessIdHint: state.uri.queryParameters['businessId'],
            branchId: state.uri.queryParameters['branchId'],
            tableId: state.uri.queryParameters['tableId'],
          );
        },
      ),
      // Backward-compatible typo path
      GoRoute(
        path: '/:businessKey/cleintapp',
        builder: (context, state) {
          return _BusinessPathClientEntry(
            businessKey: state.pathParameters['businessKey'] ?? '',
            businessIdHint: state.uri.queryParameters['businessId'],
            branchId: state.uri.queryParameters['branchId'],
            tableId: state.uri.queryParameters['tableId'],
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('404 - Page not found'))),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _BusinessPathClientEntry extends StatelessWidget {
  const _BusinessPathClientEntry({
    required this.businessKey,
    this.businessIdHint,
    this.branchId,
    this.tableId,
  });

  final String businessKey;
  final String? businessIdHint;
  final String? branchId;
  final String? tableId;

  String _slugify(String input) {
    final lower = input
        .trim()
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll('+', ' and ');
    final buffer = StringBuffer();
    var lastDash = false;
    for (final codeUnit in lower.codeUnits) {
      final isAlphaNum =
          (codeUnit >= 48 && codeUnit <= 57) ||
          (codeUnit >= 97 && codeUnit <= 122);
      if (isAlphaNum) {
        buffer.writeCharCode(codeUnit);
        lastDash = false;
      } else if (!lastDash) {
        buffer.write('-');
        lastDash = true;
      }
    }
    final value = buffer.toString();
    return value.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String _compactKey(String input) {
    final lower = input
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll('+', 'and');
    final buffer = StringBuffer();
    for (final codeUnit in lower.codeUnits) {
      final isAlphaNum =
          (codeUnit >= 48 && codeUnit <= 57) ||
          (codeUnit >= 97 && codeUnit <= 122);
      if (isAlphaNum) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  String _normalizeTitleLookup(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _buildTitleLookupCandidates(String key) {
    final candidates = <String>{};
    final base = _normalizeTitleLookup(key);
    if (base.isNotEmpty) {
      candidates.add(base);
    }

    final spacedAnd = base
        .replaceAllMapped(
          RegExp(r'([a-z0-9])and([a-z0-9])'),
          (m) => '${m[1]} and ${m[2]}',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (spacedAnd.isNotEmpty) {
      candidates.add(spacedAnd);
    }

    for (final current in List<String>.from(candidates)) {
      if (current.contains(' and ')) {
        candidates.add(current.replaceAll(' and ', ' & '));
        candidates.add(current.replaceAll(' and ', ' + '));
      }
      if (current.contains('&')) {
        candidates.add(current.replaceAll('&', ' and '));
      }
      if (current.contains('+')) {
        candidates.add(current.replaceAll('+', ' and '));
      }
    }

    return candidates
        .map((v) => v.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<String?> _resolveBusinessId(String key) async {
    final hintedId = (businessIdHint ?? '').trim();
    if (hintedId.isNotEmpty) {
      final hintedDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(hintedId)
          .get();
      if (hintedDoc.exists) {
        return hintedDoc.id;
      }
    }

    final trimmed = key.trim();
    if (trimmed.isEmpty) return null;

    final businesses = FirebaseFirestore.instance.collection('businesses');

    final publicKey = _compactKey(trimmed);
    if (publicKey.isNotEmpty) {
      try {
        final mappedDoc = await FirebaseFirestore.instance
            .collection('public_business_keys')
            .doc(publicKey)
            .get();
        final mappedBusinessId = (mappedDoc.data()?['businessId'] ?? '')
            .toString()
            .trim();
        if (mappedBusinessId.isNotEmpty) {
          final mappedBusiness = await businesses.doc(mappedBusinessId).get();
          if (mappedBusiness.exists) {
            return mappedBusiness.id;
          }
        }
      } catch (_) {
        // Ignore mapping lookup errors and continue with existing fallback logic.
      }
    }

    final byId = await businesses.doc(trimmed).get();
    if (byId.exists) return byId.id;

    final normalizedTitle = _normalizeTitleLookup(trimmed);
    final titleCandidates = _buildTitleLookupCandidates(trimmed);

    try {
      for (final candidate in titleCandidates) {
        final byLower = await businesses
            .where('title_lower', isEqualTo: candidate)
            .limit(1)
            .get();
        if (byLower.docs.isNotEmpty) return byLower.docs.first.id;
      }

      final byPrefix = await businesses
          .where('title_lower', isGreaterThanOrEqualTo: normalizedTitle)
          .where('title_lower', isLessThanOrEqualTo: '$normalizedTitle\uf8ff')
          .limit(1)
          .get();
      if (byPrefix.docs.isNotEmpty) return byPrefix.docs.first.id;
    } catch (_) {
      // Continue to paginated scan fallback when query rules/indexes reject.
    }

    final targetSlug = _slugify(trimmed);
    final targetCompact = _compactKey(trimmed);
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
    const pageSize = 200;

    while (true) {
      Query<Map<String, dynamic>> query = businesses
          .orderBy(FieldPath.documentId)
          .limit(pageSize);
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      QuerySnapshot<Map<String, dynamic>> page;
      try {
        page = await query.get();
      } catch (_) {
        break;
      }
      if (page.docs.isEmpty) {
        break;
      }

      for (final doc in page.docs) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString();
        final titleLower = (data['title_lower'] ?? '').toString();

        if (_slugify(title) == targetSlug ||
            _slugify(titleLower) == targetSlug ||
            _compactKey(title) == targetCompact ||
            _compactKey(titleLower) == targetCompact ||
            _compactKey(doc.id) == targetCompact) {
          return doc.id;
        }
      }

      if (page.docs.length < pageSize) {
        break;
      }

      lastDoc = page.docs.last;
    }

    return null;
  }

  Future<String> _resolveBranchId(String businessId, String? incoming) async {
    final provided = (incoming ?? '').trim();
    if (provided.isNotEmpty) return provided;

    final firstBranch = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .limit(1)
        .get();

    if (firstBranch.docs.isNotEmpty) {
      return firstBranch.docs.first.id;
    }

    return BusinessRepository.temporaryBranchId;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolveBusinessId(businessKey),
      builder: (context, businessSnapshot) {
        if (businessSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final businessId = (businessSnapshot.data ?? '').trim();
        if (businessId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Business not found for this client app URL.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return FutureBuilder<String>(
          future: _resolveBranchId(businessId, branchId),
          builder: (context, branchSnapshot) {
            if (branchSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final resolvedBranchId =
                (branchSnapshot.data ?? BusinessRepository.temporaryBranchId)
                    .trim();
            final trimmedTableId = (tableId ?? '').trim();

            return ClientHomeShell(
              businessId: businessId,
              branchId: resolvedBranchId,
              tableId: trimmedTableId.isEmpty ? null : trimmedTableId,
            );
          },
        );
      },
    );
  }
}
