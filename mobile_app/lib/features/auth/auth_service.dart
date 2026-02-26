import 'package:firebase_auth/firebase_auth.dart';
import '../../db/local_db_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login with ID number + station password
  Future<UserCredential> login({
    required String idNumber,
    required String stationPassword,
  }) async {
    final email = '${idNumber.trim()}@ruvimbo.health';
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: stationPassword.trim(),
    );
  }

  // Sign up - creates Firebase Auth account and saves profile locally
  Future<UserCredential> signUp({
    required String fullName,
    required String idNumber,
    required String stationIdNumber,
    required String stationPassword,
  }) async {
    final email = '${idNumber.trim()}@ruvimbo.health';

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: stationPassword.trim(),
    );

    await credential.user!.updateDisplayName(fullName);

    // Save locally
    await LocalDbService.saveUser({
      'uid': credential.user!.uid,
      'full_name': fullName,
      'id_number': idNumber,
      'station_id': stationIdNumber,
      'role': 'midwife',
      'login_method': 'email',
      'created_at': DateTime.now().toIso8601String(),
    });

    return credential;
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  Future<void> reauthenticate({
    required String idNumber,
    required String currentPassword,
  }) async {
    final email = '${idNumber.trim()}@ruvimbo.health';
    final cred = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await _auth.currentUser!.reauthenticateWithCredential(cred);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get profile from local DB
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    final local = await LocalDbService.getUser(currentUser!.uid);
    if (local != null) return local;
    // Fallback to Firebase display name
    return {
      'full_name': currentUser!.displayName ?? '',
      'uid': currentUser!.uid,
    };
  }
}