import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';  // Your signInUser function
import '../auth/signup.dart'; // Your registerUser function
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Toggle between login and signup
  bool _isLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // Password visibility toggles for each form
  bool _isLoginPasswordVisible = false;
  bool _isSignupPasswordVisible = false;

  // Controllers for login form
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Controllers for signup form (using Username instead of Display Name)
  final TextEditingController _signupUsernameController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();

  bool _isInternetConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isRetryButtonLoading = false;

  @override
  void initState() {
    super.initState();
    _startConnectivityListener();
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupUsernameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      ConnectivityResult result =
          results.isNotEmpty ? results.last : ConnectivityResult.none;
      _handleConnectivityChange(result);
    });
  }

  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      if (_isInternetConnected) {
        setState(() {
          _isInternetConnected = false;
        });
        _showNoInternetDialog(context);
      }
    } else {
      if (!_isInternetConnected) {
        setState(() {
          _isInternetConnected = true;
          _isRetryButtonLoading = false;
        });
        Navigator.of(context).pop();
      }
    }
  }

  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                backgroundColor: const Color.fromARGB(255, 30, 30, 30),
                title: const Text(
                  'No Internet Connection',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  'Internet connection is required to connect to Exy ai. Please check your internet settings and try again.',
                  style: TextStyle(color: Colors.grey[300]),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setStateDialog(() {
                        _isRetryButtonLoading = true;
                      });
                      Future.delayed(const Duration(seconds: 6), () {
                        setStateDialog(() {
                          _isRetryButtonLoading = false;
                        });

                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 10),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(scale: animation, child: child),
                        );
                      },
                      child: _isRetryButtonLoading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.fromARGB(255, 0, 0, 0)),
                                strokeWidth: 1.5,
                              ),
                            )
                          : const Text(
                              'Retry',
                              key: ValueKey('retryText'),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }




  // Custom gradient button widget with updated gradients.
  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Changed background color to white
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.black), // Changed indicator color to black for visibility
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Changed text color to black
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Login operation.
  Future<void> _login() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    User? user = await signInUser(
      _loginEmailController.text.trim(),
      _loginPasswordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = 'Login failed. Please check your email and password.';
      });
    }
  }

  // Signup operation.
  Future<void> _signup() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    User? user = await registerUser(
      _signupEmailController.text.trim(),
      _signupPasswordController.text.trim(),
      _signupUsernameController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful! Please log in.')),
      );
      setState(() {
        _isLogin = true;
      });
    } else {
      setState(() {
        _errorMessage = 'Signup failed. Please check your details.';
      });
    }
  }

  // Builds the login form card.
  Widget _buildLoginForm() {
    return Container(
      key: const ValueKey('loginForm'),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 24, 24, 24),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 122, 122, 122).withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header text.
          const Text(
            'Welcome Back!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color.fromARGB(255, 181, 181, 181), width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _loginPasswordController,
            obscureText: !_isLoginPasswordVisible,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: const TextStyle(color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color.fromARGB(255, 181, 181, 181), width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isLoginPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isLoginPasswordVisible = !_isLoginPasswordVisible;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildGradientButton(
            text: 'Log In',
            onPressed: _isLoading ? () {} : _login,
            isLoading: _isLoading,
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  // Builds the signup form card.
  Widget _buildSignupForm() {
    return Container(
      key: const ValueKey('signupForm'),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 19, 19, 19),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 105, 105, 105).withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header text.
          const Text(
            'Create Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _signupUsernameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: const TextStyle(color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color.fromARGB(255, 181, 181, 181), width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signupEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color.fromARGB(255, 181, 181, 181), width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signupPasswordController,
            obscureText: !_isSignupPasswordVisible,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: const TextStyle(color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color.fromARGB(255, 181, 181, 181), width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isSignupPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isSignupPasswordVisible = !_isSignupPasswordVisible;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildGradientButton(
            text: 'Sign Up',
            onPressed: _isLoading ? () {} : _signup,
            isLoading: _isLoading,
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Full-screen immersive design without an app bar.
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              // Updated dark gradient background.
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 0, 0, 0), Color.fromARGB(255, 0, 0, 0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main Title
                    const Text(
                      "EXY AI",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Animated switch between login and signup form.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        // Smooth slide transition with easeInOut curve.
                        final slideAnimation = Tween<Offset>(
                          begin: const Offset(1.0, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        ));
                        return SlideTransition(
                          position: slideAnimation,
                          child: child,
                        );
                      },
                      child: _isLogin ? _buildLoginForm() : _buildSignupForm(),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = '';
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? "Don't have an account? Sign up"
                            : "Already have an account? Log in",
                        style: const TextStyle(
                          color: Color.fromARGB(255, 198, 198, 198),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],

                ),
              ),
            ),
          ),
          if (!_isInternetConnected)
            Container(
              color: Colors.transparent,
              child: Center(
                child: Container(),
              ),
            ),
        ],
      ),
    );
  }
}