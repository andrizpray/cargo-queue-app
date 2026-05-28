import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/queue_provider.dart';
import 'providers/vehicle_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const CargoQueueApp());
}

class CargoQueueApp extends StatelessWidget {
  const CargoQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService(baseUrl: AppConstants.apiBaseUrl);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => QueueProvider(apiService)),
        ChangeNotifierProvider(create: (_) => VehicleProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'Cargo Queue',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        home: const AuthInitializer(),
      ),
    );
  }
}

/// Widget that initializes auth state before showing the app
class AuthInitializer extends StatefulWidget {
  const AuthInitializer({super.key});

  @override
  State<AuthInitializer> createState() => _AuthInitializerState();
}

class _AuthInitializerState extends State<AuthInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.init();
    
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_shipping,
                size: 100,
                color: Color(0xFF1565C0),
              ),
              SizedBox(height: 24),
              Text(
                'Cargo Queue',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return const SplashScreen();
  }
}
