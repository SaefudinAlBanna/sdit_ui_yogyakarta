// File: lib/app/modules/rapor_terpadu/controllers/rapor_terpadu_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../models/atp_model.dart';
import '../../../models/rapor_siswa_model.dart';
import '../../../models/rapor_terpadu_model.dart';
import '../../../models/rekap_absensi_model.dart';
import '../../../models/siswa_model.dart';
import '../../../services/rapor_pdf_service.dart';
import '../../home/controllers/home_controller.dart';

class RaporTerpaduController extends GetxController {
  // --- DEPENDENSI ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HomeController homeC = Get.find<HomeController>();

  // --- DATA INPUT ---
  late SiswaModel siswa; // Diterima dari argumen

  // --- STATE UTAMA ---
  final RxBool isLoading = true.obs;
  // State untuk menampung hasil akhir yang akan ditampilkan
  final Rxn<RaporTerpaduModel> raporLengkap = Rxn<RaporTerpaduModel>();

  @override
  void onInit() {
    super.onInit();
    // Ambil data siswa dari argumen
    if (Get.arguments is SiswaModel) {
      siswa = Get.arguments as SiswaModel;
      generateRaporLengkap(); // Mulai proses
    } else {
      // Handle error jika data siswa tidak dikirim
      isLoading.value = false;
      Get.snackbar("Error Kritis", "Data siswa tidak valid untuk membuat rapor.");
    }
  }

  Future<Map<String, String>> _fetchDataPejabat() async {
    String waliKelas = 'Belum Diatur';
    String kepalaSekolah = 'Belum Diatur';
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      
      // Ambil nama Wali Kelas dari dokumen kelas
      final kelasDoc = await _firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(siswa.idKelas)
          .get();
      if (kelasDoc.exists) {
        waliKelas = kelasDoc.data()?['walikelas'] ?? 'N/A';
      }

      // Ambil nama Kepala Sekolah dari koleksi pegawai
      final kepsekSnapshot = await _firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('pegawai')
          .where('role', isEqualTo: 'Kepala Sekolah')
          .limit(1)
          .get();
      if (kepsekSnapshot.docs.isNotEmpty) {
        kepalaSekolah = kepsekSnapshot.docs.first.data()['nama'] ?? 'N/A';
      }
    } catch (e) {
      print("Error di _fetchDataPejabat: $e");
    }
    return {'waliKelas': waliKelas, 'kepalaSekolah': kepalaSekolah};
  }

  Future<void> cetakRapor() async {
    if (raporLengkap.value != null) {
      // Panggil service kita dan kirim data yang sudah matang
      await RaporPdfService.generateAndPrintPdf(raporLengkap.value!);
    } else {
      Get.snackbar("Gagal", "Data rapor belum siap untuk dicetak.");
    }
  }

  /// Fungsi utama yang menjadi sutradara untuk mengumpulkan semua data.
  Future<void> generateRaporLengkap() async {
    isLoading.value = true;
    try {
      // Panggil semua fungsi fetcher secara paralel untuk efisiensi
      final results = await Future.wait([
        _fetchDataAkademik(),
        _fetchDataEkskul(),
        _fetchDataHalaqoh(),
        _fetchDataAbsensi(),
        _fetchCatatanWaliKelas(),
        _fetchDataPejabat(),
      ]);

      final Map<String, String> dataPejabat = results[5] as Map<String, String>;

      // Rakit semua hasil menjadi satu "super-model"
      raporLengkap.value = RaporTerpaduModel(
        dataSiswa: siswa,
        tahunAjaran: homeC.idTahunAjaran.value!.replaceAll('-', '/'),
        semester: homeC.semesterAktifId.value,
        dataAkademik: results[0] as List<RaporMapelModel>,
        dataEkskul: results[1] as List<RaporEkskulItem>,
        dataHalaqoh: results[2] as List<RaporHalaqohItem>,
        dataAbsensi: results[3] as RekapAbsensiSiswaModel,
        catatanWaliKelas: results[4] as String,
        namaWaliKelas: dataPejabat['waliKelas']!,
        namaKepalaSekolah: dataPejabat['kepalaSekolah']!,
      );

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat data rapor lengkap: $e");
    } finally {
      isLoading.value = false;
    }
  }
  
  // --- KERANGKA FUNGSI-FUNGSI FETCHER ---
  
  Future<List<RaporMapelModel>> _fetchDataAkademik() async {
    // Mengadaptasi logika dari RaporSiswaController
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final semesterAktif = homeC.semesterAktifId.value;

      // 1. Ambil semua mata pelajaran yang diikuti siswa
      final mapelSnapshot = await _firestore.collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(siswa.idKelas)
          .collection('semester').doc(semesterAktif)
          .collection('daftarsiswa').doc(siswa.nisn)
          .collection('matapelajaran').get();

      if (mapelSnapshot.docs.isEmpty) {
        return []; // Kembalikan list kosong jika tidak ada mapel
      }

      List<RaporMapelModel> tempDataRapor = [];

      // 2. Proses setiap mata pelajaran
      for (var mapelDoc in mapelSnapshot.docs) {
        final namaMapel = mapelDoc.id;
        final dataMapelSiswa = mapelDoc.data();
        
        final atpModel = await _findAtpForMapel(namaMapel);
        final namaGuru = await _findGuruPengajar(namaMapel);

        List<UnitCapaian> daftarUnitCapaian = [];
        if (atpModel != null) {
          final capaianSiswa = Map<String, String>.from(dataMapelSiswa['capaian_tp'] ?? {});
          
          for (var unit in atpModel.unitPembelajaran) {
            List<String> tpTercapai = [];
            List<String> tpPerluBimbingan = [];

            for (var tp in unit.tujuanPembelajaran) {
              if (capaianSiswa[tp] == 'Tercapai') {
                tpTercapai.add(tp);
              } else if (capaianSiswa[tp] == 'Perlu Bimbingan') {
                tpPerluBimbingan.add(tp);
              }
            }
            
            if (tpTercapai.isNotEmpty || tpPerluBimbingan.isNotEmpty) {
              daftarUnitCapaian.add(UnitCapaian(
                namaUnit: unit.lingkupMateri,
                tpTercapai: tpTercapai,
                tpPerluBimbingan: tpPerluBimbingan,
              ));
            }
          }
        }

        final String? deskripsiManual = dataMapelSiswa['deskripsi_capaian'];
        
        tempDataRapor.add(RaporMapelModel(
          namaMapel: namaMapel,
          guruPengajar: namaGuru,
          nilaiAkhir: (dataMapelSiswa['nilai_akhir'] as num?)?.toDouble(), // Konversi aman
          daftarCapaian: daftarUnitCapaian,
          deskripsiCapaian: deskripsiManual,
        ));
      }
      
      return tempDataRapor; // 3. Kembalikan hasilnya

    } catch (e) {
      print("Error di _fetchDataAkademik: $e");
      // Jika terjadi error, kembalikan list kosong agar aplikasi tidak crash
      return [];
    }
  }

  Future<List<RaporEkskulItem>> _fetchDataEkskul() async {
    try {
      final idSekolah = homeC.idSekolah;
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final semesterField = "nilaiSemester${homeC.semesterAktifId.value}";

      // 1. Ambil daftar ekskul yang diikuti siswa
      final ekskulDiikutiSnapshot = await _firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('siswa').doc(siswa.nisn)
          .collection('ekskul_diikuti')
          .where('idTahunAjaran', isEqualTo: idTahunAjaran)
          .get();
      
      if (ekskulDiikutiSnapshot.docs.isEmpty) return [];

      List<RaporEkskulItem> hasilEkskul = [];

      // 2. Loop untuk setiap ekskul
      for (final doc in ekskulDiikutiSnapshot.docs) {
        final idInstanceEkskul = doc.id;
        
        // Ambil info nama master
        final masterRef = doc.data()['masterEkskulRef'];
        final masterDoc = await _firestore.collection('master_ekskul').doc(masterRef).get();
        final namaMaster = masterDoc.data()?['namaMaster'] ?? 'Ekskul';
        
        // 3. Ambil data nilai dari dokumen anggota
        final nilaiDoc = await _firestore
            .collection('Sekolah').doc(idSekolah)
            .collection('tahunajaran').doc(idTahunAjaran)
            .collection('ekstrakurikuler').doc(idInstanceEkskul)
            .collection('anggota').doc(siswa.nisn)
            .get();
        
        String? predikat;
        String? keterangan;
        // Cek jika dokumen nilai ada DAN field semester yang benar ada
        if (nilaiDoc.exists && nilaiDoc.data()!.containsKey(semesterField)) {
          final nilaiData = nilaiDoc.data()![semesterField];
          predikat = nilaiData['predikat'];
          keterangan = nilaiData['keterangan'];
        }

        hasilEkskul.add(RaporEkskulItem(
          namaEkskul: namaMaster,
          predikat: predikat,
          keterangan: keterangan,
        ));
      }
      return hasilEkskul;
    } catch (e) {
      print("Error di _fetchDataEkskul: $e");
      return [];
    }
  }

  Future<List<RaporHalaqohItem>> _fetchDataHalaqoh() async {
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final semesterAktif = homeC.semesterAktifId.value;

      // 1. Path langsung ke dokumen siswa di dalam struktur kelas tahun ajaran
      // Ini adalah lokasi di mana kita sepakat untuk menyimpan nilai akhir Halaqoh
      final siswaDocRef = _firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(siswa.idKelas)
          .collection('semester').doc(semesterAktif)
          .collection('daftarsiswa').doc(siswa.nisn);
          
      final siswaDoc = await siswaDocRef.get();
      
      if (!siswaDoc.exists) {
        // Jika dokumen siswa di semester ini tidak ada, tidak mungkin ada nilai halaqoh
        return [];
      }

      final dataSiswa = siswaDoc.data()!;
      List<RaporHalaqohItem> hasilHalaqoh = [];

      // 2. Cek dan proses data Tahsin
      if (dataSiswa.containsKey('nilai_tahsin')) {
        final dataTahsin = dataSiswa['nilai_tahsin'] as Map<String, dynamic>?;
        if (dataTahsin != null) {
          hasilHalaqoh.add(RaporHalaqohItem(
            jenis: 'Tahsin',
            nilaiAkhir: (dataTahsin['nilaiAkhir'] as num?)?.toInt(),
            keterangan: dataTahsin['deskripsi'],
          ));
        }
      }
      
      // 3. Cek dan proses data Tahfidz
      if (dataSiswa.containsKey('nilai_tahfidz')) {
        final dataTahfidz = dataSiswa['nilai_tahfidz'] as Map<String, dynamic>?;
        if (dataTahfidz != null) {
          hasilHalaqoh.add(RaporHalaqohItem(
            jenis: 'Tahfidz',
            nilaiAkhir: (dataTahfidz['nilaiAkhir'] as num?)?.toInt(),
            keterangan: dataTahfidz['deskripsi'],
          ));
        }
      }

      return hasilHalaqoh;

    } catch (e) {
      print("Error di _fetchDataHalaqoh: $e");
      return [];
    }
  }

  Future<RekapAbsensiSiswaModel> _fetchDataAbsensi() async {
    // Siapkan nilai default jika terjadi error
    final defaultAbsensi = RekapAbsensiSiswaModel(
        idSiswa: siswa.nisn,
        namaSiswa: siswa.nama,
        sakitCount: 0,
        izinCount: 0,
        alfaCount: 0);
        
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final semesterAktif = homeC.semesterAktifId.value;

      // 1. Tentukan rentang tanggal semester (ini adalah pendekatan, bisa disempurnakan)
      // Asumsi Semester 1: Juli - Desember, Semester 2: Januari - Juni
      final tahun = int.parse(idTahunAjaran.split('-')[0]);
      final DateTime tanggalMulai;
      final DateTime tanggalSelesai;

      if (semesterAktif == '1') {
        tanggalMulai = DateTime(tahun, 7, 1);
        tanggalSelesai = DateTime(tahun, 12, 31, 23, 59, 59);
      } else {
        tanggalMulai = DateTime(tahun + 1, 1, 1);
        tanggalSelesai = DateTime(tahun + 1, 6, 30, 23, 59, 59);
      }
      
      // 2. Lakukan query ke koleksi absensi
      final absensiSnapshot = await _firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(siswa.idKelas)
          .collection('semester').doc(semesterAktif)
          .collection('absensi')
          .where('tanggal', isGreaterThanOrEqualTo: tanggalMulai)
          .where('tanggal', isLessThanOrEqualTo: tanggalSelesai)
          .get();

      // 3. Proses hasil query di sisi klien
      int sakit = 0;
      int izin = 0;
      int alfa = 0;

      for (final doc in absensiSnapshot.docs) {
        final dataSiswa = doc.data()['siswa'] as Map<String, dynamic>? ?? {};
        // Cek status absensi untuk siswa spesifik kita
        final statusSiswa = dataSiswa[siswa.nisn];
        if (statusSiswa != null) {
          if (statusSiswa == 'Sakit') sakit++;
          if (statusSiswa == 'Izin') izin++;
          if (statusSiswa == 'Alfa') alfa++;
        }
      }
      
      // 4. Kembalikan hasilnya dalam bentuk model
      return RekapAbsensiSiswaModel(
        idSiswa: siswa.nisn,
        namaSiswa: siswa.nama,
        sakitCount: sakit,
        izinCount: izin,
        alfaCount: alfa
      );

    } catch (e) {
      print("Error di _fetchDataAbsensi: $e");
      // Jika error, kembalikan nilai default agar aplikasi tidak crash
      return defaultAbsensi;
    }
  }

  Future<String> _fetchCatatanWaliKelas() async {
    try {
      final idTahunAjaran = homeC.idTahunAjaran.value!;
      final semesterAktif = homeC.semesterAktifId.value;
      final siswaDocRef = _firestore
          .collection('Sekolah').doc(homeC.idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelastahunajaran').doc(siswa.idKelas)
          .collection('semester').doc(semesterAktif)
          .collection('daftarsiswa').doc(siswa.nisn);

      final doc = await siswaDocRef.get();
      if (doc.exists) {
        // Ambil catatan dari field 'catatan_wali_kelas', jika tidak ada, beri string kosong.
        return doc.data()?['catatan_wali_kelas'] ?? "Belum ada catatan dari Wali Kelas.";
      }
      return "Belum ada catatan dari Wali Kelas.";
    } catch (e) {
      print("Error di _fetchCatatanWaliKelas: $e");
      return "Gagal memuat catatan.";
    }
  }

  //APABILA CATATAN WALIKELAS STATIS
  //=================================
  // Future<String> _fetchCatatanWaliKelas() async {
  //   // Langsung kembalikan teks placeholder.
  //   // Ini adalah solusi sementara yang fungsional.
  //   return "Tingkatkan terus semangat belajarmu, raih prestasi, dan jangan pernah berhenti menjadi pribadi yang lebih baik. Tetap semangat!";
  // }

  // --- HELPER DARI RaporSiswaController ---
  Future<AtpModel?> _findAtpForMapel(String namaMapel) async {
    final kelasAngka = int.tryParse(siswa.idKelas.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    
    final snapshot = await _firestore
        .collection('Sekolah').doc(homeC.idSekolah).collection('atp')
        .where('idTahunAjaran', isEqualTo: homeC.idTahunAjaran.value!)
        .where('namaMapel', isEqualTo: namaMapel)
        .where('kelas', isEqualTo: kelasAngka)
        .limit(1).get();
        
    if (snapshot.docs.isNotEmpty) {
      return AtpModel.fromJson(snapshot.docs.first.data());
    }
    return null;
  }

  Future<String> _findGuruPengajar(String namaMapel) async {
    final doc = await _firestore
        .collection('Sekolah').doc(homeC.idSekolah)
        .collection('tahunajaran').doc(homeC.idTahunAjaran.value!)
        .collection('penugasan').doc(siswa.idKelas)
        .collection('matapelajaran').doc(namaMapel).get();
        
    if (doc.exists) {
      return doc.data()?['guru'] ?? 'N/A';
    }
    return 'N/A';
  }
}