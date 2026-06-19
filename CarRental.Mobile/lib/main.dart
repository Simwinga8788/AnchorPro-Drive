import 'package:flutter/material.dart';
import 'theme.dart';
import 'router.dart';

void main() {
  runApp(const RetrixCarRentalApp());
}

class RetrixCarRentalApp extends StatelessWidget {
  const RetrixCarRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Retrix Car Rental',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: appRouter,
    );
  }
}
