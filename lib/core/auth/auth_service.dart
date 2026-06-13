import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/dio_client.dart';

class AuthService {
  AuthService(this._client);

  final DioClient _client;
  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn();
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> currentUser() async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) return null;
    final res = await _client.dio.get('/auth/me');
    return res.data['user'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return _exchangeFirebaseToken(credential.user);
  }

  Future<Map<String, dynamic>> register(String name, String phone, String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user?.updateDisplayName(name);
    return _exchangeFirebaseToken(credential.user, name: name, phone: phone);
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    return _exchangeFirebaseToken(userCredential.user);
  }

  Future<Map<String, dynamic>> _exchangeFirebaseToken(User? firebaseUser, {String? name, String? phone}) async {
    if (firebaseUser == null) throw Exception('Firebase user missing');
    final idToken = await firebaseUser.getIdToken();
    final res = await _client.dio.post('/auth/verify-firebase', data: {
      'idToken': idToken,
      'name': name ?? firebaseUser.displayName,
      if (phone != null) 'phone': phone,
    });
    await _storage.write(key: 'jwt', value: res.data['token']);
    await _syncFcm();
    return res.data['user'] as Map<String, dynamic>;
  }

  Future<void> _syncFcm() async {
    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _client.dio.put('/auth/fcm-token', data: {'fcmToken': token});
  }

  Future<void> signOut() async {
    await _storage.delete(key: 'jwt');
    await _google.signOut();
    await _auth.signOut();
  }
}
