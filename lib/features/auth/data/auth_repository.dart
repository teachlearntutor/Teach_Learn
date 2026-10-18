import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Exception thrown when authentication fails with a user-friendly message.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Result object for Google Sign In flow indicating whether role picker is required for a new user.
class GoogleAuthResult {
  final User user;
  final bool isNewUser;
  final String? existingRole;

  GoogleAuthResult({
    required this.user,
    required this.isNewUser,
    this.existingRole,
  });
}

/// Unambiguous uppercase alphanumeric characters for public IDs (excludes 0, O, 1, I, L)
const String _kUnambiguousChars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

bool _isGoogleSignInInitialized = false;

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<User?> get userChanges => _auth.userChanges();
  User? get currentUser => _auth.currentUser;

  /// Map Firebase Auth exceptions to friendly, clear English user messages.
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'Invalid email address or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 8 characters.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address using a different sign-in method.';
      default:
        return e.message ?? 'An unexpected authentication error occurred.';
    }
  }

  /// Ensure GoogleSignIn instance is initialized exactly once per app lifecycle
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      try {
        await GoogleSignIn.instance.initialize(
          serverClientId: '920270768909-tcueboq3pt1obkvvabtam31fb1svmntq.apps.googleusercontent.com',
        );
        _isGoogleSignInInitialized = true;
      } catch (_) {
        // Fallback initialization
      }
    }
  }

  /// Sign up user with email, password, display name, and role.
  /// Creates users/{uid} and publicIds/{id} atomically in a transaction.
  /// Deletes the Auth user if Firestore creation fails so user can retry.
  Future<User> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    User? createdUser;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      createdUser = credential.user;
      if (createdUser == null) {
        throw AuthException('Failed to create account. Please try again.');
      }

      final uid = createdUser.uid;
      final cleanName = name.trim();
      final cleanEmail = email.trim();
      final cleanRole = role.toLowerCase().trim();

      // Update Firebase Auth display name
      await createdUser.updateDisplayName(cleanName);

      // Atomic reservation of publicId and creation of users/{uid} document
      await _createUsersDocumentWithRandomPublicId(
        uid: uid,
        displayName: cleanName,
        email: cleanEmail,
        photoUrl: createdUser.photoURL,
        role: cleanRole,
      );

      return createdUser;
    } on FirebaseAuthException catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      if (e is AuthException) rethrow;
      throw AuthException('Account creation failed. Please try again.');
    }
  }

  /// Log in existing user with email & password.
  Future<User> logInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw AuthException('Could not sign in. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to log in. Please try again.');
    }
  }

  /// Sign in with Google using native GoogleSignIn credential.
  Future<GoogleAuthResult> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = account.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw AuthException('Could not retrieve Google ID token. Please verify Google Sign-In is enabled in Firebase Console.');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Google sign-in failed. Please try again.');
      }

      // Check if user record already exists in users/{uid}
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null && doc.data()!['role'] != null) {
        final existingRole = doc.data()!['role'] as String;
        return GoogleAuthResult(
          user: user,
          isNewUser: false,
          existingRole: existingRole,
        );
      }

      return GoogleAuthResult(
        user: user,
        isNewUser: true,
        existingRole: null,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Google sign-in was cancelled.');
      }
      throw AuthException('Google sign-in failed (${e.code}). Please check your configuration.');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Complete role setup for a new Google user
  Future<void> completeGoogleProfileCreation({
    required User user,
    required String role,
  }) async {
    await _createUsersDocumentWithRandomPublicId(
      uid: user.uid,
      displayName: user.displayName ?? 'TeachLearn User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      role: role.toLowerCase().trim(),
    );
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException('Failed to send reset email. Please try again.');
    }
  }

  /// Reload currentUser
  Future<User?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return _auth.currentUser;
    }
    return null;
  }

  /// Fetch user document role from Firestore users/{uid}.
  /// NEVER defaults a missing role to tutor. Throws AuthException if document is missing or invalid.
  Future<String> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      throw AuthException('User profile record is missing in database.');
    }
    final role = doc.data()!['role'] as String?;
    if (role == null || role.isEmpty) {
      throw AuthException('User role is not assigned.');
    }
    return role;
  }

  /// Fetch full user profile document from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Repair missing profile for an existing Auth user
  Future<void> repairUserProfile({
    required String uid,
    required String displayName,
    required String email,
    required String role,
  }) async {
    await _createUsersDocumentWithRandomPublicId(
      uid: uid,
      displayName: displayName.trim(),
      email: email.trim(),
      photoUrl: null,
      role: role.toLowerCase().trim(),
    );
  }

  /// Sign out current user from FirebaseAuth & GoogleSignIn
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Generate random publicId (TL-7K3Q9) and reserve it atomically in Firestore
  Future<void> _createUsersDocumentWithRandomPublicId({
    required String uid,
    required String displayName,
    required String email,
    required String? photoUrl,
    required String role,
  }) async {
    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidateId = _generateRandomPublicId();
      final publicIdRef = _firestore.collection('publicIds').doc(candidateId);
      final userRef = _firestore.collection('users').doc(uid);

      try {
        await _firestore.runTransaction<void>((transaction) async {
          final publicIdDoc = await transaction.get(publicIdRef);
          if (publicIdDoc.exists) {
            throw _CollisionException();
          }

          transaction.set(publicIdRef, {
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

          transaction.set(userRef, {
            'displayName': displayName,
            'email': email,
            'photoUrl': photoUrl,
            'role': role,
            'publicId': candidateId,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });

        // Successfully created atomically!
        return;
      } on _CollisionException {
        // Retry with a new code
        continue;
      }
    }

    throw AuthException('Could not generate a unique public ID. Please try again.');
  }

  String _generateRandomPublicId() {
    final rand = math.Random.secure();
    final code = List.generate(5, (_) => _kUnambiguousChars[rand.nextInt(_kUnambiguousChars.length)]).join();
    return 'TL-$code';
  }
}

class _CollisionException implements Exception {}
