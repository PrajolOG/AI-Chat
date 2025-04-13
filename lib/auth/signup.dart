import 'package:firebase_auth/firebase_auth.dart';

Future<User?> registerUser(String email, String password, String displayName) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    User? user = userCredential.user;

    if (user != null) {
      // Optionally update the display name
      await user.updateDisplayName(displayName);
      // Optionally send a verification email
      await user.sendEmailVerification(); // Consider enabling email verification in Firebase Console
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
    }
    return user;
  } on FirebaseAuthException catch (e) {
    print("Error: ${e.message}");
    return null;
  }
}