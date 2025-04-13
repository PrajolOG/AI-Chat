// settings.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart'; // Assuming this leads to your login/signup screen
import '../auth/logout.dart'; // Assuming this contains your signOutUser function
import 'html_viewer.dart'; // +++ Import the WebView viewer screen +++

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showAccountDetails = false;
  bool _showHtmlCompilerView = false; // State for HTML Compiler view
  late TextEditingController _htmlController; // Controller for the HTML text field

  @override
  void initState() {
    super.initState();
    _showAccountDetails = false;
    _showHtmlCompilerView = false;
    _htmlController = TextEditingController(); // Initialize controller
  }

  @override
  void dispose() {
    _htmlController.dispose(); // Dispose controller when state is disposed
    super.dispose();
  }

  // --- Logout Logic (Added mounted checks) ---
  Future<void> _logout(BuildContext context) async {
    try {
      await signOutUser();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: ${e.toString()}')));
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _buildCustomDialogContent(context),
        );
      },
    );
    if (mounted && confirm == true) {
      await _logout(context);
    }
  }

  Widget _buildCustomDialogContent(BuildContext context) {
    // --- Custom Dialog Content (Unchanged) ---
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.logout_rounded,
            color: Colors.redAccent.shade400,
            size: 50,
          ),
          const SizedBox(height: 24),
          Text(
            "Confirm Logout?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade200,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Are you sure you want to end your current session?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF282828),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade400,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Account Details View (Added mounted check for SnackBar) ---
  Widget _buildAccountDetailsView() {
    final user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? 'N/A';
    final String userEmail = user?.email ?? 'N/A';

    return Padding(
      key: const ValueKey('accountDetailsView'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _showAccountDetails = false;
                    });
                  },
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(width: 16),
                Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF232323),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.person_rounded, color: Colors.grey.shade400, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Username', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(userName, style: TextStyle(color: Colors.grey.shade200, fontSize: 17, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_rounded, color: Colors.grey.shade500),
                  onPressed: () {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Editing username is not yet implemented')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF232323),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.email_rounded, color: Colors.grey.shade400, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email Address', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(userEmail, style: TextStyle(color: Colors.grey.shade200, fontSize: 17, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Icon(Icons.email_outlined, color: Colors.grey.shade500),
              ],
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () => _confirmLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 6,
              ),
              child: const Text(
                'Logout Account',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // +++ HTML Compiler View (Navigates to HtmlViewerScreen) +++
  Widget _buildHtmlCompilerView() {
    return Padding(
      key: const ValueKey('htmlCompilerView'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _showHtmlCompilerView = false; // Go back to main settings
                    });
                  },
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(width: 16),
                Text(
                  'HTML Compiler',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),

          // --- Code Input Area ---
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF232323), // Background for text area
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _htmlController,
                maxLines: null, // Allows unlimited lines
                expands: true, // Fills the available vertical space
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  color: Colors.grey.shade200,
                  fontSize: 15,
                  fontFamily: 'monospace', // Good font for code
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste or write your HTML code here...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  border: InputBorder.none, // Remove default border
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Run Button (Navigates to HtmlViewerScreen) ---
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.black, // Icon color on white button
                size: 24,
              ),
              label: const Text(
                'Run Code',
                style: TextStyle(
                  color: Colors.black, // Text color on white button
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                final code = _htmlController.text;
                if (code.trim().isEmpty) {
                   if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(
                           content: Text('Please enter some HTML code first.'),
                           backgroundColor: Colors.orangeAccent, // Warning color
                         ),
                       );
                   }
                  return; // Don't navigate if there's no code
                }

                // --- Navigate to the HtmlViewerScreen (WebView version) ---
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HtmlViewerScreen(htmlContent: code),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // White button background
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 6,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- Main Settings List View (Added mounted checks for SnackBars) ---
  Widget _buildMainSettingsView() {
    return ListView(
      key: const ValueKey('mainSettingsView'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        SettingsTile(
          icon: Icons.person_outline_rounded,
          title: 'Account',
          subtitle: 'Manage your account details',
          onTap: () {
            setState(() {
              _showAccountDetails = true;
              _showHtmlCompilerView = false;
            });
          },
        ),
        const SizedBox(height: 12),
        SettingsTile(
          icon: Icons.code_rounded, // HTML icon
          title: 'HTML Compiler',
          subtitle: 'Write and preview HTML code (with JS)', // Updated subtitle
          onTap: () {
            setState(() {
              _showHtmlCompilerView = true;
              _showAccountDetails = false;
            });
          },
        ),
        const SizedBox(height: 12),
        SettingsTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Customize app notifications',
          onTap: () {
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications settings are not yet implemented')),
                );
             }
          },
        ),
        const SizedBox(height: 12),
        SettingsTile(
          icon: Icons.security_rounded,
          title: 'Privacy & Security',
          subtitle: 'Control privacy settings and security',
          onTap: () {
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy & Security settings are not yet implemented')),
                );
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSubViewActive = _showAccountDetails || _showHtmlCompilerView;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isSubViewActive
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                onPressed: () {
                   if (mounted) Navigator.pop(context);
                } ,
              ),
        automaticallyImplyLeading: !isSubViewActive,
        title: Text(
          "Settings",
          style: TextStyle(
            color: Colors.grey.shade100,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final bool isMainSettings = child.key == const ValueKey('mainSettingsView');
          final slideAnimation = Tween<Offset>(
            begin: isMainSettings ? const Offset(-0.3, 0.0) : const Offset(0.3, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
        child: _showAccountDetails
            ? _buildAccountDetailsView()
            : _showHtmlCompilerView
                ? _buildHtmlCompilerView()
                : _buildMainSettingsView(),
      ),
    );
  }
}

// --- Reusable Settings Tile Widget (Unchanged) ---
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}