// lib/controllers/kalender_akademik_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/event_kalender_model.dart'; // Sesuaikan path jika perlu

// Helper class untuk data ringkasan bulanan yang sudah dikelompokkan
class GroupedEvent {
  final String keterangan;
  final bool isLibur;
  final Color color;
  DateTime startDate;
  DateTime endDate;

  GroupedEvent({
    required this.keterangan,
    required this.isLibur,
    required this.color,
    required this.startDate,
    required this.endDate,
  });
}

class KalenderAkademikController extends GetxController {
  // --- LAYANAN FIREBASE ---
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // --- KONFIGURASI & STATE PENGGUNA ---
  final String idSekolah = "20404148"; // Hardcoded sesuai permintaan
  String? idTahunAjaran;
  final RxString userRole = ''.obs; // Diisi secara dinamis dari Firestore

  // --- STATE UNTUK UI & KALENDER ---
  final RxBool isLoading = true.obs;
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime?> selectedDay = DateTime.now().obs;
  final Rx<CalendarFormat> calendarFormat = CalendarFormat.month.obs;

  // --- STATE UNTUK DATA EVENT ---
  final RxMap<DateTime, List<EventKalenderModel>> events = <DateTime, List<EventKalenderModel>>{}.obs;
  final RxList<EventKalenderModel> selectedEvents = <EventKalenderModel>[].obs; // Agenda harian
  final RxList<GroupedEvent> groupedMonthlyEvents = <GroupedEvent>[].obs; // Ringkasan bulanan

  // --- STATE UNTUK FORM DIALOG ---
  final TextEditingController eventController = TextEditingController();
  final Rx<DateTime> rentangAwal = DateTime.now().obs;
  final Rx<DateTime> rentangAkhir = DateTime.now().obs;
  final RxBool isLiburSwitch = false.obs;
  final Rx<Color> selectedColor = Colors.blue.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// 1. FUNGSI INISIALISASI UTAMA
  Future<void> _initialize() async {
    isLoading.value = true;
    await _fetchUserRole();
    await _fetchTahunAjaranTerakhir();
    await _fetchEvents();
    
    // Set state awal untuk tampilan
    onDaySelected(selectedDay.value!, focusedDay.value);
    _updateGroupedMonthlyEvents(focusedDay.value);
    
    isLoading.value = false;
  }

  /// 2. PENGELOLAAN DATA PENGGUNA
  Future<void> _fetchUserRole() async {
    final user = auth.currentUser;
    if (user == null) {
      userRole.value = 'Siswa'; // Default jika tidak ada user login
      return;
    }
    try {
     final docSnapshot = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai') // <-- Path yang benar
          .doc(user.uid)
          .get();
      if (docSnapshot.exists) {
        userRole.value = docSnapshot.data()?['role'] ?? 'Siswa';
      } else {
        userRole.value = 'Siswa';
      }
    } catch (e) {
      userRole.value = 'Siswa';
      Get.snackbar("Error", "Gagal mengambil data peran: $e");
    }
  }

  /// 3. PENGELOLAAN DATA EVENT DARI FIRESTORE
  Future<void> _fetchTahunAjaranTerakhir() async {
    try {
      final snapshot = await firestore
          .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
          .orderBy('namatahunajaran', descending: true).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        idTahunAjaran = snapshot.docs.first.id;
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil data tahun ajaran: $e");
    }
  }

  Future<void> _fetchEvents() async {
    if (idTahunAjaran == null) return;
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .doc(idTahunAjaran!).collection('kalender_akademik').get();

    final Map<DateTime, List<EventKalenderModel>> fetchedEvents = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      try {
        final day = DateTime.parse(doc.id);
        final event = EventKalenderModel(
          id: doc.id,
          keterangan: data['keterangan'] ?? 'Tanpa Keterangan',
          isLibur: data['is_libur'] ?? false,
          color: data.containsKey('hex_color') ? Color(int.parse(data['hex_color'], radix: 16)) : Colors.blue,
        );
        final dateUtc = DateTime.utc(day.year, day.month, day.day);
        if (fetchedEvents[dateUtc] == null) fetchedEvents[dateUtc] = [];
        fetchedEvents[dateUtc]!.add(event);
      } catch (e) {
        print("Error parsing data event untuk doc ${doc.id}: $e");
      }
    }
    events.value = fetchedEvents;
  }
  
  /// 4. LOGIKA PEMROSESAN & PENGELOMPOKAN EVENT
  void _updateGroupedMonthlyEvents(DateTime month) {
    groupedMonthlyEvents.clear();
    final firstDayOfMonth = DateTime.utc(month.year, month.month, 1);
    final lastDayOfMonth = DateTime.utc(month.year, month.month + 1, 0);

    final List<MapEntry<DateTime, EventKalenderModel>> allEventsInMonth = [];
    events.forEach((day, eventList) {
      if (day.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) && day.isBefore(lastDayOfMonth.add(const Duration(days: 1)))) {
        for (var event in eventList) {
          allEventsInMonth.add(MapEntry(day, event));
        }
      }
    });
    allEventsInMonth.sort((a, b) => a.key.compareTo(b.key));

    if (allEventsInMonth.isEmpty) return;

    List<GroupedEvent> result = [];
    GroupedEvent currentGroup = GroupedEvent(
      keterangan: allEventsInMonth.first.value.keterangan,
      isLibur: allEventsInMonth.first.value.isLibur,
      color: allEventsInMonth.first.value.color,
      startDate: allEventsInMonth.first.key,
      endDate: allEventsInMonth.first.key,
    );

    for (int i = 1; i < allEventsInMonth.length; i++) {
      final day = allEventsInMonth[i].key;
      final event = allEventsInMonth[i].value;

      if (event.keterangan == currentGroup.keterangan &&
          event.isLibur == currentGroup.isLibur &&
          day.difference(currentGroup.endDate).inDays == 1) {
        currentGroup.endDate = day;
      } else {
        result.add(currentGroup);
        currentGroup = GroupedEvent(
          keterangan: event.keterangan,
          isLibur: event.isLibur,
          color: event.color,
          startDate: day,
          endDate: day,
        );
      }
    }
    result.add(currentGroup);
    groupedMonthlyEvents.value = result;
  }

  /// 5. FUNGSI INTERAKSI KALENDER
  void onPageChanged(DateTime newFocusedDay) {
    focusedDay.value = newFocusedDay;
    _updateGroupedMonthlyEvents(newFocusedDay);
  }

  void onDaySelected(DateTime day, DateTime focused) {
    if (!isSameDay(selectedDay.value, day)) {
      selectedDay.value = day;
      focusedDay.value = focused;
      final dateUtc = DateTime.utc(day.year, day.month, day.day);
      selectedEvents.value = events[dateUtc] ?? [];
    }
  }

  List<EventKalenderModel> getEventsForDay(DateTime day) {
    final dateUtc = DateTime.utc(day.year, day.month, day.day);
    return events[dateUtc] ?? [];
  }

  Future<void> simpanEvent() async {
   if (eventController.text.isEmpty) {
    Get.snackbar("Error", "Keterangan acara tidak boleh kosong.");
    return;
    }
     if (idTahunAjaran == null) {
    Get.snackbar("Error", "Tahun Ajaran tidak ditemukan.");
    return;
    }

    isLoading.value = true;
   try {
    final batch = firestore.batch();
    
    // Loop dari tanggal awal sampai tanggal akhir
    for (var day = rentangAwal.value;
         day.isBefore(rentangAkhir.value.add(const Duration(days: 1)));
         day = day.add(const Duration(days: 1))) {
      
      final docId = DateFormat('yyyy-MM-dd').format(day);
      final docRef = firestore
          .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
          .doc(idTahunAjaran!).collection('kalender_akademik').doc(docId);

      final data = {
        "keterangan": eventController.text,
        "is_libur": isLiburSwitch.value,
        "hex_color": selectedColor.value.value.toRadixString(16).padLeft(8, '0').toUpperCase(),
      };
      
      batch.set(docRef, data);
    }

    await batch.commit();
    Get.back(); // Tutup dialog
    Get.snackbar("Sukses", "Agenda berhasil disimpan.");
    
    // Muat ulang event untuk memperbarui UI
    await _fetchEvents();
    onDaySelected(selectedDay.value!, focusedDay.value);

  } catch (e) {
    Get.snackbar("Error", "Gagal menyimpan agenda: $e");
  } finally {
    isLoading.value = false;
  }
}


  // --- FUNGSI BARU UNTUK HAPUS AGENDA ---
  Future<void> hapusEvent(String eventId, DateTime eventDate) async {
    Get.defaultDialog(
      title: "Konfirmasi",
      middleText: "Apakah Anda yakin ingin menghapus agenda ini?",
      textConfirm: "Ya, Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back(); // Tutup dialog konfirmasi
        isLoading.value = true;
        try {
          final docRef = firestore
              .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
              .doc(idTahunAjaran!).collection('kalender_akademik').doc(eventId);

          await docRef.delete();
          Get.snackbar("Sukses", "Agenda berhasil dihapus.");

          // Muat ulang data untuk memperbarui UI
          await _fetchEvents();
          onDaySelected(eventDate, eventDate); // Refresh list untuk tanggal yang sama

        } catch (e) {
          Get.snackbar("Error", "Gagal menghapus agenda: $e");
        } finally {
          isLoading.value = false;
        }
      },
    );
  }

  // --- FUNGSI BARU UNTUK MENYIMPAN PERUBAHAN (EDIT) ---
  Future<void> simpanPerubahanEvent(String eventId) async {
    if (eventController.text.isEmpty) {
      Get.snackbar("Error", "Keterangan acara tidak boleh kosong.");
      return;
    }
    isLoading.value = true;
    try {
      final docRef = firestore
          .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
          .doc(idTahunAjaran!).collection('kalender_akademik').doc(eventId);

      final data = {
        "keterangan": eventController.text,
        "is_libur": isLiburSwitch.value,
        "hex_color": selectedColor.value.value.toRadixString(16).padLeft(8, '0').toUpperCase(),
      };

      await docRef.update(data); // Gunakan update, bukan set
      Get.back(); // Tutup dialog
      Get.snackbar("Sukses", "Agenda berhasil diperbarui.");

      await _fetchEvents();
      onDaySelected(selectedDay.value!, focusedDay.value);
    } catch (e) {
      Get.snackbar("Error", "Gagal memperbarui agenda: $e");
    } finally {
      isLoading.value = false;
    }
  }

}