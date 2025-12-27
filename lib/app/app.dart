import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../auth/auth_service.dart';
import '../data/repositories/family_repository.dart';

class GentleLightsApp extends StatelessWidget {
  const GentleLightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FamilyRepository>(create: (_) => FamilyRepository()),
      ],
      child: MaterialApp.router(
        title: 'Gentle Lights',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}



