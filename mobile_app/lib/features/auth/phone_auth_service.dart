import 'package:firebase_auth/firebase_auth.dart';
import '../../db/local_db_service.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          onError('Invalid phone number. Use format: +263771234567');
        } else if (e.code == 'too-many-requests') {
          onError('Too many attempts. Please wait before trying again.');
        } else {
          onError(e.message ?? 'Phone verification failed.');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithCredential(
      PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  // Save phone user to local DB if new
  Future<void> savePhoneUserLocally({
    required String uid,
    required String phoneNumber,
    String? fullName,
  }) async {
    final existing = await LocalDbService.getUser(uid);
    if (existing == null) {
      await LocalDbService.saveUser({
        'uid': uid,
        'full_name': fullName ?? '',
        'phone_number': phoneNumber,
        'role': 'midwife',
        'login_method': 'phone',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }
}