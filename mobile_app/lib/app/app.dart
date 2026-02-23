import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../core/theme/app_theme.dart';
import '../core/security/secure_storage_service.dart';
import '../features/auth/data/remote/auth_api.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/app_lock_cubit.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/pages/activate_device_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/app_lock_setup_page.dart';
import '../features/auth/presentation/pages/app_lock_unlock_page.dart';
import '../features/home/presentation/pages/home_shell_page.dart';

class PphPredictionApp extends StatelessWidget {
  const PphPredictionApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Android emulator -> local FastAPI on your computer
    // If using physical phone, replace with your laptop LAN IP (e.g. http://192.168.1.25:8000)
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8000',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Optional: simple request/response logging during development
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint(' ${options.method} ${options.baseUrl}${options.path}');
          debugPrint('Payload: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(' ${response.statusCode} ${response.requestOptions.path}');
          debugPrint('Response: ${response.data}');
          handler.next(response);
        },
        onError: (e, handler) {
          debugPrint(' ${e.requestOptions.method} ${e.requestOptions.path}');
          debugPrint('Error: ${e.message}');
          debugPrint('Response: ${e.response?.data}');
          handler.next(e);
        },
      ),
    );

    final secureStorage = SecureStorageService();
    final authApi = AuthApi(dio);

    final authRepository = AuthRepositoryImpl(
      api: authApi,
      secureStorage: secureStorage,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository)..add(const RestoreSessionRequested()),
        ),
        BlocProvider<AppLockCubit>(
          create: (_) => AppLockCubit(authRepository)..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'Ruvimbo PPH',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: SplashPage.routeName,
        routes: {
          SplashPage.routeName: (_) => const SplashPage(),
          WelcomePage.routeName: (_) => const WelcomePage(),
          ActivateDevicePage.routeName: (_) => const ActivateDevicePage(),
          LoginPage.routeName: (_) => const LoginPage(),
          AppLockSetupPage.routeName: (_) => const AppLockSetupPage(),
          AppLockUnlockPage.routeName: (_) => const AppLockUnlockPage(),
          HomeShellPage.routeName: (_) => const HomeShellPage(),
        },
      ),
    );
  }
}