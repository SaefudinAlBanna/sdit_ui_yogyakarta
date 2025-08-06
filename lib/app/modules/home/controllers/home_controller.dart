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
  final RxMap<String, dynamic> infoUser = <String, dynamic>{}.obs;
  
  // Variabel ini akan diisi oleh _fetchKelasAktif
  List<DocumentSnapshot<Map<String, dynamic>>> kelasAktifList = []; 
  
  List<Map<String, dynamic>> jadwalPelajaranList = [];
  // final TextEditingController kelasSiswaC = TextEditingController();
  final TextEditingController tahunAjaranBaruC = TextEditingController();
  final PersistentTabController tabController = PersistentTabController(initialIndex: 0);
  // final List<Widget> navBarScreens = [ HomePage(), MarketplacePage(), ProfilePage() ];

  final RxList<Map<String, dynamic>> kelompokMengajiDiajar = <Map<String, dynamic>>[].obs;

  final RxList<Map<String, dynamic>> ekskulDiampuPengguna = <Map<String, dynamic>>[].obs;

  bool get isPembina => ekskulDiampuPengguna.isNotEmpty;


  // --- (Getter untuk TUGAS TAMBAHAN) ---
  bool get isInKurikulumTeam => userTugas.contains('Kurikulum');
  bool get isInKesiswaanTeam => userTugas.contains('Kesiswaan');
  // bool get canManageHalaqoh => userTugas.contains('Koordinator Halaqoh'); // Koordinator Halaqoh kini adalah tugas
  
  // stelah ada tugas -------------------------
  bool get isDalang => auth.currentUser?.email == 'saefudin.skom@gmail.com'; 
  bool get kapten => auth.currentUser?.email == 'hidayyat@gmail.com';
  bool get isKepsek => userRole.value == 'Kepala Sekolah';
  bool get isAdmin => userRole.value == 'Admin';
  bool get isAdminKepsek => userRole.value == 'Admin' || userRole.value == 'Kepala Sekolah'; 
  bool get canManageTahsin => userTugas.contains('Koordinator Halaqoh') || isDalang;
  bool get informasiKelas => userRole.value == 'Guru Kelas' || userRole.value == 'Guru Mapel' || userTugas.contains('Guru Mapel') || isAdminKepsek || kapten || isDalang;
  bool get jurnalHarian => userRole.value == 'Guru Kelas' || userRole.value == 'Guru Mapel';
  bool get walikelas => userRole.value == 'Guru Kelas';
  bool get guruBK => userRole.value == 'Guru BK';
  // bool get tahfidzKelas => userRole.value == 'Guru Kelas' || userTugas.contains('Pendamping Tahfidz');
  bool get tahfidzKelas => walikelas || tugasPendampingKelasId.value != null || tugasPendampingKelasId.value != null;
  bool get isPimpinan => isAdminKepsek && !walikelas && tugasPendampingKelasId.value == null;
  bool get canEditOrDeleteHalaqoh => kelasTahsin || canManageTahsin || kapten; 
  bool get tambahHalaqohFase => canManageTahsin || kapten;
  
  // bool get kelasTahsin => userRole.value == 'Pengampu' || userTugas.contains('Pengampu');
  bool get kelasTahsin => kelompokMengajiDiajar.isNotEmpty;

  bool get isPenggantiHariIni {
    return kelompokMengajiDiajar.any((kelompok) => kelompok['isPengganti'] == true);
  }

  List<Map<String, dynamic>> get kelompokPermanen {
    return kelompokMengajiDiajar.where((k) => k['isPengganti'] != true).toList();
  }

  List<Map<String, dynamic>> get kelompokPenggantiHariIni {
    return kelompokMengajiDiajar.where((k) => k['isPengganti'] == true).toList();
  }
  

  List<String> get rolePenggantiTahsin {
    return [
      'Guru Kelas',
      'Guru Mapel',
      'Pengampu',
      // Tambahkan role lain di sini jika diperlukan di masa depan
    ];
  }

  List<String> get tugasPenggantiTahsin {
    return [
      'Pengampu', // Jika ada yang punya tugas sebagai 'Pengampu'
      // Tambahkan tugas lain di sini jika perlu
    ];
  }
  

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
    // kelasSiswaC.dispose();
    tahunAjaranBaruC.dispose();
    super.onClose();
  }
  

  Future<void> fetchUserRoleAndTugas() async {
    try {
      final userDoc = await firestore.collection('Sekolah').doc(idSekolah).collection('pegawai').doc(idUser).get();
      
      // Ambil data permanen (role, tugas, dll) dari dokumen pegawai
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        infoUser.value = data;
        userRole.value = data['role'] as String?;
        final tugasData = data['tugas'];
        if (tugasData is List) {
          userTugas.assignAll(List<String>.from(tugasData));
        } else {
          userTugas.clear();
        }
        tugasPendampingKelasId.value = data['tugas_pendamping_tahfidz'] as String?;

         if (data.containsKey('ekskulYangDiampu')) {
          ekskulDiampuPengguna.assignAll(List<Map<String, dynamic>>.from(data['ekskulYangDiampu']));
        } else {
          ekskulDiampuPengguna.clear();
        }
      }

      // --- LOGIKA PENGGABUNGAN DATA HALAQOH DIMULAI ---

      // 1. Ambil SEMUA kelompok PERMANEN yang diajar (dari "shortcut" di dokumen pegawai)
      final List<Map<String, dynamic>> kelompokPermanen = [];
      if (idTahunAjaran.value != null) {
        final kelompokSnapshot = await userDoc.reference
            .collection('tahunajarankelompok').doc(idTahunAjaran.value!)
            .collection('semester').doc(semesterAktifId.value)
            .collection('kelompokmengaji').get();
        
        if (kelompokSnapshot.docs.isNotEmpty) {
          kelompokPermanen.addAll(kelompokSnapshot.docs.map((doc) => doc.data()));
        }
      }

      // 2. Lakukan query collectionGroup untuk mencari TUGAS PENGGANTI HARI INI
      final tanggalHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final sesiPenggantiSnapshot = await firestore.collectionGroup('sesi_pengganti')
          .where('tanggal', isEqualTo: tanggalHariIni)
          .where('uid_pengganti', isEqualTo: idUser) // Cari di mana SAYA adalah penggantinya
          .get();
      
      final List<Map<String, dynamic>> kelompokPengganti = [];
      if (sesiPenggantiSnapshot.docs.isNotEmpty) {
        print("INFO: Ditemukan ${sesiPenggantiSnapshot.docs.length} tugas sebagai pengganti hari ini.");
        for (var doc in sesiPenggantiSnapshot.docs) {
          final dataPengganti = doc.data();
          // Rakit ulang data kelompok agar strukturnya sama, dengan penanda khusus
          kelompokPengganti.add({
            'fase': dataPengganti['fase'],
            'tempatmengaji': dataPengganti['namaTempat'], // Standarisasi nama kunci
            'idpengampu': dataPengganti['uid_pengganti'], // ID saya sebagai pengganti
            'namapengampu': dataPengganti['nama_pengganti'],
            'idPengampuAsli': dataPengganti['uid_pengampu_asli'], 
            'namaPengampuAsli': dataPengganti['nama_pengampu_asli'],
            'isPengganti': true, // Penanda penting bahwa ini adalah sesi pengganti
          });
        }
      }

      // 3. Gabungkan keduanya dan perbarui state utama.
      // State ini akan menjadi satu-satunya sumber kebenaran untuk hak akses Halaqoh.
      kelompokMengajiDiajar.assignAll([...kelompokPermanen, ...kelompokPengganti]);
      
      print("INFO: Total ${kelompokMengajiDiajar.length} kelompok halaqoh ditemukan (permanen + pengganti).");
      
    } catch (e) {
      print("Gagal mengambil role & tugas & sesi pengganti: $e");
      // Jika terjadi error, pastikan semua state bersih
      userRole.value = null;
      userTugas.clear();
      kelompokMengajiDiajar.clear();
      ekskulDiampuPengguna.clear();
    }
  }


 void _listenToConfigChanges() {
  if (idTahunAjaran == null) return;

  final docRef = firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran.value!);

  _configListener?.cancel(); 

  _configListener = docRef.snapshots().listen((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()!;

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

    }
  }, onError: (error) {
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
        // _fetchUserRole(),
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
      return;
    }
    try {
      final doc = await firestore.collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran.value!).get();
          
      if (doc.exists && doc.data() != null) {
        // Ambil nilai dari field 'semesterAktif', jika tidak ada, gunakan '1' sebagai fallback.
        semesterAktifId.value = doc.data()!['semesterAktif'] ?? '1';
      } else {
        semesterAktifId.value = '1';
      }
    } catch (e) {
      // Jika terjadi error, gunakan nilai default agar aplikasi tidak crash.
      semesterAktifId.value = '1';
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
    }
    
    // Kembalikan Map dengan format yang benar
    return {'id': doc.id, 'start': startTime, 'end': endTime};
  }).toList();

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

  Stream<JurnalModel?> streamJurnalDetail(String idKelas) {
      final now = DateTime.now();
      // [PERBAIKAN KUNCI] Dapatkan waktu saat ini dalam format HH:mm untuk perbandingan
      final String jamSekarang = DateFormat('HH:mm').format(now); 
      final String namaHari = DateFormat('EEEE', 'id_ID').format(now);
      final String tanggalStr = DateFormat('yyyy-MM-dd').format(now);

      // 1. HIRARKI #1: Cek Hari Libur
      if (!isHariSekolahAktif(now)) {
        return Stream.value(JurnalModel(
          materipelajaran: pesanLiburKustom.value.isNotEmpty ? pesanLiburKustom.value : "Selamat menikmati hari libur.",
          namapenginput: "Info Sekolah",
          jampelajaran: "Hari Libur"
        ));
      }

      return Stream.fromFuture((() async {
        try {
          final idTahunAjaran = this.idTahunAjaran.value!;
          final semester = semesterAktifId.value;

          // 2. HIRARKI #2: Cek Kegiatan Global
          final kegiatanGlobalSnap = await firestore.collection('kegiatan_global')
              .where('hari', whereIn: [namaHari, 'Setiap Hari Kerja']).get();
          for (var doc in kegiatanGlobalSnap.docs) {
            final data = doc.data();
            final mulai = data['jamMulai'] as String;    // Contoh: "20:00"
            final selesai = data['jamSelesai'] as String;  // Contoh: "20:36"

            // [PERBAIKAN KUNCI] Bandingkan jamSekarang dengan rentang dari Firestore
            if (jamSekarang.compareTo(mulai) >= 0 && jamSekarang.compareTo(selesai) < 0) {
              if (data['tipe'] == 'PESAN_TEMPLATE') {
                return JurnalModel(materipelajaran: data['templatePesan'], namapenginput: data['namaKegiatan']);
              }
              return JurnalModel(materipelajaran: data['namaKegiatan'], namapenginput: "Kegiatan Sekolah");
            }
          }

          // 3. HIRARKI #3: Cek Jadwal KBM & Pengganti
          final jadwalKelasSnap = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('jadwalkelas').doc(idKelas).get();
          if (jadwalKelasSnap.exists && jadwalKelasSnap.data()!.containsKey(namaHari)) {
            final jadwalHari = jadwalKelasSnap.data()![namaHari] as List;
            // Cari slot jadwal yang sesuai dengan jam saat ini
            final slot = jadwalHari.firstWhere((s) {
              final parts = (s['jam'] as String).split('-');
              return jamSekarang.compareTo(parts[0]) >= 0 && jamSekarang.compareTo(parts[1]) < 0;
            }, orElse: () => null);

            if (slot != null) {
              String jamSlot = slot['jam'];

              // Cek apakah ada pengganti untuk slot ini
              final penggantiSnap = await firestore.collection('sesi_pengganti_kbm').where('idKelas', isEqualTo: idKelas).where('tanggal', isEqualTo: tanggalStr).where('jam', isEqualTo: jamSlot).limit(1).get();

              String guruBertugasNama = penggantiSnap.docs.isNotEmpty 
                  ? penggantiSnap.docs.first.data()['namaGuruPengganti'] 
                  : (slot['listNamaGuru'] as List).join(', ');

              // 4. HIRARKI #4: Cek apakah jurnal sudah diisi
              final jurnalSnap = await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idTahunAjaran).collection('kelastahunajaran').doc(idKelas).collection('semester').doc(semester).collection('tanggaljurnal').doc(DateFormat.yMd('id_ID').format(now).replaceAll('/', '-')).collection('jurnalkelas').doc(jamSlot).get();

              if (jurnalSnap.exists) {
                return JurnalModel.fromFirestore(jurnalSnap.data()!);
              } else {
                return JurnalModel(
                  materipelajaran: slot['namaMapel'],
                  namapenginput: guruBertugasNama,
                  catatanjurnal: penggantiSnap.docs.isNotEmpty ? "(Menggantikan)" : "Jurnal belum diisi",
                  jampelajaran: jamSlot, // Tampilkan rentang jamnya
                );
              }
            }
          }

          // 5. HIRARKI TERAKHIR: Di luar jam KBM
          return JurnalModel(
            materipelajaran: pesanAkhirSekolahKustom.value.isNotEmpty ? pesanAkhirSekolahKustom.value : "Kegiatan belajar telah usai.",
            namapenginput: "Info Sekolah",
            jampelajaran: "Jam Sekolah Usai",
          );

        } catch (e) {
          return JurnalModel(materipelajaran: "Error memuat data jurnal.", namapenginput: e.toString());
        }
      })());
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

  Future<List<String>> getDataKelasYangDiajar() async {
    // Ambil data global yang sudah ada di controller ini
    final idTahunAjaranValue = idTahunAjaran.value;
    final semesterAktif = semesterAktifId.value;

    if (idTahunAjaranValue == null) {
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
          
      for (var docSnapshot in snapshot.docs) {
        kelasList.add(docSnapshot.id);
      }
      
      kelasList.sort();
      
    } catch (e) {
      debugPrint("   -> Query GAGAL dengan error: $e");
    }
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
}
