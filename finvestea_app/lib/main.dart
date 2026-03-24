import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/services/auth_service.dart';

// Notifies GoRouter whenever local auth state changes so the redirect
// function re-runs without recreating the whole router.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    AuthService().authStateChanges.listen((_) => notifyListeners());
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinvesteaApp());
}

class FinvesteaApp extends StatefulWidget {
  const FinvesteaApp({super.key});

  @override
  State<FinvesteaApp> createState() => _FinvesteaAppState();
}

class _FinvesteaAppState extends State<FinvesteaApp> {
  late final _AuthNotifier _authNotifier;
  late final GoRouter appRouter;

  @override
  void initState() {
    super.initState();
    _authNotifier = _AuthNotifier();
    appRouter = createRouter(_authNotifier);
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Finvestea',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
