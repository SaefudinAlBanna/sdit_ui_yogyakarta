// lib/app/interfaces/input_nilai_massal_interface.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/siswa_halaqoh.dart';

// [BARU] Ini adalah kontrak kita.
abstract class IInputNilaiMassalController {
  // State yang dibutuhkan UI
  RxBool get isSavingNilai;
  RxList<SiswaHalaqoh> get daftarSiswa;
  RxList<String> get santriTerpilihUntukNilai;
  Map<String, TextEditingController> get nilaiMassalControllers;
  
  // Controller untuk template
  TextEditingController get suratC;
  TextEditingController get ayatHafalC;
  TextEditingController get capaianC;
  TextEditingController get materiC;
  RxString get keteranganHalaqoh;

  // Fungsi yang akan dipanggil dari UI
  void toggleSantriSelection(String nisn);
  Future<void> simpanNilaiMassal();
  void clearNilaiForm();
}