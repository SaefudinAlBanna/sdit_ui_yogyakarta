// views/input_info_sekolah_view.dart

import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/input_info_sekolah_controller.dart';

class InputInfoSekolahView extends GetView<InputInfoSekolahController> {
  const InputInfoSekolahView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Informasi Baru'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- Input Judul ---
            TextField(
              controller: controller.judulC,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              decoration: const InputDecoration(
                hintText: 'Judul Informasi...',
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            
            // --- Area Upload Gambar ---
            const SizedBox(height: 20),
            Obx(() {
              if (controller.imageFile.value == null) {
                return GestureDetector(
                    onTap: controller.pickImage,
                    child: DottedBorder(
                      // --- PERUBAHAN UTAMA DIMULAI DI SINI ---

                      // 1. Semua pengaturan sekarang masuk ke dalam parameter 'options'
                      // Karena Anda butuh border berbentuk Rounded Rectangle, kita pakai RoundedRectDottedBorderOptions
                      options: RoundedRectDottedBorderOptions(
                        // 2. Properti-properti lama dipindahkan ke dalam 'options'
                        radius: const Radius.circular(12),
                        dashPattern: const [8, 4],
                        strokeWidth: 2,
                        color: Colors.grey,
                      ),

                      // --- AKHIR DARI PERUBAHAN ---

                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tambahkan Gambar (Opsional)', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  );
              } else {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        controller.imageFile.value!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: controller.removeImage,
                        ),
                      ),
                    ),
                  ],
                );
              }
            }),
            
            // --- Input Isi Informasi ---
            const SizedBox(height: 20),
            TextField(
              controller: controller.inputC,
              maxLines: null, // Otomatis menyesuaikan tinggi
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 16, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Tuliskan informasi selengkapnya di sini...',
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
      // Tombol Post
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.simpanInfo,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Publikasikan', style: TextStyle(fontSize: 16)),
            )),
      ),
    );
  }
}