import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mengambil user yang sedang login (atau null jika belum login)
  User? get currentUser => _auth.currentUser;

  /// Stream status login user secara real-time
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registrasi akun baru dengan email dan password
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  /// Login akun yang sudah terdaftar dengan email dan password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  /// Logout pengguna saat ini
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  /// Pesan error yang mudah dipahami untuk ditampilkan di UI
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa jaringan kamu.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi (${e.code}).';
    }
  }
}