import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/constants.dart';
import 'services/api_service.dart';
import 'providers/queue_provider.dart';
import 'providers/vehicle_provider.dart';
import 'screens/home_screen.dart';

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
          cardTheme: CardTheme(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
