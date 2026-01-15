import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const int _startFrame = 14;
  static const int _endFrame = 110;
  static const int _fps = 28;

  int _currentFrame = _startFrame;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _preloadAndStart();
  }

  Future<void> _preloadAndStart() async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (int i = _startFrame + 1; i <= _endFrame; i++) {
      if (!mounted) return; // Check mounted before each precache
      
      final frameNumber = i.toString().padLeft(5, '0');
      final imagePath = 'assets/animations/splash screen/30/Comp 1_$frameNumber.png';
      await precacheImage(AssetImage(imagePath), context);
    }

    if (mounted) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startAnimation() {
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: (1000 / _fps).round()));

      if (!mounted) return false;

      if (_currentFrame >= _endFrame) {
        widget.onFinished();
        return false;
      }

      setState(() {
        _currentFrame++;
      });

      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final frameNumber = _currentFrame.toString().padLeft(5, '0');
    final imagePath = 'assets/animations/splash screen/30/Comp 1_$frameNumber.png';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
