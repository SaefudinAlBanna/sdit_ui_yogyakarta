// lib/app/modules/absensi/views/absensi_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/absensi_controller.dart';

class AbsensiPage extends StatelessWidget {
  const AbsensiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller
    final AbsensiController controller = Get.put(AbsensiController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Kehadiran'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Memuat data absensi..."),
                ],
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  controller.hasAttendedToday.value
                      ? Icons.check_circle
                      : (controller.isWithinRadius.value ? Icons.location_on : Icons.location_off),
                  size: 100,
                  color: controller.hasAttendedToday.value
                      ? Colors.green
                      : (controller.isWithinRadius.value ? Colors.blue : Colors.red),
                ),
                const SizedBox(height: 24),
                Text(
                  controller.attendanceMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  icon: const Icon(Icons.touch_app),
                  label: Text(
                    controller.hasAttendedToday.value ? 'SUDAH ABSEN' : 'ABSEN MASUK SEKARANG',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Tombol hanya aktif jika pengguna belum absen DAN berada dalam radius
                  onPressed: (controller.isWithinRadius.value && !controller.hasAttendedToday.value)
                      ? controller.markAttendance
                      : null,
                ),
                const SizedBox(height: 20),
                // Tombol refresh untuk mencoba lagi jika ada error
                if(!controller.hasAttendedToday.value)
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Cek Ulang Lokasi"),
                    onPressed: controller.checkUserLocationAndAttendance,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}