import 'package:flutter/material.dart';
import 'package:cha9cha9ni/features/auth/screens/signin_screen.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          image: DecorationImage(
            image: AssetImage('assets/images/Element.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Spacer to center content
                SizedBox(height: screenHeight * 0.15),
                
                // Success image
                Image.asset(
                  'assets/images/success.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                
                const SizedBox(height: 40),
                
                // Title
                const Text(
                  'Reset Password Success!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF13123A),
                    fontSize: 24,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w700,
                    height: 1.50,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                const Text(
                  'Please login again\nwith your new password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666680),
                    fontSize: 16,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Go to Sign In button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const SignInScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEE3764),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Go to Sign In',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Nunito Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
