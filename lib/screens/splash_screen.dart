import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/network_helper.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool isFirstLaunch;
  
  const SplashScreen({
    super.key,
    this.isFirstLaunch = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkSystemStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  Future<void> _checkSystemStatus() async {
    await Future.delayed(const Duration(seconds: 3));
    
    // Check internet connection
    final hasInternet = await NetworkHelper.hasInternetConnection();
    
    if (!hasInternet) {
      _showNoInternetDialog();
      return;
    }

    // Navigate to home
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          settings: RouteSettings(arguments: widget.isFirstLaunch),
        ),
      );
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text(
              'لا يوجد اتصال بالإنترنت',
              style: TextStyle(color: AppTheme.textPrimaryColor),
            ),
          ],
        ),
        content: const Text(
          'يحتاج التطبيق إلى الإنترنت للعمل بشكل صحيح. تأكد من اتصالك وحاول مرة أخرى.',
          style: TextStyle(color: AppTheme.textPrimaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkSystemStatus();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.2),
                            AppTheme.primaryColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ).createShader(bounds),
                      child: const Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.appDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'جاري التحميل...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 