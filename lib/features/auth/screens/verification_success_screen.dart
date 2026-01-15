import 'package:cha9cha9ni/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../features/home/home_screen.dart';

class VerificationSuccessScreen extends StatelessWidget {
  const VerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Image.asset(
                    'assets/images/success.png',
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Title
                Text(
                  l10n.verificationSuccess,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF13123A),
                    fontSize: 24,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w700,
                    height: 1.50,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  l10n.verificationSuccessSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF666680),
                    fontSize: 16,
                    fontFamily: 'Nunito Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
                
                const Spacer(),
                
                // Okay button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CC3C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.okay,
                      style: const TextStyle(
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
