// lib/app/modules/manajemen_jam/controllers/manajemen_jam_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManajemenJamController extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String idSekolah = '20404148'; // Pastikan ID benar

  // [MODIFIKASI] Controller untuk dialog
  final TextEditingController namaC = TextEditingController();
  // [BARU] State untuk menampung waktu yang dipilih dari TimePicker
  final Rx<TimeOfDay?> jamMulai = Rxn<TimeOfDay>();
  final Rx<TimeOfDay?> jamSelesai = Rxn<TimeOfDay>();
  
  // [DIHAPUS] Kita tidak lagi butuh controller untuk waktu dan urutan
  Stream<QuerySnapshot<Map<String, dynamic>>> streamJamPelajaran() {
    return firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('jampelajaran')
        .orderBy('urutan')
        .snapshots();
  }

  Future<void> _reorderAllJamPelajaran() async {
  try {
    // 1. Baca semua dokumen
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('jampelajaran').get();
        
    if (snapshot.docs.isEmpty) return; // Tidak ada yang perlu diurutkan

    // 2. Urutkan berdasarkan waktu mulai
    var docs = snapshot.docs;
    docs.sort((a, b) {
      final timeA = a.data()['jamMulai'] as String;
      final timeB = b.data()['jamMulai'] as String;
      return timeA.compareTo(timeB);
    });

    // 3. Siapkan batch untuk menulis ulang urutan
    final batch = firestore.batch();
    for (int i = 0; i < docs.length; i++) {
      final docRef = docs[i].reference;
      // Update field 'urutan' dengan nomor urut yang benar (dimulai dari 1)
      batch.update(docRef, {'urutan': i + 1});
    }

    // 4. Commit semua perubahan
    await batch.commit();

  } catch (e) {
    // Tampilkan error di konsol, tidak perlu mengganggu user dengan snackbar
    print("Error saat re-ordering jam pelajaran: $e");
  }
}

  // [BARU] Fungsi untuk memunculkan TimePicker
  Future<void> pilihWaktu(BuildContext context, String jenisWaktu) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (jenisWaktu == 'mulai') {
        jamMulai.value = picked;
      } else {
        jamSelesai.value = picked;
      }
    }
  }

  // [DIROMBAK TOTAL] Fungsi simpan dengan validasi dan urutan otomatis
      Future<void> simpanJam({String? docId}) async {
      // 1. Validasi (Tidak ada perubahan)
      if (namaC.text.isEmpty || jamMulai.value == null || jamSelesai.value == null) {
        Get.snackbar("Gagal", "Nama kegiatan dan waktu wajib diisi.");
        return;
      }
      final mulaiInMinutes = jamMulai.value!.hour * 60 + jamMulai.value!.minute;
      final selesaiInMinutes = jamSelesai.value!.hour * 60 + jamSelesai.value!.minute;
      if (selesaiInMinutes <= mulaiInMinutes) {
        Get.snackbar("Error Logika", "Jam Selesai harus setelah Jam Mulai.");
        return;
      }
      
      // Format waktu (Tidak ada perubahan)
      final formatWaktu = (TimeOfDay time) => "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      final String jamMulaiStr = formatWaktu(jamMulai.value!);
      final String jamSelesaiStr = formatWaktu(jamSelesai.value!);
    
      try {
        // [PERBAIKAN] Hapus semua logika 'urutan' manual dari sini.
        final dataToSave = {
          'namaKegiatan': namaC.text,
          'jamMulai': jamMulaiStr,
          'jamSelesai': jamSelesaiStr,
          'jampelajaran': '$jamMulaiStr-$jamSelesaiStr',
        };
    
        // [PERBAIKAN] Lakukan operasi simpan atau update terlebih dahulu.
        if (docId == null) {
          await firestore.collection('Sekolah').doc(idSekolah).collection('jampelajaran').add(dataToSave);
        } else {
          await firestore.collection('Sekolah').doc(idSekolah).collection('jampelajaran').doc(docId).update(dataToSave);
        }
        
        // [PERBAIKAN] Panggil fungsi re-order SETELAH operasi database selesai, di luar if/else.
        // Ini memastikan fungsi ini berjalan baik untuk 'tambah' maupun 'update'.
        await _reorderAllJamPelajaran();
    
        // [PERBAIKAN] Panggil Get.back() dan snackbar hanya sekali di akhir.
        Get.back();
        Get.snackbar("Berhasil", docId == null ? "Jam pelajaran baru telah ditambahkan." : "Jam pelajaran telah diperbarui.");
    
      } catch (e) {
        Get.snackbar("Error", "Gagal menyimpan data: $e");
      }
    }

  Future<void> hapusJam(String docId) async {
    // Logika hapus tidak perlu diubah, tapi perlu memastikan urutan di-update jika perlu (fitur masa depan)
    try {
      await firestore.collection('Sekolah').doc(idSekolah).collection('jampelajaran').doc(docId).delete();

      // [PENTING] Panggil fungsi re-order SETELAH data dihapus
      await _reorderAllJamPelajaran();

      Get.back();
      Get.snackbar("Berhasil", "Jam pelajaran telah dihapus.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus data: $e");
    }
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class ManajemenJamController extends GetxController {
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final String idSekolah = '20404148'; // Ganti jika perlu

//   // Controller untuk dialog tambah/edit
//   final TextEditingController namaC = TextEditingController();
//   final TextEditingController mulaiC = TextEditingController();
//   final TextEditingController selesaiC = TextEditingController();
//   final TextEditingController urutanC = TextEditingController();

//   // Stream untuk menampilkan daftar jam pelajaran secara real-time
//   Stream<QuerySnapshot<Map<String, dynamic>>> streamJamPelajaran() {
//     return firestore
//         .collection('Sekolah').doc(idSekolah)
//         .collection('jampelajaran')
//         .orderBy('urutan') // Diurutkan berdasarkan nomor urut
//         .snapshots();
//   }

//   // Fungsi untuk menyimpan (baik tambah baru maupun update)
//   Future<void> simpanJam({String? docId}) async {
//     if (namaC.text.isEmpty || mulaiC.text.isEmpty || selesaiC.text.isEmpty || urutanC.text.isEmpty) {
//       Get.snackbar("Gagal", "Semua field wajib diisi.");
//       return;
//     }

//     final data = {
//       'namaKegiatan': namaC.text,
//       'jamMulai': mulaiC.text,
//       'jamSelesai': selesaiC.text,
//       'urutan': int.tryParse(urutanC.text) ?? 99,
//       // Gabungkan jamMulai dan jamSelesai untuk field lama 'jampelajaran'
//       'jampelajaran': '${mulaiC.text}-${selesaiC.text}',
//     };

//     try {
//       if (docId == null) {
//         // Jika tambah baru
//         await firestore.collection('Sekolah').doc(idSekolah).collection('jampelajaran').add(data);
//         Get.snackbar("Berhasil", "Jam pelajaran baru telah ditambahkan.");
//       } else {
//         // Jika update
//         await firestore.collection('Sekolah').doc(idSekolah).collection('jampelajaran').doc(docId).update(data);
//         Get.snackbar("Berhasil", "Jam pelajaran telah diperbarui.");
//       }
//       Get.back(); // Tutup dialog
//     } catch (e) {
//       Get.snackbar("Error", "Gagal menyimpan data: $e");
//     }
//   }

//   // Fungsi untuk menghapus jam pelajaran
//   Future<void> hapusJam(String docId) async {
//     try {
//       await firestore.collection('Sekolah').doc(idSekolah).collection('jampelajaran').doc(docId).delete();
//       Get.back(); // Tutup dialog konfirmasi
//       Get.snackbar("Berhasil", "Jam pelajaran telah dihapus.");
//     } catch (e) {
//       Get.snackbar("Error", "Gagal menghapus data: $e");
//     }
//   }
// }