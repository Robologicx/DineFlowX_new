import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/services/auth_service.dart';

class AuthState {
  final User? firebaseUser;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const AuthState({this.firebaseUser, this.isLoading = false, this.error})
    : isLoggedIn = firebaseUser != null;

  AuthState copyWith({User? firebaseUser, bool? isLoading, String? error}) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final AuthService _service;

  AuthNotifier(this.ref, this._service) : super(const AuthState()) {
    // Initialize with current user on app start
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      state = state.copyWith(firebaseUser: currentUser);
    }
  }

  Future<void> signIn(
    BuildContext context,
    String email,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.signIn(email, password);
      state = state.copyWith(firebaseUser: user, isLoading: false);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.signUp(email, password);
      state = state.copyWith(firebaseUser: user, isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await AuthService().signOut();
      state = const AuthState(); // clear state completely
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearError() => state = state.copyWith(error: null);

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      await AuthService().deleteAccount();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
