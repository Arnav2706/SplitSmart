import 'dart:async';
import '../models/app_user.dart';

class LocalAuthService {
  final _authStateController = StreamController<AppUser?>.broadcast();
  
  // We mock a local user
  AppUser _currentUser = const AppUser(
    id: 'local_user',
    name: 'My Device',
    upiId: 'local@okicici',
  );

  LocalAuthService() {
    // Immediately emit the signed-in user
    Future.microtask(() => _authStateController.add(_currentUser));
  }

  AppUser? get currentUser => _currentUser;

  Stream<AppUser?> get authStateChanges {
    Future.microtask(() => _authStateController.add(_currentUser));
    return _authStateController.stream;
  }

  Future<void> signInAnonymously(String name, String upiId) async {
    _currentUser = AppUser(
      id: 'local_user',
      name: name,
      upiId: upiId,
    );
    _authStateController.add(_currentUser);
  }

  Future<void> signOut() async {
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
