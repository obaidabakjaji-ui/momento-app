import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/app_user.dart';
import 'room_service.dart';

/// Thrown by [AuthService.requestEmailCode] / [AuthService.verifyEmailCode]
/// for cases the UI should surface specially (e.g. cooldown, wrong code).
class EmailCodeException implements Exception {
  /// One of: `cooldown`, `expired`, `wrong-code`, `attempts-exhausted`,
  /// `no-pending`, `already-verified`, `unknown`.
  final String code;
  final String message;
  EmailCodeException(this.code, this.message);
  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  User? get currentUser => _auth.currentUser;
  // userChanges fires on sign-in/out AND on user property changes (e.g. when
  // emailVerified flips to true after reload). authStateChanges does NOT fire
  // for property updates, so AuthGate would otherwise never re-route after
  // verification finishes.
  Stream<User?> get authStateChanges => _auth.userChanges();

  Future<UserCredential> signUpWithEmail(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);
    await _createUserDoc(cred.user!, name);
    // Code is requested by VerifyEmailScreen on entry — that way both the
    // sign-up path and the existing-but-unverified sign-in path get a code
    // sent automatically without duplicating logic here.
    return cred;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Ask the backend to generate a fresh 6-digit code and email it to the
  /// signed-in user. Throws [EmailCodeException] for cooldown / already
  /// verified cases.
  Future<void> requestEmailCode() async {
    if (_auth.currentUser == null) {
      throw EmailCodeException('unauthenticated', 'Sign in first.');
    }
    try {
      await _functions.httpsCallable('requestEmailCode').call();
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e);
    }
  }

  /// Submit a 6-digit code. On success Firebase Auth's `emailVerified`
  /// flag flips to true (refreshed via [reloadCurrentUser]).
  Future<void> verifyEmailCode(String code) async {
    if (_auth.currentUser == null) {
      throw EmailCodeException('unauthenticated', 'Sign in first.');
    }
    try {
      await _functions.httpsCallable('verifyEmailCode').call({'code': code});
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e);
    }
    // Refresh local auth state so `isEmailVerified` returns true immediately.
    await reloadCurrentUser();
  }

  EmailCodeException _mapFunctionsException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'resource-exhausted':
        // Server uses this for both "wait Ns" and "too many attempts".
        if ((e.message ?? '').toLowerCase().contains('attempts')) {
          return EmailCodeException('attempts-exhausted',
              'Too many wrong attempts. Request a new code.');
        }
        return EmailCodeException('cooldown', e.message ?? 'Try again soon.');
      case 'deadline-exceeded':
        return EmailCodeException(
            'expired', 'That code expired. Tap resend for a new one.');
      case 'permission-denied':
        return EmailCodeException('wrong-code', 'Wrong code. Try again.');
      case 'failed-precondition':
        return EmailCodeException('no-pending',
            'No active code. Tap resend to get a new one.');
      default:
        return EmailCodeException(
            'unknown', e.message ?? 'Something went wrong.');
    }
  }

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    final googleUser = await googleSignIn.authenticate();

    final idToken = googleUser.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    final cred = await _auth.signInWithCredential(credential);

    // Create user doc if first time
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) {
      await _createUserDoc(cred.user!, cred.user!.displayName ?? 'User');
    }

    return cred;
  }

  Future<void> _createUserDoc(User user, String name) async {
    final appUser = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: name,
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(appUser.toMap());
  }

  Future<AppUser?> getCurrentAppUser() async {
    if (currentUser == null) return null;
    final doc = await _db.collection('users').doc(currentUser!.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  /// Permanently delete the current user's account.
  ///
  /// Cascades:
  /// 1. For each room they belong to: removes them from memberIds/adminIds,
  ///    or deletes the room entirely if they're its last member.
  /// 2. Deletes the user doc (posts they made remain — their sender info is
  ///    denormalized on each post, and posts expire naturally in 6 hours).
  /// 3. Deletes the Firebase Auth account.
  ///
  /// Throws [FirebaseAuthException] with code `requires-recent-login` if auth
  /// deletion needs reauthentication — callers should prompt and retry.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No user signed in');
    final uid = user.uid;

    // Fetch the user doc so we know which rooms to clean up.
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      final appUser = AppUser.fromFirestore(doc);
      final rooms = RoomService();
      for (final roomId in appUser.roomIds) {
        try {
          await rooms.leaveRoom(roomId: roomId, userId: uid);
        } catch (_) {
          // Continue on a single room failure — we still want to delete the
          // rest. A stale/missing room shouldn't block account deletion.
        }
      }
      // leaveRoom already removes the user from each room doc, but the user's
      // own doc still exists. Delete it now.
      await _db.collection('users').doc(uid).delete();
    }

    // Finally, delete the auth account itself. This may throw
    // `requires-recent-login`; UI handles that.
    await user.delete();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
