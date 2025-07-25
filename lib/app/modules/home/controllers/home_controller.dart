// lib/app/modules/home/controllers/home_controller.dart

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../controller/storage_controller.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../../../models/event_kalender_model.dart';
// import '../pages/home.dart';
// import '../pages/marketplace.dart';
// import '../pages/profile.dart';
import '../../../models/jurnal_model.dart';

class HomeController extends GetxController {

  // --- VARIABEL & STATE ---
  final StorageController storageC = Get.find<StorageController>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late final String idUser;
  late final String emailAdmin;
  final String idSekolah = "20404148";
  Set<String> hariLiburSet = {};
  Map<String, Map<String, dynamic>> jurnalOtomatisConfig = {};
  final RxBool isLoading = true.obs;
  final RxString jamPelajaranDocId = 'Memuat jam...'.obs;
  final Rx<String?> userRole = Rx<String?>(null);
  final RxString pesanAkhirSekolahKustom = "".obs;
  final RxString pesanLiburKustom = "".obs;
  final Rx<DateTime?> tanggalUpdatePesanAkhirSekolah = Rx<DateTime?>(null);
  final Rxn<String> idTahunAjaran = Rxn<String>(null);
  final RxList<String> userTugas = <String>[].obs;

  /// Menyimpan ID kelas jika user adalah seorang pendamping tahfidz.
  /// Akan null jika bukan pendamping.
  final Rxn<String> tugasPendampingKelasId = Rxn<String>();

  final RxString semesterAktifId = "1".obs;
  final RxBool isReady = false.obs;
  
  // Variabel ini akan diisi oleh _fetchKelasAktif
  List<DocumentSnapshot<Map<String, dynamic>>> kelasAktifList = []; 
  
  List<Map<String, dynamic>> jadwalPelajaranList = [];
  final TextEditingController kelasSiswaC = TextEditingController();
  final TextEditingController tahunAjaranBaruC = TextEditingController();
  final PersistentTabController tabController = PersistentTabController(initialIndex: 0);
  // final List<Widget> navBarScreens = [ HomePage(), MarketplacePage(), ProfilePage() ];

  final RxList<Map<String, dynamic>> kelompokMengajiDiajar = <Map<String, dynamic>>[].obs;


  // --- (Getter untuk TUGAS TAMBAHAN) ---
  bool get isInKurikulumTeam => userTugas.contains('Kurikulum');
  bool get isInKesiswaanTeam => userTugas.contains('Kesiswaan');
  // bool get canManageHalaqoh => userTugas.contains('Koordinator Halaqoh'); // Koordinator Halaqoh kini adalah tugas
  
  // stelah ada tugas -------------------------
  bool get isDalang => auth.currentUser?.email == 'saefudin123.skom@gmail.com'; 
  bool get kapten => auth.currentUser?.email == 'hidayyat@gmail.com';
  bool get isKepsek => userRole.value == 'Kepala Sekolah';
  bool get isAdmin => userRole.value == 'Admin';
  bool get isAdminKepsek => userRole.value == 'Admin' || userRole.value == 'Kepala Sekolah'; 
  bool get canManageTahsin => userTugas.contains('Koordinator Halaqoh') || isDalang;
  bool get informasiKelas => userRole.value == 'Guru Kelas' || userRole.value == 'Guru Mapel' || userTugas.contains('Guru Mapel');
  bool get jurnalHarian => userRole.value == 'Guru Kelas' || userRole.value == 'Guru Mapel';
  bool get walikelas => userRole.value == 'Guru Kelas';
  bool get guruBK => userRole.value == 'Guru BK';
  // bool get tahfidzKelas => userRole.value == 'Guru Kelas' || userTugas.contains('Pendamping Tahfidz');
  bool get tahfidzKelas => walikelas || tugasPendampingKelasId.value != null;
  bool get isPimpinan => isAdminKepsek && !walikelas && tugasPendampingKelasId.value == null;
  bool get canEditOrDeleteHalaqoh => kelasTahsin || canManageTahsin || kapten; 
  bool get tambahHalaqohFase => canManageTahsin || kapten;
  
  // bool get kelasTahsin => userRole.value == 'Pengampu' || userTugas.contains('Pengampu');
  bool get kelasTahsin => kelompokMengajiDiajar.isNotEmpty;

  

  Timer? _timer;
  StreamSubscription? _configListener;

 // --- FUNGSI BAWAAN GETX ---
  @override
  void onInit() {
    super.onInit();
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      Get.offAllNamed('/login');
      return;
    }
    idUser = currentUser.uid;
    _initializeData();
  }


  @override
  void onClose() {
    _timer?.cancel();
    _configListener?.cancel(); 
    tabController.dispose();
    kelasSiswaC.dispose();
    tahunAjaranBaruC.dispose();
    super.onClose();
  }
  
  
  Future<void> fetchUserRoleAndTugas() async {
    try {
      final doc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
          
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        userRole.value = data['role'] as String?;
        
        // Ambil 'tugas' (List/Array)
        final tugasData = data['tugas'];
        if (tugasData is List) {
          userTugas.assignAll(List<String>.from(tugasData));
          } else {
          userTugas.clear(); // Pastikan kosong jika field tidak ada
        }

         kelompokMengajiDiajar.clear(); // Kosongkan dulu untuk refresh
        if (idTahunAjaran.value != null) {
          final kelompokSnapshot = await doc.reference
              .collection('tahunajarankelompok').doc(idTahunAjaran.value!)
              .collection('semester').doc(semesterAktifId.value)
              .collection('kelompokmengaji').get();
          
          if (kelompokSnapshot.docs.isNotEmpty) {
            // Simpan semua kelompok yang diajar ke dalam state
            kelompokMengajiDiajar.assignAll(
              kelompokSnapshot.docs.map((kelompokDoc) => kelompokDoc.data()).toList()
            );
          }
        }
        print("INFO: Ditemukan ${kelompokMengajiDiajar.length} kelompok halaqoh yang diajar.");
        // --- AKHIR TAMBAHAN ---
      }
    } catch (e) {
      print("Gagal mengambil role & tugas pengguna: $e");
      userRole.value = null;
      userTugas.clear();
    }
  }




void _listenToConfigChanges() {
  if (idTahunAjaran == null) return;

  final docRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran.value!);

  _configListener?.cancel(); 

  _configListener = docRef.snapshots().listen((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()!;
      
      // ... (kode pesanLiburKustom sudah benar, biarkan saja)

      // --- MODIFIKASI BAGIAN INI ---
      // Update pesan akhir sekolah kustom
      if (data.containsKey('pesanAkhirSekolahConfig')) {
        final config = data['pesanAkhirSekolahConfig'] as Map<String, dynamic>;
        pesanAkhirSekolahKustom.value = (config['pesan'] as String?) ?? "";
        
        // Ambil timestamp, konversi ke DateTime, dan simpan di state
        if (config['tanggalUpdate'] != null) {
          final timestamp = config['tanggalUpdate'] as Timestamp;
          tanggalUpdatePesanAkhirSekolah.value = timestamp.toDate();
        } else {
          tanggalUpdatePesanAkhirSekolah.value = null; // Reset jika tidak ada tanggal
        }
        
      } else {
        // Jika config dihapus, reset pesan dan tanggalnya
        pesanAkhirSekolahKustom.value = ""; 
        tanggalUpdatePesanAkhirSekolah.value = null;
      }
      // --- AKHIR MODIFIKASI ---

      print("DEBUG: Pesan config terupdate -> ${pesanAkhirSekolahKustom.value} pada ${tanggalUpdatePesanAkhirSekolah.value}");

    }
  }, onError: (error) {
    print("Error mendengarkan config: $error");
  });
}

// Buat FUNGSI BARU untuk menyimpan pesan
Future<void> simpanPesanAkhirSekolah(String pesanBaru) async {
  if (idTahunAjaran == null) {
    Get.snackbar("Error", "Tahun ajaran tidak aktif.");
    return;
  }
  
  final userDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
  final namaKepsek = userDoc.data()?['nama'] ?? 'Admin';

  try {
    isLoading.value = true;
    final docRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran.value!);
    
    await docRef.update({
      'pesanAkhirSekolahConfig': {
        'pesan': pesanBaru,
        'diubahOleh': namaKepsek,
        'terakhirDiubah': FieldValue.serverTimestamp(),
        'tanggalUpdate': Timestamp.now(),
      }
    });
    Get.snackbar("Berhasil", "Pesan akhir sekolah berhasil diperbarui.");
  } catch (e) {
    Get.snackbar("Error", "Gagal menyimpan pesan: $e");
  } finally {
    isLoading.value = false;
  }
}

  Future<void> _fetchUserRole() async {
  try {
    final doc = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('pegawai').doc(idUser)
        .get();
    if (doc.exists) {
      // Ambil field 'role' dari dokumen, jika tidak ada, defaultnya null.
      userRole.value = doc.data()?['role'];
    }
  } catch (e) {
    print("Gagal mengambil role pengguna: $e");
    // Biarkan role null jika terjadi error
  }
}

  void _showSafeSnackbar(String title, String message, {bool isError = false}) {
    // Memastikan snackbar hanya ditampilkan setelah frame UI selesai digambar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
      Get.snackbar(
        title,
        message,
        backgroundColor: isError ? Colors.red : Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }

   /// Menyediakan stream data PENGGUNA (PEGAWAI) yang sedang login
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream() {
    // Path ini sekarang menggunakan idUser dan idSekolah dari controller ini sendiri
    return firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile() {
    return firestore.collection('Sekolah').doc(idSekolah)
                   .collection('pegawai').doc(idUser).snapshots();
  }


  /// Mengorkestrasi seluruh proses: pilih gambar, upload, dan simpan URL.
  Future<void> pickAndUploadProfilePicture() async {
    final user = auth.currentUser;
    if (user == null) {
      _showSafeSnackbar('Error', 'Sesi tidak valid. Silakan login ulang.', isError: true);
      return;
    }

    // 1. Pilih gambar dari galeri
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70, // Kompresi gambar agar tidak terlalu besar
    );

    if (pickedFile == null) {
      // Pengguna membatalkan pemilihan, tidak perlu melakukan apa-apa.
      return;
    }

    // Tampilkan dialog loading SEBELUM memulai proses berat (upload/update)
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final File imageFile = File(pickedFile.path);
      
      // 2. Upload gambar ke Supabase
      final String? imageUrl = await storageC.uploadProfilePicture(imageFile, user.uid);

      if (imageUrl == null) {
        // Jika upload gagal (StorageController mengembalikan null)
        throw Exception('Gagal mengupload gambar ke server.');
      }
      
      // 3. Jika upload berhasil, simpan URL ke Firestore
      await _updateProfileUrlInFirestore(imageUrl, user.uid);
      
      // 4. Tampilkan pesan sukses
      _showSafeSnackbar('Berhasil', 'Foto profil berhasil diperbarui!');

    } catch (e) {
      // 5. Tangani SEMUA jenis error di sini
      print("Error pickAndUploadProfilePicture: $e"); // Log error untuk debug
      _showSafeSnackbar('Error', 'Gagal memperbarui foto: ${e.toString()}', isError: true);
    } finally {
      // 6. PASTIKAN dialog loading SELALU ditutup, baik berhasil maupun gagal.
      Get.back();
    }
  }

  /// Fungsi private untuk menyimpan URL ke Firestore
  Future<void> _updateProfileUrlInFirestore(String imageUrl, String uid) async {
    try {
      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .doc(uid)
          .update({'profileImageUrl': imageUrl});
    } catch (e) {
      // Melempar exception agar bisa ditangkap oleh blok catch di fungsi utama
      throw Exception('Gagal menyimpan URL ke Firestore: $e');
    }
  }

  // =========================================================================
  // LOGIKA INISIALISASI UTAMA
  // =========================================================================
  Future<void> _initializeData() async {
    isLoading.value = true;
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) throw Exception("Sesi tidak valid, silakan login ulang.");
      emailAdmin = currentUser.email!;

      // Langkah 1: Ambil Tahun Ajaran Aktif (tetap sama)
      idTahunAjaran.value = await _fetchTahunAjaranTerakhir();

      // --- PENAMBAHAN BARU (FONDASI) ---
      // Langkah 2: Setelah tahu tahun ajaran, ambil semester aktifnya.
      await _fetchSemesterAktif();
      // ------------------------------------

      _listenToConfigChanges();

      // Langkah 3: Jalankan sisa pengambilan data
      await Future.wait([
        _fetchJadwalPelajaran(),
        _fetchKelasAktif(),
        _fetchJurnalOtomatisConfig(),
        _fetchHariLibur(),
        _fetchUserRole(),
        fetchUserRoleAndTugas()
      ]);

      _updateCurrentJamPelajaran();
      _startTimerForClock();

      isReady.value = true;

    } catch (e) {
      _showSafeSnackbar("Kesalahan Inisialisasi", "Gagal memuat data awal: ${e.toString()}", isError: true);
      jamPelajaranDocId.value = "Error memuat data";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchSemesterAktif() async {
    if (idTahunAjaran.value == null) {
      print("Peringatan: Tidak bisa mengambil semester karena ID Tahun Ajaran null.");
      return;
    }
    try {
      final doc = await firestore.collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran.value!).get();
          
      if (doc.exists && doc.data() != null) {
        // Ambil nilai dari field 'semesterAktif', jika tidak ada, gunakan '1' sebagai fallback.
        semesterAktifId.value = doc.data()!['semesterAktif'] ?? '1';
        print("INFO: Semester aktif dimuat: ${semesterAktifId.value}");
      } else {
        print("PERINGATAN: Dokumen tahun ajaran tidak ditemukan, menggunakan semester default '1'.");
        semesterAktifId.value = '1';
      }
    } catch (e) {
      print("ERROR: Gagal mengambil semester aktif: $e");
      // Jika terjadi error, gunakan nilai default agar aplikasi tidak crash.
      semesterAktifId.value = '1';
    }
  }
  

  Future<void> _fetchPesanLiburKustom() async {
  if (idTahunAjaran == null) return;
  try {
    final doc = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran.value!).get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('pesanLiburConfig')) {
      final config = doc.data()!['pesanLiburConfig'] as Map<String, dynamic>;
      final pesan = config['pesan'] as String?;
      if (pesan != null && pesan.isNotEmpty) {
        pesanLiburKustom.value = pesan;
      }
    }
  } catch (e) {
    print("Gagal mengambil pesan libur kustom: $e");
  }
}

  // --- FUNGSI BARU ---
  Future<void> _fetchHariLibur() async {
    if (idTahunAjaran == null) return;
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .doc(idTahunAjaran.value!).collection('kalender_akademik')
        .where('is_libur', isEqualTo: true) // Hanya ambil yang libur
        .get();
    
    for (var doc in snapshot.docs) {
      // Simpan tanggal dalam format yyyy-MM-dd
      hariLiburSet.add(doc.id); 
    }
    // print("DEBUG: Hari libur dimuat: $hariLiburSet");
  }

  // --- FUNGSI BARU ---
bool isHariSekolahAktif(DateTime tanggal) {
  // 1. Cek apakah hari Sabtu (6) atau Minggu (7)
  if (tanggal.weekday == DateTime.saturday || tanggal.weekday == DateTime.sunday) {
    return false;
  }

  // 2. Cek apakah tanggal ada di daftar hari libur nasional/sekolah
  String formattedDate = DateFormat('yyyy-MM-dd').format(tanggal);
  if (hariLiburSet.contains(formattedDate)) {
    return false;
  }
  
  // 3. Jika lolos semua, berarti hari sekolah aktif
  return true;
}


  // --- FUNGSI BARU UNTUK OTOMATISASI JAM KEGIATAN RUTIN (PERSIAPAN, ISTIRAHAT DLL)---
  Future<void> _fetchJurnalOtomatisConfig() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah).collection('konfigurasi_jurnal_otomatis').get();
    
    for (var doc in snapshot.docs) {
      jurnalOtomatisConfig[doc.id] = doc.data();
    }
    // print("DEBUG: Konfigurasi Jurnal Otomatis dimuat: $jurnalOtomatisConfig");
  }


  // =========================================================================
  // LOGIKA PENGAMBILAN DATA (FETCHING)
  // =========================================================================

  Future<String> _fetchTahunAjaranTerakhir() async {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .orderBy('namatahunajaran', descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) throw Exception("Tidak ada data tahun ajaran.");
    return snapshot.docs.first.id;
  }

  Future<void> _fetchJadwalPelajaran() async {
  final snapshot = await firestore
      .collection('Sekolah').doc(idSekolah).collection('jampelajaran').get();
  
  jadwalPelajaranList = snapshot.docs.map((doc) {
    final data = doc.data();
    
    // Asumsi di Firestore ada field 'jampelajaran' berisi "HH.mm-HH.mm"
    final String jamString = data['jampelajaran'] ?? doc.id;
    
    // Pecah string jam menjadi bagian start dan end
    final parts = jamString.split('-');
    
    String startTime = "00.00";
    String endTime = "00.00";

    if (parts.length == 2) {
      startTime = parts[0]; // contoh: "23.25"
      endTime = parts[1];   // contoh: "23.59"
    } else {
      // Sebagai fallback jika formatnya tidak sesuai, agar tidak crash
      print("Peringatan: Format jam pelajaran salah untuk dokumen ID: ${doc.id}. Menggunakan waktu default.");
    }
    
    // Kembalikan Map dengan format yang benar
    return {'id': doc.id, 'start': startTime, 'end': endTime};
  }).toList();

  // (Optional) Tambahkan print untuk memastikan hasilnya benar
  print("DEBUG: Jadwal Pelajaran yang dimuat: $jadwalPelajaranList");
}

  Future<void> _fetchKelasAktif() async {
    if (idTahunAjaran.value == null) return;
    try {
      final snapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran.value!)
          .collection('kelastahunajaran').get();
          
      // Mengisi variabel yang digunakan oleh UI (home.dart)
      kelasAktifList = snapshot.docs;
    } catch (e) {
      print("Gagal mengambil semua kelas aktif: $e");
      kelasAktifList = []; // Pastikan kosong jika error.
    }
  }

  // =========================================================================
  // LOGIKA JAM PELAJARAN
  // =========================================================================

  void _startTimerForClock() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCurrentJamPelajaran();
    });
  }

  void _updateCurrentJamPelajaran() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    String newJam = 'Tidak ada jam pelajaran';

    for (final jadwal in jadwalPelajaranList) {
      try {
        final startMinutes = _parseTimeToMinutes(jadwal['start']);
        final endMinutes = _parseTimeToMinutes(jadwal['end']);
        if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
          newJam = jadwal['id'];
          break; // Keluar setelah menemukan yang cocok
        }
      } catch (_) {
        continue; // Abaikan jadwal dengan format salah
      }
    }
    if (jamPelajaranDocId.value != newJam) {
      jamPelajaranDocId.value = newJam;
    }
  }

  int _parseTimeToMinutes(String? hhmm) {
    if (hhmm == null) throw const FormatException("Waktu null");
    final parts = hhmm.split('.');
    if (parts.length != 2) throw const FormatException("Format waktu salah");
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // =========================================================================
  // STREAMS UNTUK DATA REAL-TIME
  // =========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamInformasiSekolah() {
    // Periksa NILAI di dalam Rxn, bukan objeknya.
    if (idTahunAjaran.value == null) {
      // Kembalikan stream kosong jika ID belum siap. UI tidak akan crash.
      return const Stream.empty(); 
    }
    return firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .doc(idTahunAjaran.value!) // Sekarang aman digunakan karena sudah dicek
        .collection('informasisekolah')
        .orderBy('tanggalinput', descending: true).limit(10).snapshots();
}

  // Tambahkan deklarasi events di atas fungsi ini, misal:
  // Map<DateTime, List<EventKalenderModel>> events = {};

  // Jika events perlu diisi dari Firestore, tambahkan logika pengisian pada _fetchHariLibur atau fungsi lain yang sesuai.

  Map<DateTime, List<EventKalenderModel>> events = {};

  // di HomeController (Aplikasi Guru)

Stream<JurnalModel?> streamJurnalDetail(String idKelas) {
    final jamId = jamPelajaranDocId.value;
    
    // Gunakan ID Tahun Ajaran & Semester dari state controller ini
    final tahunAjaranId = idTahunAjaran.value;
    final semesterId = semesterAktifId.value;

    if (tahunAjaranId == null || jamId.isEmpty || jamId.contains('...')) {
      return Stream.value(null);
    }

    // Logika untuk hari libur dan jam sekolah usai (tetap sama, sudah benar)
    final now = DateTime.now();
    if (!isHariSekolahAktif(now)) {
      // ... logika hari libur
      return Stream.value(JurnalModel(materipelajaran: "Selamat menikmati hari libur.", namapenginput: "Sistem", jampelajaran: "Hari Libur"));
    }
    if (jamId == 'Tidak ada jam pelajaran') {
      // ... logika jam usai
      return Stream.value(JurnalModel(materipelajaran: "Kegiatan belajar telah usai.", namapenginput: "Info Sekolah", jampelajaran: "Jam Sekolah Usai"));
    }

    // --- INTI PERUBAHAN ---
    // Sekarang kita membuat path yang lengkap dengan semester.
    final docIdTanggalJurnal = DateFormat('yyyy-MM-dd').format(now);
    
    final docRef = firestore
      .collection('Sekolah').doc(idSekolah)
      .collection('tahunajaran').doc(tahunAjaranId)
      .collection('kelastahunajaran').doc(idKelas) // <- Menggunakan `kelastahunajaran`
      .collection('semester').doc(semesterId)      // <-- INTEGRASI SEMESTER
      .collection('tanggaljurnal').doc(docIdTanggalJurnal)
      .collection('jurnalkelas').doc(jamId);

    // Sisa logikanya tetap sama
    return docRef.snapshots().map((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return JurnalModel.fromFirestore(docSnapshot.data()!);
      }
      if (jurnalOtomatisConfig.containsKey(jamId)) {
        final configData = jurnalOtomatisConfig[jamId]!;
        return JurnalModel.fromFirestore(configData);
      }
      return null;
    });
  }

  // UNTUK KEPALA SEKOLAH
  Future<void> simpanPesanLibur(String pesanBaru) async {
  if (idTahunAjaran == null) {
    Get.snackbar("Error", "Tahun ajaran tidak aktif.");
    return;
  }
  
  // Ambil nama Kepala Sekolah dari profil yang sedang login
  final userDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
  final namaKepsek = userDoc.data()?['nama'] ?? 'Admin';

  try {
    isLoading.value = true;
    final docRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran.value!);
    
    await docRef.update({
      'pesanLiburConfig': {
        'pesan': pesanBaru,
        'diubahOleh': namaKepsek,
        'terakhirDiubah': FieldValue.serverTimestamp(),
        'tanggalUpdate': Timestamp.now(),
      }
    });
    Get.snackbar("Berhasil", "Pesan libur berhasil diperbarui.");
  } catch (e) {
    Get.snackbar("Error", "Gagal menyimpan pesan: $e");
  } finally {
    isLoading.value = false;
  }
}


  // =========================================================================
  // ACTIONS
  // =========================================================================
  
  void signOut() async {
    await auth.signOut();
    Get.offAllNamed('/login'); // Ganti dengan rute login Anda
  }

  

  Future<void> simpanTahunAjaran() async {
    String uid = auth.currentUser!.uid;
    String emailPenginput = auth.currentUser!.email!;

    DocumentReference<Map<String, dynamic>> ambilDataPenginput = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(uid);

    DocumentSnapshot<Map<String, dynamic>> snapDataPenginput =
        await ambilDataPenginput.get();

    CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran');
    QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
        await colTahunAjaran.get();
    List<Map<String, dynamic>> listTahunAjaran =
        snapshotTahunAjaran.docs.map((e) => e.data()).toList();

    //ambil namatahunajaranya
    listTahunAjaran.map((e) => e['namatahunajaran']).toList();

    // buat documen id buat tahun ajaran
    String idTahunAjaran = tahunAjaranBaruC.text.replaceAll("/", "-");

    if (listTahunAjaran.elementAt(0)['namatahunajaran'] !=
        tahunAjaranBaruC.text) {
      if (!listTahunAjaran.any(
        (element) => element['namatahunajaran'] == tahunAjaranBaruC.text,
      )) {
        //belum input tahun ajaran yang baru, maka bikin tahun ajaran baru
        colTahunAjaran
            .doc(idTahunAjaran)
            .set({
              'namatahunajaran': tahunAjaranBaruC.text,
              'idpenginput': uid,
              'emailpenginput': emailPenginput,
              'namapenginput': snapDataPenginput.data()?['nama'],
              'tanggalinput': DateTime.now().toString(),
              'idtahunajaran': idTahunAjaran,
            })
            .then(
              (value) => {
                Get.snackbar('Berhasil', 'Tahun ajaran sudah berhasil dibuat'),
                tahunAjaranBaruC.text = "",
              },
            );
      } else {
        Get.snackbar('Gagal', 'Tahun ajaran sudah ada');
      }
      // Get.back();
    }
    // Get.back();
  }

  Future<String?> getDataKelasWali() async {
  String tahunajaranya = await getTahunAjaranTerakhir();
  String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

  QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
      .collection('Sekolah')
      .doc(idSekolah)
      .collection('tahunajaran')
      .doc(idTahunAjaran)
      .collection('kelastahunajaran')
      .where('idwalikelas', isEqualTo: idUser)
      .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first.id;
  } else {
    // print('Tidak ditemukan kelas untuk walikelas dengan id: $idUser');
    // Get.snackbar("Informasi", "Tidak ada catatan dalam kelas anda");
    return null;
  }
}

  Future<String> getTahunAjaranTerakhir() async {
    CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran');
    QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
        await colTahunAjaran.get();
    List<Map<String, dynamic>> listTahunAjaran =
        snapshotTahunAjaran.docs.map((e) => e.data()).toList();
    String tahunAjaranTerakhir =
        listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
    return tahunAjaranTerakhir;
  }

  Future<List<String>> getDataFase() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    // String idSemester = 'Semester I';  // nanti ini diambil dari database

    List<String> faseList = [];

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            faseList.add(docSnapshot.id);
          }
        });
    return faseList;
  }

  Future<List<String>> getDataKelasYangDiajar() async {
    // Ambil data global yang sudah ada di controller ini
    final idTahunAjaranValue = idTahunAjaran.value;
    final semesterAktif = semesterAktifId.value;

    // --- BLOK DEBUGGING ---
    // Cetak semua variabel yang kita gunakan untuk query ke konsol.
    debugPrint("=========================================");
    debugPrint("[DEBUG] Menjalankan getDataKelasYangDiajar()");
    debugPrint("   -> Menggunakan idUser: $idUser");
    debugPrint("   -> Menggunakan idTahunAjaran: $idTahunAjaranValue");
    debugPrint("   -> Menggunakan semesterAktif: $semesterAktif");
    // ----------------------

    if (idTahunAjaranValue == null) {
      debugPrint("   -> HASIL: Gagal, idTahunAjaranValue adalah null.");
      debugPrint("=========================================");
      return [];
    }

    List<String> kelasList = [];
    try {
      final snapshot = await firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('pegawai').doc(idUser)
          .collection('tahunajaran').doc(idTahunAjaranValue)
          .collection('semester').doc(semesterAktif)
          .collection('kelasnya').get();
      
      // --- BLOK DEBUGGING ---
      debugPrint("   -> Query berhasil dijalankan.");
      debugPrint("   -> Ditemukan ${snapshot.docs.length} kelas.");
      // ----------------------
          
      for (var docSnapshot in snapshot.docs) {
        kelasList.add(docSnapshot.id);
      }
      
      kelasList.sort();
      
    } catch (e) {
      debugPrint("   -> Query GAGAL dengan error: $e");
    }
    
    debugPrint("   -> HASIL AKHIR: Mengembalikan daftar kelas: $kelasList");
    debugPrint("=========================================");
    return kelasList;
  }

  Future<List<String>> getDataKelas() async {

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('kelas')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }

  Future<List<String>> getDataKelasMapel() async {

    String tahunajaranya =
        await getTahunAjaranTerakhir(); // ambil dari tahun ajaran di collection pegawai
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        // .collection('kelasaktif')
        .collection('kelastahunajaran')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }

  Future<List<String>> getDataMapel(String kelas) async {
    String tahunajaranya =
        await getTahunAjaranTerakhir(); // ambil dari tahun ajaran di collection pegawai
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> mapelList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .doc(idUser)
        .collection('tahunajaran')
        .doc(idTahunAjaran) // tahun ajaran yang d kelas pegawai
        .collection('kelasnya')
        .doc(kelas)
        .collection('matapelajaran')
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            mapelList.add(docSnapshot.id);
          }
        });
    return mapelList;
  }

  // Di dalam HomeController

Future<List<String>> getDataKelompok() async {
  // Ambil data global yang sudah ada di controller ini
  final idTahunAjaranValue = idTahunAjaran.value;
  final semesterAktif = semesterAktifId.value;

  if (idTahunAjaranValue == null) return [];

  List<String> kelompokList = [];
  try {
    final snapshot = await firestore
        .collection('Sekolah').doc(idSekolah)
        .collection('pegawai').doc(idUser)
        .collection('tahunajarankelompok').doc(idTahunAjaranValue)
        .collection('semester').doc(semesterAktif) // <-- PATH SEMESTER BARU
        .collection('kelompokmengaji').get();
        
    for (var docSnapshot in snapshot.docs) {
      kelompokList.add(docSnapshot.id);
    }
  } catch (e) {
    print("Error getDataKelompok (semester): $e");
    // Kembalikan list kosong jika error
  }
  return kelompokList;
}

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataInfo() async* {
    // ignore: unnecessary_null_comparison
    // if (idTahunAjaran == null) return const Stream.empty();

    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('informasisekolah')
        .orderBy('tanggalinput', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataJurnal() async* {
    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('pegawai')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataJurnalKelas() {
    if (idTahunAjaran.value == null) {
      return const Stream.empty();
    }
    return firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .doc(idTahunAjaran.value!)
        .collection('kelasaktif').snapshots();
}

  String getJamPelajaranSaatIni() {
  DateTime now = DateTime.now();
  int currentMinutes = now.hour * 60 + now.minute;
  print('currentMinutes: $currentMinutes');
  List<String> jamPelajaran = [
    '07-00-07.05',
    '07.05-07.30',
    '08.00-08.45',

  ];
  for (String jam in jamPelajaran) {
    List<String> range = jam.split('-');
    int startMinutes = _parseToMinutes(range[0]);
    int endMinutes = _parseToMinutes(range[1]);
    print('Cek: $currentMinutes >= $startMinutes && $currentMinutes < $endMinutes');
    if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
      print('MATCH: $jam');
      return jam;
    }
  }
  print('Tidak ada jam pelajaran');
  return 'Tidak ada jam pelajaran';
}

int _parseToMinutes(String hhmm) {
  List<String> parts = hhmm.split('.');
  int hour = int.parse(parts[0]);
  int minute = int.parse(parts[1]);
  return hour * 60 + minute;
}

  // void test() {
  //   // print("jamPelajaranRx.value = ${jamPelajaranRx.value}, getJamPelajaranSaatIni() = ${getJamPelajaranSaatIni()}");
  //   jamPelajaranRx.value = getJamPelajaranSaatIni();
  //   print('jamPelajaranRx.value (init): ${jamPelajaranRx.value}');
  // }

  void tampilkanjurnal(String docId, String jamPelajaran) {
    getDataJurnalPerKelas(docId, jamPelajaran);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataJurnalPerKelas(
  String docId,
  String jamPelajaran,
) {
    if (idTahunAjaran.value == null) { // Tambahkan pengecekan
      return const Stream.empty();
    }
    DateTime now = DateTime.now();
    String docIdJurnal = DateFormat.yMd().format(now).replaceAll('/', '-');

    return firestore
        .collection('Sekolah').doc(idSekolah).collection('tahunajaran')
        .doc(idTahunAjaran.value!) // Aman digunakan
        .collection('kelasaktif').doc(docId)
        .collection('tanggaljurnal').doc(docIdJurnal)
        .collection('jurnalkelas')
        .where('jampelajaran', isEqualTo: jamPelajaranDocId.value)
        .snapshots();
 }
}

//**
//1. Menggunakan Tipe Data Numerik untuk Perbandingan
// Pendekatan ini lebih robust karena membandingkan angka lebih mudah dan akurat daripada membandingkan string waktu.
//Anda bisa mengubah semua waktu menjadi menit total dari tengah malam atau menggunakan objek DateTime secara langsung.
// Contoh Implementasi: */

void tampilkanSesuaiWaktu() {
  DateTime now = DateTime.now();
  int currentHour = now.hour;
  int currentMinute = now.minute;

  // Konversi waktu sekarang ke menit total dari tengah malam
  int currentTimeInMinutes = currentHour * 60 + currentMinute;

  // Definisikan rentang waktu dalam menit total
  // 01.00 - 01.30
  int startTime1 = 1 * 60 + 0;
  int endTime1 = 1 * 60 + 30;

  // 01.31 - 02.00
  int startTime2 = 1 * 60 + 31;
  int endTime2 = 2 * 60 + 0;

  // 02.01 - 02.30
  int startTime3 = 2 * 60 + 1;
  int endTime3 = 2 * 60 + 30;

  String isidataWaktu1 = 'pertama';
  String isidataWaktu2 = 'kedua';
  String isidataWaktu3 = 'ketiga';

  String tampilanYangSesuai =
      'Tidak ada data waktu yang cocok.'; // Default value

  if (currentTimeInMinutes >= startTime1 && currentTimeInMinutes <= endTime1) {
    tampilanYangSesuai = isidataWaktu1;
  } else if (currentTimeInMinutes >= startTime2 &&
      currentTimeInMinutes <= endTime2) {
    tampilanYangSesuai = isidataWaktu2;
  } else if (currentTimeInMinutes >= startTime3 &&
      currentTimeInMinutes <= endTime3) {
    tampilanYangSesuai = isidataWaktu3;
  }

  print('Waktu sekarang: $currentHour:$currentMinute');
  print('Tampilan yang sesuai: $tampilanYangSesuai');

  // Di sini Anda bisa memperbarui UI berdasarkan nilai tampilanYangSesuai
  // Contoh: setState(() { _dataYangDitampilkan = tampilanYangSesuai; });
}

//*** 2. Menggunakan Objek DateTime dan isAfter/isBefore
//Ini adalah cara yang lebih modern dan direkomendasikan
//karena DateTime dirancang untuk perbandingan waktu.
//Anda bisa membuat objek DateTime untuk waktu mulai dan
//akhir setiap rentang.
// */
void tampilkanSesuaiWaktuDenganDateTime() {
  DateTime now = DateTime.now();

  // Penting: Pastikan Anda hanya membandingkan jam dan menit saja
  // atau pastikan rentang waktu yang Anda definisikan adalah untuk hari yang sama.
  // Untuk perbandingan waktu harian saja (tanpa mempertimbangkan tanggal):
  DateTime timeOnly(int hour, int minute) {
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // Definisikan rentang waktu menggunakan objek DateTime
  DateTime start1 = timeOnly(1, 0); // 01.00
  DateTime end1 = timeOnly(1, 30); // 01.30

  DateTime start2 = timeOnly(1, 31); // 01.31
  DateTime end2 = timeOnly(2, 0); // 02.00

  DateTime start3 = timeOnly(2, 1); // 02.01
  DateTime end3 = timeOnly(4, 30); // 02.30

  String isidataWaktu1 = 'pertama';
  String isidataWaktu2 = 'kedua';
  String isidataWaktu3 = 'ketiga';

  String tampilanYangSesuai = 'Tidak ada data waktu yang cocok.';

  // Perbandingan menggunakan isAfter dan isBefore
  if ((now.isAfter(start1) || now.isAtSameMomentAs(start1)) &&
      (now.isBefore(end1) || now.isAtSameMomentAs(end1))) {
    tampilanYangSesuai = isidataWaktu1;
  } else if ((now.isAfter(start2) || now.isAtSameMomentAs(start2)) &&
      (now.isBefore(end2) || now.isAtSameMomentAs(end2))) {
    tampilanYangSesuai = isidataWaktu2;
  } else if ((now.isAfter(start3) || now.isAtSameMomentAs(start3)) &&
      (now.isBefore(end3) || now.isAtSameMomentAs(end3))) {
    tampilanYangSesuai = isidataWaktu3;
  }

  // print('Waktu sekarang: ${now.hour}:${now.minute}');
  // print('Tampilan yang sesuai: $tampilanYangSesuai');
}

