import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if user is already signed in
    _checkCurrentUser();
  }

  void _checkCurrentUser() async {
    try {
      _log('Checking for existing user session');
      final user = _auth.currentUser;
      if (user != null) {
        _log('User already signed in: ${user.email}');
        // User already signed in, navigate to dashboard
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        });
      } else {
        _log('No user currently signed in');
      }
    } catch (e, stackTrace) {
      _logError('Error checking current user', e, stackTrace);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Trigger Google Sign-In flow
      _log('Starting Google Sign-In flow');
      final GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (e, stackTrace) {
        _logError('Google Sign-In dialog failed', e, stackTrace);
        _showError('Failed to open Google Sign-In. Please try again.');
        return;
      }

      if (googleUser == null) {
        _log('User cancelled Google Sign-In');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _log('Google Sign-In successful: ${googleUser.email}');

      // Step 2: Obtain auth details from Google Sign-In
      _log('Getting Google authentication details');
      final GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        _log('Google authentication details obtained');
        
        // More flexible token validation
        if (googleAuth.accessToken == null && googleAuth.idToken == null) {
          throw Exception('Both access token and ID token are null');
        }
        
        if (googleAuth.idToken == null) {
          _log('Warning: ID token is null, but access token is present');
          // Continue anyway - sometimes Firebase can work with just access token
        }
        
      } catch (e, stackTrace) {
        _logError('Failed to get Google authentication details', e, stackTrace);
        _showError('Failed to get authentication details from Google. Please try again.');
        return;
      }

      // Step 3: Create Firebase credential
      _log('Creating Firebase credential');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Sign in to Firebase with the credential
      _log('Signing in to Firebase');
      try {
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        _log('Firebase sign-in successful: ${userCredential.user?.email}');
        
        // Check if this is a new user or existing user
        final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        if (isNewUser) {
          _log('New user detected - creating user profile');
          await _createNewUserProfile(userCredential.user!);
        } else {
          _log('Existing user - logging in');
          await _handleExistingUser(userCredential.user!);
        }

      } catch (e, stackTrace) {
        _logError('Firebase sign-in failed', e, stackTrace);
        
        // Provide more specific error messages for common Firebase errors
        String errorMessage = _getFirebaseErrorMessage(e);
        _showError(errorMessage);
        return;
      }

      // Step 5: Navigate to dashboard
      _log('Navigating to dashboard');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }

    } catch (e, stackTrace) {
      _logError('Unexpected error during Google Sign-In process', e, stackTrace);
      _showError('An unexpected error occurred during sign-in. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to create a new user profile in Firestore
  Future<void> _createNewUserProfile(User user) async {
    try {
      _log('Creating new user profile for: ${user.email}');
      
      // Show welcome message for new users
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Welcome to Rating App, ${user.displayName ?? 'User'}!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      _logError('Failed to create user profile', e, stackTrace);
      // Don't throw error here - user is authenticated, just profile creation failed
    }
  }

  // Helper method to handle existing user login
  Future<void> _handleExistingUser(User user) async {
    try {
      _log('Handling existing user: ${user.email}');
      
      // Show welcome back message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Welcome back, ${user.displayName ?? 'User'}!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      _logError('Failed to update existing user data', e, stackTrace);
      // Don't throw error here - user can still proceed
    }
  }

  // Helper method to get user-friendly Firebase error messages
  String _getFirebaseErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      _log('Firebase Auth Exception: ${error.code} - ${error.message}');
      
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in method.';
        case 'invalid-credential':
          return 'The authentication credential is invalid or has expired.';
        case 'operation-not-allowed':
          return 'Google Sign-In is not enabled for this Firebase project.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No user found for this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'invalid-verification-code':
          return 'Invalid verification code.';
        case 'quota-exceeded':
          return 'Quota exceeded. Please try again later.';
        case 'provider-already-linked':
          return 'This provider is already linked to your account.';
        case 'email-already-in-use':
          return 'This email is already registered with a different account.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    
    // Handle Google Sign-In specific errors
    if (error is FirebaseException) {
      return 'Firebase error: ${error.message}';
    }
    
    return 'Sign-in failed. Please try again.';
  }

  // Helper method for logging (use print for development, or your preferred logging solution)
  void _log(String message) {
    debugPrint('🔐 [LoginScreen] $message');
  }

  void _logError(String message, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('❌ [LoginScreen] ERROR: $message');
    debugPrint('   Error: $error');
    if (stackTrace != null) {
      debugPrint('   Stack trace: $stackTrace');
    }
  }

  // Helper method for showing error messages
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon/Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Welcome Text
                  Text(
                    'Welcome to',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rating App',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Share your experience and help us improve',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Google Sign-In Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _signInWithGoogle,
                          icon: Image.network(
                            'https://www.google.com/favicon.ico',
                            height: 20,
                            width: 20,
                            errorBuilder: (context, error, stackTrace) {
                              _logError('Failed to load Google icon', error, stackTrace);
                              return const Icon(Icons.g_mobiledata, size: 24);
                            },
                          ),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.3),
                          ),
                        ),
                  const SizedBox(height: 24),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Powered by Firebase & Google Auth',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}