import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Custom domain exception for Auth operations.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Result payload for Google Sign-In flow.
class GoogleSignInResult {
  final User user;
  final bool isNewUser;
  final String? existingRole;

  const GoogleSignInResult({
    required this.user,
    required this.isNewUser,
    this.existingRole,
  });
}

/// Production-ready authentication repository wrapping FirebaseAuth & Cloud Firestore.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String kWebClientId =
      '920270768909-tcueboq3pt1obkvvabtam31fb1svmntq.apps.googleusercontent.com';

  static bool _googleSignInInitialized = false;
  static Future<void>? _googleSignInFuture;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Expose authStateChanges stream for real-time auth state listening
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Expose userChanges stream for profile/verification updates
  Stream<User?> get userChanges => _auth.userChanges();

  /// Expose current logged-in user instance
  User? get currentUser => _auth.currentUser;

  /// Initialize GoogleSignIn client configuration exactly once
  static Future<void> initializeGoogleSignIn() {
    if (_googleSignInInitialized) return Future.value();
    _googleSignInFuture ??= () async {
      try {
        await GoogleSignIn.instance.initialize(serverClientId: kWebClientId);
        _googleSignInInitialized = true;
      } catch (_) {}
    }();
    return _googleSignInFuture!;
  }

  /// Send email verification to current logged-in user
  Future<void> sendEmailVerification([User? user]) async {
    try {
      final targetUser = user ?? _auth.currentUser;
      await targetUser?.sendEmailVerification();
    } catch (_) {}
  }

  /// Reload current logged-in user data
  Future<void> reloadCurrentUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (_) {}
  }

  /// Sign Up with Email and Password
  Future<User> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final normalizedRole = role.toLowerCase().trim();
      if (!_isValidRole(normalizedRole)) {
        throw const AuthException('Please select a valid account role.');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Account creation failed. Please try again.');
      }

      await user.updateDisplayName(name.trim());

      // Atomic reservation of publicId and creation of users/{uid} document
      await _createUsersDocumentWithRandomPublicId(
        user: user,
        displayName: name.trim(),
        email: email.trim(),
        photoUrl: user.photoURL,
        role: normalizedRole,
        deleteAuthUserOnFailure: true,
      );

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const AuthException(
          'Registration failed. Firestore permissions denied.',
        );
      }
      throw AuthException(e.message ?? 'Failed to initialize user profile.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }

  /// Log In with Email and Password
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
        throw const AuthException('Login failed. Invalid user credentials.');
      }

      // Check if user has corresponding users/{uid} doc
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        throw const AuthException(
          'Account profile incomplete. Please repair profile or choose role.',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }

  /// Sign In or Sign Up using Google Sign-In
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      await initializeGoogleSignIn();
      final googleAccount = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException(
          'Google sign-in failed. Unable to authenticate.',
        );
      }

      // Check if user already exists in Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return GoogleSignInResult(user: user, isNewUser: true);
      }

      final roleValue = doc.data()?['role'];
      if (roleValue is! String || !_isValidRole(roleValue)) {
        throw const AuthException(
          'This account profile has no valid role and cannot be repaired automatically.',
        );
      }
      final role = roleValue;
      return GoogleSignInResult(
        user: user,
        isNewUser: false,
        existingRole: role,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Fetch user role from Firestore
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        throw const AuthException('User profile record not found.');
      }
      final role = doc.data()?['role'] as String?;
      if (role == null || role.isEmpty) {
        throw const AuthException('User role is unassigned.');
      }
      return role;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to retrieve user role: ${e.toString()}');
    }
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
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) {
      throw const AuthException(
        'The signed-in account changed. Please sign in again.',
      );
    }
    final normalizedRole = role.toLowerCase().trim();
    if (!_isValidRole(normalizedRole)) {
      throw const AuthException('Please select a valid account role.');
    }
    await _createUsersDocumentWithRandomPublicId(
      user: user,
      displayName: displayName.trim(),
      email: email.trim(),
      photoUrl: user.photoURL,
      role: normalizedRole,
      deleteAuthUserOnFailure: false,
    );
  }

  bool _isValidRole(String role) =>
      role == 'tutor' || role == 'student' || role == 'parent';

  /// Sign out current user from FirebaseAuth & GoogleSignIn
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Delete current user account and user subcollections in Firestore, then Auth user
  Future<void> deleteUserAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No active user session found.');
    }

    final uid = user.uid;

    // 1. Re-authenticate
    final providerData = user.providerData;
    final isPasswordUser = providerData.any((p) => p.providerId == 'password');
    final isGoogleUser = providerData.any((p) => p.providerId == 'google.com');

    try {
      if (isPasswordUser) {
        if (password == null || password.isEmpty) {
          throw const AuthException(
            'Please enter your password to confirm account deletion.',
          );
        }
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(cred);
      } else if (isGoogleUser) {
        await initializeGoogleSignIn();
        final googleAccount = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleAccount.authentication;
        final cred = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
        await user.reauthenticateWithCredential(cred);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const AuthException(
          'Incorrect password. Re-authentication failed.',
        );
      }
      throw AuthException(e.message ?? 'Re-authentication failed.');
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Re-authentication failed: $e');
    }

    try {
      final userDoc = _firestore.collection('users').doc(uid);
      final students = await userDoc.collection('students').get();
      for (final student in students.docs) {
        final tests = await student.reference.collection('tests').get();
        await _deleteDocumentsInChunks(tests.docs);
      }
      await _deleteDocumentsInChunks(students.docs);

      for (final subcollection in [
        'attendance',
        'holidays',
        'classes',
        'sessions',
      ]) {
        final documents = await userDoc.collection(subcollection).get();
        await _deleteDocumentsInChunks(documents.docs);
      }

      await _firestore
          .collection('tutorProfiles')
          .doc(uid)
          .collection('private')
          .doc('contact')
          .delete();
      await _firestore.collection('tutorProfiles').doc(uid).delete();

      await userDoc.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const AuthException(
          "You don't have permission to delete these records.",
        );
      }
      throw AuthException('Failed to delete account data: ${e.message}');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to delete account data: $e');
    }

    // 6. Delete Auth user (only after Firestore deletion succeeds)
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Failed to delete account credentials.');
    }
  }

  Future<void> _deleteDocumentsInChunks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    const chunkSize = 400;
    for (var start = 0; start < documents.length; start += chunkSize) {
      final end = (start + chunkSize).clamp(0, documents.length);
      final batch = _firestore.batch();
      for (final document in documents.sublist(start, end)) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  /// Generate random publicId (TL-7K3Q9) and reserve it atomically in Firestore
  Future<void> _createUsersDocumentWithRandomPublicId({
    required User user,
    required String displayName,
    required String email,
    required String? photoUrl,
    required String role,
    required bool deleteAuthUserOnFailure,
  }) async {
    const maxAttempts = 5;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidateId = _generateRandomPublicId();
      final publicIdRef = _firestore.collection('publicIds').doc(candidateId);
      final userRef = _firestore.collection('users').doc(user.uid);

      try {
        await _firestore.runTransaction<void>((transaction) async {
          final publicIdDoc = await transaction.get(publicIdRef);
          if (publicIdDoc.exists) {
            throw Exception('Public ID collision. Retrying...');
          }

          transaction.set(publicIdRef, {
            'uid': user.uid,
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

        // Reservation succeeded
        return;
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          // If transaction failed after 5 attempts, clean up Auth user if newly created
          if (deleteAuthUserOnFailure) {
            try {
              await user.delete();
            } catch (_) {}
          }
          throw const AuthException(
            'Failed to assign unique Public ID. Please try again.',
          );
        }
      }
    }
  }

  String _generateRandomPublicId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    final code = List.generate(
      5,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
    return 'TL-$code';
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'email-not-found':
        return 'No account exists with this email address.';
      case 'too-many-requests':
        return 'Too many reset attempts. Please wait a moment and try again.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please check your credentials.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}
