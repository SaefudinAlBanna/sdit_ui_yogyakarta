// import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'app/controller/storage_controller.dart';
import 'app/routes/app_pages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/services/halaqoh_service.dart';

// Import intl untuk formatting tanggal
import 'package:intl/date_symbol_data_local.dart';

// Import Supabase dengan prefix 'as supabase' untuk menghindari konflik nama 'User'
import 'package:supabase_flutter/supabase_flutter.dart' as supabase; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

   await dotenv.load(fileName: ".env");
  
  // Inisialisasi Firebase (tidak berubah)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi Supabase dengan prefix (tidak berubah)
  await supabase.Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, 
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!, 
  );
  
  await GetStorage.init();

    // --- DAFTARKAN STORAGE CONTROLLER DI SINI ---
  Get.put(StorageController(), permanent: true);

  Get.put(HalaqohService());

  // ==========================================================
  // --- TAMBAHKAN KODE INISIALISASI TANGGAL DI SINI ---
  await initializeDateFormatting('id_ID', null);
  // ==========================================================
  
  runApp(
    StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        // print('snapshot.data = ${snapshot.data}');
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: "SDIT UI",
          initialRoute: snapshot.data != null ? Routes.HOME : Routes.LOGIN,
          // initialRoute: Routes.KELOMPOK_HALAQOH,
          getPages: AppPages.routes,
        );
      }
    ),
  );
}