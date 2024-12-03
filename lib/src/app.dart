import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:teacher_app/src/auth/login_view.dart';
import 'package:teacher_app/src/beacon/beacon_view.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFF182026),
        useMaterial3: true,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => const LoginView(),
        ),
        GetPage(
          name: '/beacon',
          page: () => const BeaconView(),
        ),
      ],
    );
  }
}
