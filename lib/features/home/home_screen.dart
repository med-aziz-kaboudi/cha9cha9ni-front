import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../main.dart' show PendingVerificationHelper;
import '../auth/screens/signin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = 'Loading...';
  final _tokenStorage = TokenStorageService();

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final name = await _tokenStorage.getUserDisplayName();
    if (mounted) {
      setState(() {
        _displayName = name;
      });
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      // Clear backend tokens and user profile
      await _tokenStorage.clearTokens();
      
      // Clear any pending verification
      await PendingVerificationHelper.clear();
      
      // Sign out from Supabase (if there's a session)
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await Supabase.instance.client.auth.signOut();
      }
      
      // Navigate to sign in screen and clear all routes
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.gray,
          image: DecorationImage(
            image: AssetImage('assets/images/Element.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/icons/horisental.png',
                  width: MediaQuery.of(context).size.width * 0.60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 60),
                
                // Welcome text
                Text(
                  'Welcome!',
                  style: AppTextStyles.heading1.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // User name
                Text(
                  _displayName,
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 18,
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                
                // Sign out button
                GestureDetector(
                  onTap: () => _handleSignOut(context),
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: ShapeDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Sign Out',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
