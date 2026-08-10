import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository_provider.dart';

final authProvider = NotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = true;

    try {
      final authRepository = ref.read(authRepositoryProvider);

      await authRepository.signIn(
        email: email,
        password: password,
      );
    } finally {
      state = false;
    }
  }

  Future<void> signOut() async {
    state = true;

    try {
      final authRepository = ref.read(authRepositoryProvider);

      await authRepository.signOut();
    } finally {
      state = false;
    }
  }
}