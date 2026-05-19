import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginService {
  LoginService._();
  static final LoginService instance = LoginService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user != null) {
        try {
          await user.updateDisplayName(name);

          await _db.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': name,
            'email': email,
            'phone': phone,
            'createdAt': FieldValue.serverTimestamp(),
            'platform': 'email',
            'role': 'user',
          });
        } catch (e) {
          await user.delete();
          throw 'Не удалось сохранить данные пользователя. Попробуйте ещё раз.';
        }
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Произошла непредвиденная ошибка: $e';
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn().catchError((e) => print("Внутренняя ошибка Google: $e"));
      if (googleUser == null) throw 'Вход отменен пользователем';

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Ошибка при работе с Google: $e';
    }
  }

  Future<void> completeGoogleProfile({
    required String name,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'Пользователь не найден. Перезайдите.';
    }

    final displayName = name.isEmpty ? user.displayName ?? 'Пользователь Google' : name;

    try {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': displayName,
        'email': user.email ?? '',
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'google',
        'role': 'user',
      }, SetOptions(merge: true));

      if (displayName.isNotEmpty && user.displayName != displayName) {
        await user.updateDisplayName(displayName);
      }
    } catch (e) {
      throw 'Не удалось сохранить профиль: $e';
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Ошибка при выходе: $e');
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Пользователь с таким email не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Этот email уже используется';
      case 'invalid-email':
        return 'Некорректный формат email';
      case 'weak-password':
        return 'Пароль слишком слабый';
      case 'user-disabled':
        return 'Аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'operation-not-allowed':
        return 'Этот метод входа не включен в консоли Firebase';
      default:
        return e.message ?? 'Ошибка аутентификации';
    }
  }
}

