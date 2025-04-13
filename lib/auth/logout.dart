// auth/logout.dart
import 'package:firebase_auth/firebase_auth.dart';

Future<void> signOutUser() async {
  try {
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    print("Error during logout: $e");
    // Optionally handle errors more explicitly or rethrow to be caught in the UI layer.
    rethrow;
  }
}
