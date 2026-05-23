import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/error/auth_exception_mapper.dart';

@injectable
class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _authService.signIn(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthExceptionMapper.fromAuth(e);
    }
  }

  /// Returns true if email confirmation is pending (session is null after signup).
  Future<bool> signUp({required String email, required String password}) async {
    try {
      final response = await _authService.signUp(email: email, password: password);
      return response.session == null;
    } on AuthException catch (e) {
      throw AuthExceptionMapper.fromAuth(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } on AuthException catch (e) {
      throw AuthExceptionMapper.fromAuth(e);
    }
  }

  String? get currentUserEmail => _authService.currentUser?.email;
}
