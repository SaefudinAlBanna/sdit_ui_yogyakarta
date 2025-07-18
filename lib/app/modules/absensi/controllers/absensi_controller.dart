// lib/app/modules/absensi/controllers/absensi_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class AbsensiController extends GetxController {
  // Observables untuk State Management UI
  final RxBool isLoading = true.obs;
  final RxString attendanceMessage = "Menentukan lokasi Anda...".obs;
  final RxBool isWithinRadius = false.obs;
  final RxBool hasAttendedToday = false.obs;

  // Dependensi Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String idSekolah = "20404148"; // Sesuaikan dengan ID sekolah Anda

  @override
  void onInit() {
    super.onInit();
    checkUserLocationAndAttendance();
  }

  /// Fungsi utama untuk memeriksa lokasi dan status absensi
  Future<void> checkUserLocationAndAttendance() async {
    isLoading.value = true;
    
    final String todayDocId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String uid = _auth.currentUser!.uid;

    // 1. Cek apakah sudah absen hari ini
    final attendanceDoc = await _firestore.collection('Sekolah').doc(idSekolah)
        .collection('absensi').doc(todayDocId)
        .collection('pegawai').doc(uid).get();

    if (attendanceDoc.exists) {
      hasAttendedToday.value = true;
      attendanceMessage.value = "Anda sudah berhasil absen hari ini.";
      isWithinRadius.value = false; // Nonaktifkan tombol
      isLoading.value = false;
      return;
    }

    // 2. Jika belum absen, lanjutkan cek lokasi
    hasAttendedToday.value = false;
    try {
      // Ambil konfigurasi sekolah (lokasi & radius)
      final schoolConfigDoc = await _firestore.collection('Sekolah').doc(idSekolah).get();
      final schoolData = schoolConfigDoc.data();
      if (schoolData == null || schoolData['lokasiSekolah'] == null || schoolData['radiusAbsen'] == null) {
        throw Exception("Konfigurasi lokasi sekolah tidak ditemukan.");
      }
      final GeoPoint schoolLocation = schoolData['lokasiSekolah'];
      final double schoolRadius = (schoolData['radiusAbsen'] as num).toDouble();

      // Dapatkan posisi pengguna saat ini
      Position userPosition = await _determinePosition();
      
      // Hitung jarak
      double distanceInMeters = Geolocator.distanceBetween(
        schoolLocation.latitude,
        schoolLocation.longitude,
        userPosition.latitude,
        userPosition.longitude,
      );
      
      // Update state berdasarkan jarak
      if (distanceInMeters <= schoolRadius) {
        isWithinRadius.value = true;
        attendanceMessage.value = "Anda berada dalam area sekolah. Silakan tekan tombol untuk absen.";
      } else {
        isWithinRadius.value = false;
        attendanceMessage.value = "Anda berada di luar area sekolah. Jarak Anda: ${distanceInMeters.toStringAsFixed(0)} meter.";
      }
    } catch (e) {
      attendanceMessage.value = "Error: ${e.toString()}";
      isWithinRadius.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fungsi untuk mencatat absensi ke Firestore
  Future<void> markAttendance() async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User tidak ditemukan");

      // Dapatkan data pegawai untuk nama, dll.
      final userProfile = await _firestore.collection('Sekolah').doc(idSekolah)
          .collection('pegawai').doc(user.uid).get();
      final userName = userProfile.data()?['nama'] ?? 'Tanpa Nama';

      final String todayDocId = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Position currentPosition = await _determinePosition();

      // Simpan data absensi
      await _firestore.collection('Sekolah').doc(idSekolah)
          .collection('absensi').doc(todayDocId)
          .collection('pegawai').doc(user.uid).set({
            'userId': user.uid,
            'nama': userName,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'Hadir',
            'lokasi': GeoPoint(currentPosition.latitude, currentPosition.longitude),
          });
      
      hasAttendedToday.value = true;
      isWithinRadius.value = false;
      attendanceMessage.value = "Absensi berhasil dicatat. Terima kasih!";

    } catch (e) {
      Get.snackbar('Gagal', 'Gagal mencatat absensi: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  /// Helper function dari package geolocator untuk handle permission dan get location.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi dinonaktifkan.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Izin lokasi ditolak secara permanen, kami tidak dapat meminta izin.');
    }

    return await Geolocator.getCurrentPosition();
  }
}