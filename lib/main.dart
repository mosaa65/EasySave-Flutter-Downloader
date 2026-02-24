import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart'; // لـ kDebugMode
import 'screens/HomeScreen.dart';
import 'services/ad_manager.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. تهيئة خدمة التخزين (تنشئ المجلد والملف وتطلب صلاحيات)
  // 2. تهيئة خدمة الإشعارات (تنشئ القنوات وتطلب صلاحيات)
  //await NotificationService.init();  // تأكد من تهيئة الربط الأساسي لـ Flutter مرة واحدة
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة المكتبات بشكل متوازٍ لتحسين وقت البدء
  await Future.wait([
    FlutterDownloader.initialize(debug: kDebugMode),
    _requestNecessaryPermissions(),
    MobileAds.instance.initialize(),
  ]);

  // تهيئة نظام الإعلانات
  await AdManager().initialize();
  // تمكين الإعدادات التجريبية في وضع التطوير فقط
  if (kDebugMode) {
    _enableTestAdConfig();
  }


  runApp(const MyApp());
}

Future<void> _requestNecessaryPermissions() async {
  // طلب أذونات التخزين الأساسية
  final storageStatus = await Permission.storage.request();

  // طلب إذن إدارة التخزين الخارجي لأندرويد 11+
  if (Platform.isAndroid) {
    final manageStorageStatus = await Permission.manageExternalStorage.request();

    if (!manageStorageStatus.isGranted) {
      print('⚠️ إدارة التخزين الخارجي مطلوبة لبعض الميزات');
    }
  }

  if (!storageStatus.isGranted) {
    print('❌ الإذن ضروري لعمل التطبيق بشكل صحيح');
    // يمكن إضافة منطق إضافي مثل عرض تنبيه للمستخدم
  }
}

void _enableTestAdConfig() {
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: const ["956B7C2B216717B88B61575962152CA1"],
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
    ),
  );
  print('🔧 تم تفعيل وضع اختبار الإعلانات');
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      title: 'EasySave',
      debugShowCheckedModeBanner: false,
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      // بدل home: HomeScreen() خلي initialRoute + routes
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (_) => HomeScreen(),
      },
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Cairo-SemiBold',
      ),    );
  }


  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.red,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.red,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
      ),
    );
  }
}
