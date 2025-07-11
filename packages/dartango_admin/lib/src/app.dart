import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/users/users_screen.dart';
import 'screens/groups/groups_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'utils/storage_utils.dart';

class DartangoAdminApp extends StatelessWidget {
  const DartangoAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
              authService: AuthService(
            client: http.Client(),
            storage: StorageUtils(),
          )),
        ),
      ],
      child: MaterialApp(
        title: 'Dartango Admin',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/users':
              return MaterialPageRoute(
                builder: (context) => const UsersScreen(),
              );
            case '/groups':
              return MaterialPageRoute(
                builder: (context) => const GroupsScreen(),
              );
            case '/permissions':
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(
                    child: Text('Permissions Management - Coming Soon'),
                  ),
                ),
              );
            case '/models':
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(
                    child: Text('Models Management - Coming Soon'),
                  ),
                ),
              );
            case '/analytics':
              return MaterialPageRoute(
                builder: (context) => const AnalyticsScreen(),
              );
            case '/logs':
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(
                    child: Text('Logs - Coming Soon'),
                  ),
                ),
              );
            case '/settings':
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(
                    child: Text('Settings - Coming Soon'),
                  ),
                ),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}
