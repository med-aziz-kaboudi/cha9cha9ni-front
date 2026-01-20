import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Tutorial step data
class TutorialStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;
  final TutorialPosition position;

  TutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.icon = Icons.touch_app_rounded,
    this.position = TutorialPosition.bottom,
  });
}

enum TutorialPosition { top, bottom, left, right }

/// Tutorial overlay widget that guides users through the app
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  });

  /// Check if tutorial has been completed
  static Future<bool> hasCompletedTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_completed') ?? false;
  }

  /// Mark tutorial as completed
  static Future<void> markTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
  }

  /// Reset tutorial (for testing)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', false);
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTargetRect();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateTargetRect() {
    if (_currentStep >= widget.steps.length) return;

    final step = widget.steps[_currentStep];
    final RenderBox? renderBox =
        step.targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _targetRect = Rect.fromLTWH(
          position.dx,
          position.dy,
          renderBox.size.width,
          renderBox.size.height,
        );
      });
    }
  }

  void _nextStep() async {
    HapticFeedback.lightImpact();
    await _animationController.reverse();

    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _updateTargetRect();
      _animationController.forward();
    } else {
      await TutorialOverlay.markTutorialCompleted();
      widget.onComplete();
    }
  }

  void _previousStep() async {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      await _animationController.reverse();
      setState(() {
        _currentStep--;
      });
      _updateTargetRect();
      _animationController.forward();
    }
  }

  void _skip() async {
    HapticFeedback.mediumImpact();
    await TutorialOverlay.markTutorialCompleted();
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_currentStep];
    final l10n = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Dark overlay with hole for target
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomPaint(
                  painter: _OverlayPainter(
                    targetRect: _targetRect,
                    overlayColor: Colors.black.withOpacity(0.8),
                  ),
                ),
              ),
            ),

            // Highlight ring around target
            if (_targetRect != null)
              Positioned(
                left: _targetRect!.left - 8,
                top: _targetRect!.top - 8,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: _targetRect!.width + 16,
                    height: _targetRect!.height + 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.secondary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Tooltip card
            _buildTooltipCard(step, screenSize, l10n),

            // Skip button (top right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _skip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.skipTutorial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Step indicator
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 100,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.steps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: index == _currentStep ? 28 : 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == _currentStep
                            ? AppColors.secondary
                            : index < _currentStep
                                ? AppColors.secondary.withOpacity(0.6)
                                : Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTooltipCard(
    TutorialStep step,
    Size screenSize,
    AppLocalizations l10n,
  ) {
    // Calculate tooltip position based on target rect
    double? top, bottom, left, right;

    if (_targetRect != null) {
      final targetCenter = _targetRect!.center;

      // Determine if tooltip should be above or below target
      if (targetCenter.dy < screenSize.height / 2) {
        // Target is in upper half, show tooltip below
        top = _targetRect!.bottom + 24;
      } else {
        // Target is in lower half, show tooltip above
        bottom = screenSize.height - _targetRect!.top + 24;
      }

      // Center horizontally with some margin
      left = 20;
      right = 20;
    } else {
      // Default center position
      top = screenSize.height / 2 - 80;
      left = 20;
      right = 20;
    }

    final isLastStep = _currentStep == widget.steps.length - 1;

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with icon
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              step.icon,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              step.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Description
                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Navigation buttons
                      Row(
                        children: [
                          // Back button (if not first step)
                          if (_currentStep > 0) ...[
                            GestureDetector(
                              onTap: _previousStep,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          // Step counter
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentStep + 1} / ${widget.steps.length}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Next/Done button
                          GestureDetector(
                            onTap: _nextStep,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isLastStep
                                        ? l10n.doneTutorial
                                        : l10n.nextTutorial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isLastStep
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// Custom painter to draw overlay with a hole for the target
class _OverlayPainter extends CustomPainter {
  final Rect? targetRect;
  final Color overlayColor;

  _OverlayPainter({
    this.targetRect,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    // Draw full overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Cut out hole for target
    if (targetRect != null) {
      final holePath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            targetRect!.inflate(8),
            const Radius.circular(12),
          ),
        );

      final combinedPath = Path.combine(
        PathOperation.difference,
        overlayPath,
        holePath,
      );

      canvas.drawPath(combinedPath, paint);
    } else {
      canvas.drawPath(overlayPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
