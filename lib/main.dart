import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/document_reader_screen.dart';
import 'screens/money_reader_screen.dart';
import 'screens/form_analyzer_screen.dart';
import 'screens/signature_detection_test_page.dart';
import 'providers/app_provider.dart';
import 'utils/app_theme.dart';
import 'utils/storage_helper.dart';
import 'utils/font_test.dart'; // إضافة اختبار الخطوط
import 'widgets/connection_monitor.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize storage
    await StorageHelper.init();
    
    // Check if this is the first launch
    bool isFirstLaunch = await StorageHelper.isFirstLaunch() ?? true;
    
    // Set app version for tracking
    await StorageHelper.setAppVersion('1.1.0');
    
    // Set system UI overlay style for dark theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1A1A2E),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    // Force portrait orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    runApp(InsightApp(isFirstLaunch: isFirstLaunch));
  } catch (e) {
    print('Error during app initialization: $e');
    // Fallback to basic app launch
    runApp(const InsightApp(isFirstLaunch: true));
  }
}

class InsightApp extends StatelessWidget {
  final bool isFirstLaunch;
  
  const InsightApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'Insight - المساعد الذكي',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: SplashScreen(isFirstLaunch: isFirstLaunch),
        builder: (context, child) {
          // Add error boundary with detailed error handling
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            // Log error details for debugging
            print('🔥 Flutter Error: ${errorDetails.exception}');
            print('📍 Stack trace: ${errorDetails.stack}');
            
            return Scaffold(
              backgroundColor: const Color(0xFF1A1A2E),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'حدث خطأ في التطبيق',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تفاصيل الخطأ: ${errorDetails.exception.toString()}',
                        style: const TextStyle(
                          color: Color(0xFFB8B8B8),
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Force restart the app
                          SystemNavigator.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('إعادة تشغيل التطبيق'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          };
          
          // Wrap with connection monitor and Directionality
          return ConnectionMonitor(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          );
        },
        routes: {
          '/home': (context) => const HomeScreen(),
          '/document_reader': (context) => const DocumentReaderScreen(),
          '/money_reader': (context) => const MoneyReaderScreen(),
          '/form_analyzer': (context) => const FormAnalyzerScreen(),
          '/font_test': (context) => const FontTestWidget(), // طريق اختبار الخطوط
          '/signature_test': (context) => const SignatureDetectionTestPage(), // طريق اختبار التوقيع
        },
      ),
    );
  }
}
