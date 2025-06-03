
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DaftarHalaqohController extends GetxController {
  
  var currentPengampuData = Get.arguments;

  //  late Map<String, dynamic> currentPengampuData;

  RxBool isLoading = false.obs;

  TextEditingController pengampuC = TextEditingController();
  TextEditingController kelasSiswaC = TextEditingController();
  TextEditingController alasanC = TextEditingController();
  TextEditingController umiC = TextEditingController();
  TextEditingController umidrawerC = TextEditingController();

  // FirebaseFirestore firestore = FirebaseFirestore.instance;
  // String idUser = FirebaseAuth.instance.currentUser!.uid;
  // String idSekolah = '20404148'; // Harap pastikan ini benar atau dinamis jika perlu
  // String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? _idUser; // Jadikan nullable dan isi di onInit
  String idSekolah = '20404148';
  String? _emailAdmin; // Jadikan nullable dan isi di onInit

  // Properti untuk diakses dari luar, pastikan sudah diinisialisasi
  String get idUser => _idUser ?? '';
  String get emailAdmin => _emailAdmin ?? '';

  @override
  void onInit() {
    super.onInit();
    // Ambil argumen ketika controller diinisialisasi
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      currentPengampuData = arguments;
      print("Controller initialized with data: $currentPengampuData");
    } else {
      // Handle kasus jika argumen tidak ada atau tidak sesuai, mungkin lempar error atau set default
      print("Error: Arguments not found or invalid for DaftarHalaqohController");
      currentPengampuData = {}; // Atau throw error
      // Get.offAllNamed(Routes.HOME); // Contoh fallback
    }

    // Inisialisasi user data
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _idUser = currentUser.uid;
      _emailAdmin = currentUser.email;
    } else {
      // Handle jika user tidak login, mungkin redirect ke login
      print("Error: User not logged in.");
    }
  }

  Future<String> getTahunAjaranTerakhir() async {
    // ... (kode Anda sudah benar)
    CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran');
    QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
        await colTahunAjaran.orderBy('namatahunajaran').get(); // Urutkan untuk memastikan yang terakhir benar
    if (snapshotTahunAjaran.docs.isEmpty) {
      throw Exception("Tidak ada tahun ajaran ditemukan");
    }
    String tahunAjaranTerakhir =
        snapshotTahunAjaran.docs.last.data()['namatahunajaran'];
    return tahunAjaranTerakhir;
  }

  Future<List<String>> getDataKelasYangAda() async {
    // ... (kode Anda sudah benar)
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> kelasList = [];
    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .where('fase', isEqualTo: currentPengampuData['fase'])
        .get()
        .then((querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            kelasList.add(docSnapshot.id);
          }
        });
    return kelasList;
  }

  Future<List<String>> getDataUmi() async {
    // ... (kode Anda sudah benar)
     List<String> umiList = [
      'Umi', 
      'AlQuran',
      'Jilid 1',
      'Jilid 2',
      'Jilid 3',
      'Jilid 4',
      'Jilid 5',
      'Jilid 6',
      ];
    return umiList;
  }

  Future<void> updateUmi(String nisnSiswa) async {
    // ... (kode Anda sepertinya OK, tapi pastikan 'currentPengampuData' punya semua field yang dibutuhkan)
    // Pastikan idTahunAjaran diambil dengan benar
    try {
      String tahunajaranya = await getTahunAjaranTerakhir();
      String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

      if (umiC.text.isEmpty) {
        Get.snackbar("Peringatan", "Kategori Umi belum dipilih.");
        return;
      }

      WriteBatch batch = firestore.batch();

      // Path 1
      DocumentReference ref1 = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(currentPengampuData['fase'])
          .collection('pengampu')
          .doc(currentPengampuData['namapengampu'])
          .collection('tempat')
          .doc(currentPengampuData['tempatmengaji'])
          .collection('daftarsiswa')
          .doc(nisnSiswa);
      batch.update(ref1, {'ummi': umiC.text});

      // Path 2
      DocumentReference ref2 = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(currentPengampuData['fase'])
          .collection('pengampu')
          .doc(currentPengampuData['namapengampu'])
          .collection('tempat')
          .doc(currentPengampuData['tempatmengaji'])
          .collection('semester')
          .doc('Semester I'); // Asumsi Semester I, pastikan ini dinamis jika perlu
      batch.update(ref2, {'ummi': umiC.text});
      
      // Path 3 (jika ada path nilai spesifik per semester di daftarsiswa)
      DocumentReference ref3 = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(currentPengampuData['fase'])
          .collection('pengampu')
          .doc(currentPengampuData['namapengampu'])
          .collection('tempat')
          .doc(currentPengampuData['tempatmengaji'])
          .collection('daftarsiswa')
          .doc(nisnSiswa)
          .collection('semester')
          .doc('Semester I'); // Asumsi Semester I
       batch.update(ref3, {'ummi': umiC.text});


      await batch.commit();
      Get.back();
      Get.snackbar("Berhasil", "Umi Berhasil diperbarui");
      umiC.clear();

    } catch (e) {
      Get.snackbar("Error", "Gagal update Umi: ${e.toString()}");
    }
  }


  Future<void> updateUmiDrawer(String nisnSiswa) async {
    // ... (serupa dengan updateUmi, gunakan batch dan error handling)
     try {
      String tahunajaranya = await getTahunAjaranTerakhir();
      String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

      if (umidrawerC.text.isEmpty) {
        Get.snackbar("Peringatan", "Kategori Umi belum dipilih.");
        return;
      }
      WriteBatch batch = firestore.batch();

      DocumentReference ref1 = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(currentPengampuData['fase'])
          .collection('pengampu')
          .doc(currentPengampuData['namapengampu'])
          .collection('tempat')
          .doc(currentPengampuData['tempatmengaji'])
          .collection('daftarsiswa')
          .doc(nisnSiswa);
      batch.update(ref1, {'ummi': umidrawerC.text});
      
      DocumentReference ref2 = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(currentPengampuData['fase'])
          .collection('pengampu')
          .doc(currentPengampuData['namapengampu'])
          .collection('tempat')
          .doc(currentPengampuData['tempatmengaji'])
          .collection('semester')
          .doc('Semester I'); 
      batch.update(ref2, {'ummi': umidrawerC.text});

      DocumentReference ref3 = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(currentPengampuData['fase'])
          .collection('pengampu')
          .doc(currentPengampuData['namapengampu'])
          .collection('tempat')
          .doc(currentPengampuData['tempatmengaji'])
          .collection('daftarsiswa')
          .doc(nisnSiswa)
          .collection('semester')
          .doc('Semester I');
       batch.update(ref3, {'ummi': umidrawerC.text});


      await batch.commit();
      // Get.back(); // Mungkin tidak perlu Get.back() jika ini dari bottomsheet yang auto close
      Get.snackbar("Berhasil", "Umi Berhasil diperbarui untuk siswa terpilih.");
      // umidrawerC.clear(); // Jangan clear jika mau dipakai lagi
    } catch (e) {
      Get.snackbar("Error", "Gagal update Umi: ${e.toString()}");
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataSiswaStreamBaru() async* {
    // ... (kode Anda sudah benar)
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(kelasSiswaC.text)
        .collection('daftarsiswa')
        .where('statuskelompok', isEqualTo: 'baru')
        .snapshots();
  }

  // Future<void> halaqohUntukSiswaNext(String nisnSiswa) async { ... } // Periksa apakah masih relevan/digunakan

  Future<void> ubahStatusSiswa(String nisnSiSwa) async {
    // ... (kode Anda sudah benar)
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelastahunajaran')
        .doc(kelasSiswaC.text) // Pastikan kelasSiswaC.text terisi dengan benar
        .collection('daftarsiswa')
        .doc(nisnSiSwa)
        .update({'statuskelompok': 'aktif'});
  }

  Future<void> simpanSiswaKelompok(String namaSiswa, String nisnSiswa) async {
    // ... (kode Anda sepertinya OK, tapi sangat panjang. Pertimbangkan WriteBatch)
    // Pastikan semua currentPengampuData[...] dan kelasSiswaC.text tersedia dan benar.
    // Gunakan try-catch dan WriteBatch untuk atomicity
    isLoading.value = true;
    try {
      String tahunajaranya = await getTahunAjaranTerakhir();
      String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

      QuerySnapshot<Map<String, dynamic>> querySnapshotKelompok = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('pegawai')
          .where('alias', isEqualTo: currentPengampuData['namapengampu'])
          .get();

      if (querySnapshotKelompok.docs.isEmpty) {
        Get.snackbar("Error", "Data pengampu tidak ditemukan.");
        isLoading.value = false;
        return;
      }
      Map<String, dynamic> dataGuru = querySnapshotKelompok.docs.first.data();
      String idPengampu = dataGuru['uid'];

      WriteBatch batch = firestore.batch();
      String tanggalInput = DateTime.now().toIso8601String();
      String semesterSaatIni = "Semester I"; // Asumsi, buat ini dinamis jika perlu

      // 1. Simpan di daftarsiswa pengampu
      DocumentReference refDaftarSiswaPengampu = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(currentPengampuData['fase'])
          .collection('pengampu').doc(currentPengampuData['namapengampu'])
          .collection('tempat').doc(currentPengampuData['tempatmengaji'])
          .collection('daftarsiswa').doc(nisnSiswa);
      batch.set(refDaftarSiswaPengampu, {
        'ummi': "0", // Default UMMI
        'namasiswa': namaSiswa,
        'nisn': nisnSiswa,
        'kelas': kelasSiswaC.text,
        'fase': currentPengampuData['fase'],
        'tempatmengaji': currentPengampuData['tempatmengaji'],
        'tahunajaran': currentPengampuData['tahunajaran'], // Seharusnya tahunajaranya dari getTahunAjaranTerakhir
        'kelompokmengaji': currentPengampuData['namapengampu'],
        'namapengampu': currentPengampuData['namapengampu'],
        'idpengampu': idPengampu, // Gunakan idPengampu yang didapat dari query pegawai
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
        'idsiswa': nisnSiswa,
      });
      
      // 1.1 Sub-koleksi semester di daftarsiswa pengampu
      DocumentReference refSemesterDaftarSiswa = refDaftarSiswaPengampu.collection('semester').doc(semesterSaatIni);
      batch.set(refSemesterDaftarSiswa, {
          'ummi': "0",
          'namasiswa': namaSiswa,
          'nisn': nisnSiswa,
          'kelas': kelasSiswaC.text,
          'fase': currentPengampuData['fase'],
          'tempatmengaji': currentPengampuData['tempatmengaji'],
          'tahunajaran': tahunajaranya, 
          'kelompokmengaji': currentPengampuData['namapengampu'],
          'namasemester': semesterSaatIni,
          'namapengampu': currentPengampuData['namapengampu'],
          'idpengampu': idPengampu,
          'emailpenginput': emailAdmin,
          'idpenginput': idUser,
          'tanggalinput': tanggalInput,
          'idsiswa': nisnSiswa,
      });


      // 2. Update data di bawah collection siswa
      DocumentReference refSiswaTahunAjaran = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('siswa').doc(nisnSiswa)
          .collection('tahunajarankelompok').doc(idTahunAjaran);
      batch.set(refSiswaTahunAjaran, {
        'fase': currentPengampuData['fase'],
        'nisn': nisnSiswa,
        'namatahunajaran': tahunajaranya,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
      }, SetOptions(merge: true)); // Merge jika sudah ada data lain

      DocumentReference refSiswaKelompokMengaji = refSiswaTahunAjaran
          .collection('kelompokmengaji').doc(currentPengampuData['fase']);
      batch.set(refSiswaKelompokMengaji, {
        'fase': currentPengampuData['fase'],
        'tempatmengaji': currentPengampuData['tempatmengaji'],
        'namapengampu': currentPengampuData['namapengampu'],
        'idpengampu': idPengampu,
        'tahunajaran': tahunajaranya,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
      }, SetOptions(merge: true));

      DocumentReference refSiswaPengampu = refSiswaKelompokMengaji
          .collection('pengampu').doc(currentPengampuData['namapengampu']);
      batch.set(refSiswaPengampu, {
        'nisn': nisnSiswa,
        'fase': currentPengampuData['fase'],
        'tahunajaran': idTahunAjaran, // atau tahunajaranya
        'namapengampu': currentPengampuData['namapengampu'],
        'idpengampu': idPengampu,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
      }, SetOptions(merge: true));

      DocumentReference refSiswaTempat = refSiswaPengampu
          .collection('tempat').doc(currentPengampuData['tempatmengaji']);
      batch.set(refSiswaTempat, {
        'nisn': nisnSiswa,
        'tempatmengaji': currentPengampuData['tempatmengaji'],
        'fase': currentPengampuData['fase'],
        'tahunajaran': idTahunAjaran, // atau tahunajaranya
        'namapengampu': currentPengampuData['namapengampu'],
        'idpengampu': idPengampu,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
      }, SetOptions(merge: true));
      
      DocumentReference refSiswaSemester = refSiswaTempat.collection('semester').doc(semesterSaatIni);
      batch.set(refSiswaSemester, {
        'ummi': "0",
        'nisn': nisnSiswa,
        'tempatmengaji': currentPengampuData['tempatmengaji'],
        'fase': currentPengampuData['fase'],
        'tahunajaran': idTahunAjaran, // atau tahunajaranya
        'namasemester': semesterSaatIni,
        'namapengampu': currentPengampuData['namapengampu'],
        'idpengampu': idPengampu,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
      });

      await batch.commit();
      ubahStatusSiswa(nisnSiswa); // Panggil setelah batch commit
      Get.snackbar("Berhasil", "$namaSiswa berhasil ditambahkan ke kelompok.");
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan siswa: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDaftarHalaqohDrawer() async* {
    // ... (kode Anda sudah benar)
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(currentPengampuData['fase']) 
        .collection('pengampu')
        .doc(currentPengampuData['namapengampu'])
        .collection('tempat')
        .doc(currentPengampuData['tempatmengaji'])
        .collection('daftarsiswa')
        .where('ummi', isNotEqualTo: umidrawerC.text) // Pastikan umidrawerC.text tidak kosong
        .snapshots();
  }
  Stream<QuerySnapshot<Map<String, dynamic>>> getDaftarHalaqoh() async* {
    // ... (kode Anda sudah benar)
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(currentPengampuData['fase']) 
        .collection('pengampu')
        .doc(currentPengampuData['namapengampu'])
        .collection('tempat')
        .doc(currentPengampuData['tempatmengaji'])
        .collection('daftarsiswa')
        .snapshots();
  }

  void test() async {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    print(idSekolah);
    print(idTahunAjaran);
    print(currentPengampuData['fase']);
    print(currentPengampuData['namapengampu']);
    print(currentPengampuData['tempatmengaji']);
  }

  Future<List<String>> getDataPengampuFase() async {
    // ... (kode Anda sudah benar)
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> pengampuList = [];
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(currentPengampuData['fase'])
        .collection('pengampu')
        // .where('namapengampu', isNotEqualTo: currentPengampuData['namapengampu']) // Bisa difilter di client side jika jumlahnya tidak banyak
        .get();
        
    for (var docSnapshot in querySnapshot.docs) {
        // Filter tambahan jika diperlukan (misal berdasarkan fase lagi, meskipun sudah di path)
        if (docSnapshot.data()['namapengampu'] != currentPengampuData['namapengampu'] && 
            docSnapshot.data()['fase'] == currentPengampuData['fase']) {
            pengampuList.add(docSnapshot.data()['namapengampu']);
        }
    }
    return pengampuList;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> dataPengampuPindah() async {
    // ... (kode Anda sudah benar)
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    DocumentSnapshot<Map<String, dynamic>> getPengampuNya =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelompokmengaji')
            .doc(currentPengampuData['fase']) // Asumsi fase tetap sama, jika bisa beda, ini perlu dipertimbangkan
            .collection('pengampu')
            .doc(pengampuC.text) // pengampuC.text adalah nama pengampu baru
            .get();
    return getPengampuNya;
  }

  Future<void> pindahkan(String nisnSiswa) async {
    if (pengampuC.text.isEmpty) {
      Get.snackbar('Peringatan', 'Pengampu baru belum dipilih.');
      return;
    }
    if (alasanC.text.isEmpty) {
      Get.snackbar('Peringatan', 'Alasan pindah kosong, silahkan diisi dahulu.');
      return;
    }

    isLoading.value = true;
    try {
      String tahunAjaranAktif = await getTahunAjaranTerakhir();
      String idTahunAjaran = tahunAjaranAktif.replaceAll('/', '-');
      String semesterAktif = "Semester I"; // Asumsi, buat dinamis jika perlu

      WriteBatch batch = firestore.batch();

      // 1. Dapatkan data pengampu tujuan (baru)
      DocumentSnapshot<Map<String, dynamic>> snapPengampuBaru = await dataPengampuPindah();
      if (!snapPengampuBaru.exists) {
        throw Exception("Data pengampu tujuan tidak ditemukan.");
      }
      Map<String, dynamic> dataPengampuBaru = snapPengampuBaru.data()!;
      // Pastikan dataPengampuBaru memiliki field: 'fase', 'namapengampu', 'tempatmengaji', 'idpengampu', 'ummi' (jika ada default)

      // 2. Dapatkan data siswa dari pengampu lama
      DocumentReference refSiswaDiPengampuLama = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(currentPengampuData['fase']) // FASE LAMA
          .collection('pengampu').doc(currentPengampuData['namapengampu']) // NAMA PENGAMPU LAMA
          .collection('tempat').doc(currentPengampuData['tempatmengaji']) // TEMPAT LAMA
          .collection('daftarsiswa').doc(nisnSiswa);
      
      DocumentSnapshot<Map<String, dynamic>> snapSiswaLama = await refSiswaDiPengampuLama.get() as DocumentSnapshot<Map<String, dynamic>>;
      if (!snapSiswaLama.exists) {
        throw Exception("Data siswa di pengampu lama tidak ditemukan.");
      }
      Map<String, dynamic> dataSiswaYangDipindah = snapSiswaLama.data()!;
      String namaSiswa = dataSiswaYangDipindah['namasiswa'];
      String kelasSiswa = dataSiswaYangDipindah['kelas'];
      // String ummiSiswaLama = dataSiswaYangDipindah['ummi'] ?? "0"; // Ambil ummi lama

      // 3. Dapatkan nilai-nilai siswa dari semester di pengampu lama
      //    Path: /Sekolah/{idSekolah}/tahunajaran/{idTahunAjaran}/kelompokmengaji/{currentPengampuData['fase']}/pengampu/{currentPengampuData['namapengampu']}/tempat/{currentPengampuData['tempatmengaji']}/daftarsiswa/{nisnSiswa}/semester/{semesterAktif}/nilai
      QuerySnapshot<Map<String, dynamic>> snapNilaiLama = await refSiswaDiPengampuLama
          .collection('semester').doc(semesterAktif) // SEMESTER LAMA
          .collection('nilai').get();
      
      List<Map<String,dynamic>> daftarNilaiLama = [];
      for(var docNilai in snapNilaiLama.docs){
          daftarNilaiLama.add({...docNilai.data(), 'idNilai': docNilai.id});
      }

      // === OPERASI PADA PENGAMPU BARU ===
      // 4. Tambahkan siswa ke daftarsiswa pengampu baru
      DocumentReference refSiswaDiPengampuBaru = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(dataPengampuBaru['fase']) // FASE BARU
          .collection('pengampu').doc(dataPengampuBaru['namapengampu']) // NAMA PENGAMPU BARU
          .collection('tempat').doc(dataPengampuBaru['tempatmengaji']) // TEMPAT BARU
          .collection('daftarsiswa').doc(nisnSiswa);
      
      batch.set(refSiswaDiPengampuBaru, {
        ...dataSiswaYangDipindah, // Salin semua data siswa lama
        'fase': dataPengampuBaru['fase'], // Update dengan info pengampu baru
        'tempatmengaji': dataPengampuBaru['tempatmengaji'],
        'kelompokmengaji': dataPengampuBaru['namapengampu'],
        'namapengampu': dataPengampuBaru['namapengampu'],
        'idpengampu': dataPengampuBaru['idpengampu'],
        // 'ummi': ummiSiswaLama, // Pertahankan Ummi dari data siswa lama atau default baru?
        'tanggalinput': DateTime.now().toIso8601String(), // Update tanggal
        // Hapus field yang spesifik pengampu lama jika ada (misal 'catatan_pengampu_lama')
      });

      // 5. Tambahkan nilai ke semester di pengampu baru
      DocumentReference refSemesterDiPengampuBaru = refSiswaDiPengampuBaru
          .collection('semester').doc(semesterAktif); // Atau dataPengampuBaru['namasemester'] jika ada
      
      batch.set(refSemesterDiPengampuBaru, { // Buat dokumen semester jika belum ada
          // 'ummi': ummiSiswaLama, // sesuaikan dengan data siswa
          'namasiswa': namaSiswa,
          'nisn': nisnSiswa,
          'kelas': kelasSiswa,
          'fase': dataPengampuBaru['fase'],
          'tempatmengaji': dataPengampuBaru['tempatmengaji'],
          'tahunajaran': tahunAjaranAktif, 
          'kelompokmengaji': dataPengampuBaru['namapengampu'],
          'namasemester': semesterAktif,
          'namapengampu': dataPengampuBaru['namapengampu'],
          'idpengampu': dataPengampuBaru['idpengampu'],
          'emailpenginput': emailAdmin,
          'idpenginput': idUser,
          'tanggalinput': DateTime.now().toIso8601String(),
          'idsiswa': nisnSiswa,
      });
      
      for (var nilai in daftarNilaiLama) {
        String idNilaiLama = nilai.remove('idNilai'); // Ambil dan hapus id dari map
        DocumentReference refNilaiBaru = refSemesterDiPengampuBaru.collection('nilai').doc(idNilaiLama); // Gunakan ID lama agar tidak duplikat
        batch.set(refNilaiBaru, {
          ...nilai, // Salin semua data nilai lama
           // Update field yang relevan dengan pengampu baru jika perlu
          'fase': dataPengampuBaru['fase'],
          'tempatmengaji': dataPengampuBaru['tempatmengaji'],
          'kelompokmengaji': dataPengampuBaru['namapengampu'],
          'namapengampu': dataPengampuBaru['namapengampu'],
          'idpengampu': dataPengampuBaru['idpengampu'],
          'tanggalinput': nilai['tanggalinput'], // Pertahankan tanggal input nilai asli
        });
      }

      // === CATAT RIWAYAT PINDAH ===
      // 6. Buat catatan pindahan
      String idPindahan = firestore.collection('_placeholder_').doc().id; // Generate unique ID
      DocumentReference refRiwayatPindah = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('tahunajaran').doc(idTahunAjaran)
          // .collection('semester').doc(semesterAktif) // Struktur riwayat pindah bisa disesuaikan
          .collection('riwayatpindahan').doc(idPindahan); // Atau langsung di root 'pindahan'
      
      batch.set(refRiwayatPindah, {
        // 'ummi': ummiSiswaLama,
        'namasiswa': namaSiswa,
        'nisn': nisnSiswa,
        'kelas': kelasSiswa,
        'fase_lama': currentPengampuData['fase'],
        'fase_baru': dataPengampuBaru['fase'],
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalpindah': DateTime.now().toIso8601String(),
        'pengampu_lama': currentPengampuData['namapengampu'],
        'tempat_lama': currentPengampuData['tempatmengaji'],
        'pengampu_baru': dataPengampuBaru['namapengampu'],
        'tempat_baru': dataPengampuBaru['tempatmengaji'],
        'alasanpindah': alasanC.text,
        'idsiswa': nisnSiswa,
        'tahunajaran': tahunAjaranAktif,
        'semester': semesterAktif,
      });

      // === OPERASI PADA PADMINDUK SISWA (KOLEKSI /Sekolah/{id}/siswa/{nisn}) ===
      // 7. Update data kelompok di dokumen utama siswa
      DocumentReference refKelompokDiSiswa = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('siswa').doc(nisnSiswa)
          .collection('tahunajarankelompok').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(dataPengampuBaru['fase']); // FASE BARU (jika fase bisa berubah)
                                                                      // Jika fase selalu sama, gunakan currentPengampuData['fase']

      batch.update(refKelompokDiSiswa, { // Asumsi dokumen ini sudah ada dari proses simpanSiswaKelompok
        "idpengampu": dataPengampuBaru['idpengampu'],
        "kelompokmengaji": dataPengampuBaru['namapengampu'], // alias nama pengampu
        "namapengampu": dataPengampuBaru['namapengampu'],
        "tempatmengaji": dataPengampuBaru['tempatmengaji'],
        "pernahpindah": "iya",
        // "fase": dataPengampuBaru['fase'], // jika fase di path atas adalah dataPengampuBaru['fase']
      });
      
      // Hapus struktur pengampu lama di bawah dokumen siswa
      DocumentReference refPengampuLamaDiSiswa = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('siswa').doc(nisnSiswa)
          .collection('tahunajarankelompok').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(currentPengampuData['fase']) // FASE LAMA
          .collection('pengampu').doc(currentPengampuData['namapengampu']); // NAMA PENGAMPU LAMA
      
      // Untuk menghapus subkoleksi, Anda perlu menghapus semua dokumen di dalamnya satu per satu.
      // Atau, jika Anda hanya ingin menghapus dokumen 'tempat' dan 'semester' di bawahnya:
      QuerySnapshot snapTempatLamaDiSiswa = await refPengampuLamaDiSiswa.collection('tempat').get();
      for(var docTempat in snapTempatLamaDiSiswa.docs){
          QuerySnapshot snapSemesterLamaDiSiswa = await docTempat.reference.collection('semester').get();
          for(var docSemester in snapSemesterLamaDiSiswa.docs){
              batch.delete(docSemester.reference);
          }
          batch.delete(docTempat.reference);
      }
      batch.delete(refPengampuLamaDiSiswa); // Hapus dokumen pengampu lama itu sendiri

      // Buat struktur pengampu baru di bawah dokumen siswa
      DocumentReference refPengampuBaruDiSiswa = firestore
          .collection('Sekolah').doc(idSekolah)
          .collection('siswa').doc(nisnSiswa)
          .collection('tahunajarankelompok').doc(idTahunAjaran)
          .collection('kelompokmengaji').doc(dataPengampuBaru['fase']) // FASE BARU
          .collection('pengampu').doc(dataPengampuBaru['namapengampu']); // NAMA PENGAMPU BARU
      batch.set(refPengampuBaruDiSiswa, { /* data relevan pengampu baru */ 
        'nisn': nisnSiswa,
        'fase': dataPengampuBaru['fase'],
        'tahunajaran': idTahunAjaran,
        'namapengampu': dataPengampuBaru['namapengampu'],
        'idpengampu': dataPengampuBaru['idpengampu'],
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
      });
      
      DocumentReference refTempatBaruDiSiswa = refPengampuBaruDiSiswa.collection('tempat').doc(dataPengampuBaru['tempatmengaji']);
      batch.set(refTempatBaruDiSiswa, { /* data relevan tempat baru */ 
          'nisn': nisnSiswa,
          'tempatmengaji': dataPengampuBaru['tempatmengaji'],
          'fase': dataPengampuBaru['fase'],
          'tahunajaran': idTahunAjaran,
          'namapengampu': dataPengampuBaru['namapengampu'],
          'idpengampu': dataPengampuBaru['idpengampu'],
          'emailpenginput': emailAdmin,
          'idpenginput': idUser,
          'tanggalinput': DateTime.now().toIso8601String(),
      });

      DocumentReference refSemesterBaruDiSiswa = refTempatBaruDiSiswa.collection('semester').doc(semesterAktif);
      batch.set(refSemesterBaruDiSiswa, { /* data relevan semester baru */
          // 'ummi': ummiSiswaLama,
          'nisn': nisnSiswa,
          'tempatmengaji': dataPengampuBaru['tempatmengaji'],
          'fase': dataPengampuBaru['fase'],
          'tahunajaran': idTahunAjaran,
          'namasemester': semesterAktif,
          'namapengampu': dataPengampuBaru['namapengampu'],
          'idpengampu': dataPengampuBaru['idpengampu'],
          'emailpenginput': emailAdmin,
          'idpenginput': idUser,
          'tanggalinput': DateTime.now().toIso8601String(),
       });


      // === OPERASI PADA PENGAMPU LAMA (PENGHAPUSAN) ===
      // 8. Hapus nilai-nilai dari semester di pengampu lama
      DocumentReference refSemesterDiPengampuLama = refSiswaDiPengampuLama
          .collection('semester').doc(semesterAktif); // SEMESTER LAMA
      for (var nilai in daftarNilaiLama) {
        batch.delete(refSemesterDiPengampuLama.collection('nilai').doc(nilai['idNilai']));
      }
      // Hapus dokumen semester itu sendiri di pengampu lama jika sudah tidak ada nilai & tidak ada data lain yang penting
      // batch.delete(refSemesterDiPengampuLama); // Hati-hati jika ada data lain di doc semester ini

      // 9. Hapus siswa dari daftarsiswa pengampu lama
      batch.delete(refSiswaDiPengampuLama);


      // COMMIT SEMUA OPERASI
      await batch.commit();

      Get.back(); // Tutup dialog
      Get.snackbar('Berhasil', '$namaSiswa berhasil dipindahkan ke ${dataPengampuBaru['namapengampu']}.');
      pengampuC.clear();
      alasanC.clear();

    } catch (e) {
      Get.back(); // Tutup dialog jika masih terbuka
      Get.snackbar('Error Pindah', 'Gagal memindahkan siswa: ${e.toString()}', duration: Duration(seconds: 5));
      print("Error pindahkan: $e");
    } finally {
      isLoading.value = false;
    }
  }
}




















// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// // import 'package:intl/intl.dart';

// class DaftarHalaqohController extends GetxController {
//   var currentPengampuData = Get.arguments;
//   RxBool isLoading = false.obs;

//   TextEditingController pengampuC = TextEditingController();
//   TextEditingController kelasSiswaC = TextEditingController();
//   TextEditingController alasanC = TextEditingController();
//   TextEditingController umiC = TextEditingController();
//   TextEditingController umidrawerC = TextEditingController();

//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   String idUser = FirebaseAuth.instance.currentUser!.uid;
//   String idSekolah = '20404148';
//   String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

//   Future<String> getTahunAjaranTerakhir() async {
//     CollectionReference<Map<String, dynamic>> colTahunAjaran = firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran');
//     QuerySnapshot<Map<String, dynamic>> snapshotTahunAjaran =
//         await colTahunAjaran.get();
//     List<Map<String, dynamic>> listTahunAjaran =
//         snapshotTahunAjaran.docs.map((e) => e.data()).toList();
//     String tahunAjaranTerakhir =
//         listTahunAjaran.map((e) => e['namatahunajaran']).toList().last;
//     return tahunAjaranTerakhir;
//   }


//   Future<List<String>> getDataKelasYangAda() async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     List<String> kelasList = [];
//     await firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran')
//         .doc(idTahunAjaran)
//         .collection('kelastahunajaran')
//         .where('fase', isEqualTo: currentPengampuData['fase'])
//         .get()
//         .then((querySnapshot) {
//           for (var docSnapshot in querySnapshot.docs) {
//             kelasList.add(docSnapshot.id);
//           }
//         });
//     return kelasList;
//   }

//   Future<List<String>> getDataUmi() async {
//     List<String> umiList = [
//       'Umi', 
//       'AlQuran',
//       'Jilid 1',
//       'Jilid 2',
//       'Jilid 3',
//       'Jilid 4',
//       'Jilid 5',
//       'Jilid 6',
//       ];
//     return umiList;
//   }

//   Future<void> updateUmi(String nisnSiswa) async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
//     // String idSekolah = '20404148';

//     if (idTahunAjaran.isNotEmpty) {
//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('pengampu')
//           .doc(currentPengampuData['namapengampu'])
//           .collection('tempat')
//           .doc(currentPengampuData['tempatmengaji'])
//           .collection('daftarsiswa')
//           .doc(nisnSiswa)
//           .update({'ummi': umiC.text});

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('pengampu')
//           .doc(currentPengampuData['namapengampu'])
//           .collection('tempat')
//           .doc(currentPengampuData['tempatmengaji'])
//           .collection('daftarsiswa')
//           .doc(nisnSiswa)
//           .collection('semester')
//           .doc('Semester I')
//           .update({'ummi': umiC.text});

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .doc(nisnSiswa)
//           .collection('tahunajarankelompok')
//           .doc(idTahunAjaran)
//           // .collection('semester')
//           // .doc(argumenData[0]['namasemester'])
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('pengampu')
//           .doc(currentPengampuData['namapengampu'])
//           .collection('tempat')
//           .doc(currentPengampuData['tempatmengaji'])
//           .collection('semester')
//           .doc('Semester I')
//           .update({'ummi': umiC.text});

//       Get.back();
//       Get.snackbar("Berhasil", "Umi Berhasil dibuat");
//     } else {
//       Get.snackbar(
//         "Error",
//         "Data tidak ditemukan, Atau periksa koneksi internet",
//       );
//     }
//   }

//   Future<void> updateUmiDrawer(String nisnSiswa) async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
//     // String idSekolah = '20404148';

//     if (idTahunAjaran.isNotEmpty) {
//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('pengampu')
//           .doc(currentPengampuData['namapengampu'])
//           .collection('tempat')
//           .doc(currentPengampuData['tempatmengaji'])
//           .collection('daftarsiswa')
//           .doc(nisnSiswa)
//           .update({'ummi': umidrawerC.text});

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('pengampu')
//           .doc(currentPengampuData['namapengampu'])
//           .collection('tempat')
//           .doc(currentPengampuData['tempatmengaji'])
//           .collection('daftarsiswa')
//           .doc(nisnSiswa)
//           .collection('semester')
//           .doc('Semester I')
//           .update({'ummi': umidrawerC.text});

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .doc(nisnSiswa)
//           .collection('tahunajarankelompok')
//           .doc(idTahunAjaran)
//           // .collection('semester')
//           // .doc(argumenData[0]['namasemester'])
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('pengampu')
//           .doc(currentPengampuData['namapengampu'])
//           .collection('tempat')
//           .doc(currentPengampuData['tempatmengaji'])
//           .collection('semester')
//           .doc('Semester I')
//           .update({'ummi': umidrawerC.text});

//       // Get.back();
//       // Get.snackbar("Berhasil", "Umi Berhasil dibuat");
//     } else {
//       Get.snackbar(
//         "Error",
//         "Data tidak ditemukan, Atau periksa koneksi internet",
//       );
//     }
//   }

//   Stream<QuerySnapshot<Map<String, dynamic>>> getDataSiswaStreamBaru() async* {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");
//     // String idSemester = await getDataSemester();
//     yield* firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran')
//         .doc(idTahunAjaran)
//         .collection('kelastahunajaran')
//         .doc(kelasSiswaC.text)
//         .collection('daftarsiswa')
//         // .collection('semester')
//         // .doc('Semester I') // ini nanti diganti otomatis // sudah di pasang -->> kalo sudah dihapus comment
//         // .collection('daftarsiswa')
//         .where('statuskelompok', isEqualTo: 'baru')
//         .snapshots();

//     // print('ini kelasnya : ${kelasSiswaC.text}');
//   }

//   Future<void> halaqohUntukSiswaNext(String nisnSiswa) async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     QuerySnapshot<Map<String, dynamic>> querySnapshotKelompok =
//         await firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('pegawai')
//             .where('alias', isEqualTo: currentPengampuData['namapengampu'])
//             .get();
//     if (querySnapshotKelompok.docs.isNotEmpty) {
//       Map<String, dynamic> dataGuru = querySnapshotKelompok.docs.first.data();
//       String idPengampu = dataGuru['uid'];

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .doc(nisnSiswa)
//           .collection('tahunajarankelompok')
//           .doc(idTahunAjaran)
//           .set({
//             'fase': currentPengampuData['fase'],
//             'namatahunajaran': tahunajaranya,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//           });

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .doc(nisnSiswa)
//           .collection('tahunajarankelompok')
//           .doc(idTahunAjaran)
//           .collection('semester')
//           .doc(currentPengampuData['namasemester'])
//           .set({
//             'fase': currentPengampuData['fase'],
//             'namasemester': currentPengampuData['namasemester'],
//             'tahunajaran': tahunajaranya,
//             'emailpenginput': emailAdmin,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//           });

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .doc(nisnSiswa)
//           .collection('tahunajarankelompok')
//           .doc(idTahunAjaran)
//           .collection('semester')
//           .doc(currentPengampuData['namasemester'])
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .set({
//             'fase': currentPengampuData['fase'],
//             'tempatmengaji': currentPengampuData['tempatmengaji'],
//             'namapengampu': currentPengampuData['namapengampu'],
//             'kelompokmengaji': currentPengampuData['namapengampu'],
//             'idpengampu': idPengampu,
//             'namasemester': currentPengampuData['namasemester'],
//             'tahunajaran': tahunajaranya,
//             'emailpenginput': emailAdmin,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//           });

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .doc(nisnSiswa)
//           .collection('tahunajarankelompok')
//           .doc(idTahunAjaran)
//           .collection('semester')
//           .doc(currentPengampuData['namasemester'])
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('tempat')
//           .doc(currentPengampuData['tempatmengaji'])
//           .set({
//             'nisn': nisnSiswa,
//             'tempatmengaji': currentPengampuData['tempatmengaji'],
//             'fase': currentPengampuData['fase'],
//             'tahunajaran': currentPengampuData['tahunajaran'],
//             'kelompokmengaji': currentPengampuData['namapengampu'],
//             'namasemester': currentPengampuData['namasemester'],
//             'namapengampu': currentPengampuData['namapengampu'],
//             'idpengampu': idPengampu,
//             'emailpenginput': emailAdmin,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//           });
//     }
//   }

//   Future<void> ubahStatusSiswa(String nisnSiSwa) async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     await firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran')
//         .doc(idTahunAjaran)
//         .collection('kelastahunajaran')
//         .doc(kelasSiswaC.text)
//         .collection('daftarsiswa')
//         .doc(nisnSiSwa)
//         .update({'statuskelompok': 'aktif'});
//   }

//   Future<void> simpanSiswaKelompok(String namaSiswa, String nisnSiswa) async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     QuerySnapshot<Map<String, dynamic>> querySnapshotKelompok =
//         await firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('pegawai')
//             .where('alias', isEqualTo: currentPengampuData['namapengampu'])
//             .get();
//     if (querySnapshotKelompok.docs.isNotEmpty) {
//       Map<String, dynamic> dataGuru = querySnapshotKelompok.docs.first.data();
//       String idPengampu = dataGuru['uid'];

//       //buat pada tahunpelajaran sekolah
//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('pengampu')
//           .doc(currentPengampuData['namapengampu'])
//           .collection('tempat')
//           .doc(currentPengampuData['tempatmengaji'])
//           .collection('daftarsiswa')
//           .doc(nisnSiswa)
//           .set({
//             'ummi' : "0",
//             'namasiswa': namaSiswa,
//             'nisn': nisnSiswa,
//             'kelas': kelasSiswaC.text,
//             'fase': currentPengampuData['fase'],
//             'tempatmengaji': currentPengampuData['tempatmengaji'],
//             'tahunajaran': currentPengampuData['tahunajaran'],
//             'kelompokmengaji': currentPengampuData['namapengampu'],
//             'namapengampu': currentPengampuData['namapengampu'],
//             'idpengampu': currentPengampuData['idpengampu'],
//             'emailpenginput': emailAdmin,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//             'idsiswa': nisnSiswa,
//           });

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('tahunajaran')
//           .doc(idTahunAjaran)
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('pengampu')
//           .doc(currentPengampuData['namapengampu'])
//           .collection('tempat')
//           .doc(currentPengampuData['tempatmengaji'])
//           .collection('daftarsiswa')
//           .doc(nisnSiswa)
//           .collection('semester')
//           .doc('Semester I')
//           .set({
//             'ummi': "0",
//             'namasiswa': namaSiswa,
//             'nisn': nisnSiswa,
//             'kelas': kelasSiswaC.text,
//             'fase': currentPengampuData['fase'],
//             'tempatmengaji': currentPengampuData['tempatmengaji'],
//             'tahunajaran': currentPengampuData['tahunajaran'],
//             'kelompokmengaji': currentPengampuData['namapengampu'],
//             'namasemester': 'Semester I',
//             'namapengampu': currentPengampuData['namapengampu'],
//             'idpengampu': idPengampu,
//             'emailpenginput': emailAdmin,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//             'idsiswa': nisnSiswa,
//           });

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .doc(nisnSiswa)
//           .collection('tahunajarankelompok')
//           .doc(idTahunAjaran)
//           .set({
//             'fase': currentPengampuData['fase'],
//             'nisn': nisnSiswa,
//             'namatahunajaran': tahunajaranya,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//           });

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .doc(nisnSiswa)
//           .collection('tahunajarankelompok')
//           .doc(idTahunAjaran)
//           // .collection('semester')
//           // .doc(argumenData[0]['namasemester'])
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .set({
//             'fase': currentPengampuData['fase'],
//             'tempatmengaji': currentPengampuData['tempatmengaji'],
//             'namapengampu': currentPengampuData['namapengampu'],
//             'kelompokmengaji': currentPengampuData['namapengampu'],
//             'idpengampu': idPengampu,
//             // 'namasemester': argumenData[0]['namasemester'],
//             'tahunajaran': tahunajaranya,
//             'emailpenginput': emailAdmin,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//           });

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .doc(nisnSiswa)
//           .collection('tahunajarankelompok')
//           .doc(idTahunAjaran)
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('pengampu')
//           .doc(currentPengampuData['namapengampu'])
//           .set({
//             'nisn': nisnSiswa,
//             // 'tempatmengaji': currentPengampuData['tempatmengaji'],
//             'fase': currentPengampuData['fase'],
//             'tahunajaran': idTahunAjaran,
//             'kelompokmengaji': currentPengampuData['namapengampu'],
//             'namapengampu': currentPengampuData['namapengampu'],
//             'idpengampu': idPengampu,
//             'emailpenginput': emailAdmin,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//           });

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .doc(nisnSiswa)
//           .collection('tahunajarankelompok')
//           .doc(idTahunAjaran)
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('pengampu')
//           .doc(currentPengampuData['namapengampu'])
//           .collection('tempat')
//           .doc(currentPengampuData['tempatmengaji'])
//           .set({
//             'nisn': nisnSiswa,
//             'tempatmengaji': currentPengampuData['tempatmengaji'],
//             'fase': currentPengampuData['fase'],
//             'tahunajaran': idTahunAjaran,
//             'kelompokmengaji': currentPengampuData['namapengampu'],
//             // 'namasemester': 'Semester I',
//             'namapengampu': currentPengampuData['namapengampu'],
//             'idpengampu': idPengampu,
//             'emailpenginput': emailAdmin,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//           });

//       await firestore
//           .collection('Sekolah')
//           .doc(idSekolah)
//           .collection('siswa')
//           .doc(nisnSiswa)
//           .collection('tahunajarankelompok')
//           .doc(idTahunAjaran)
//           // .collection('semester')
//           // .doc(argumenData[0]['namasemester'])
//           .collection('kelompokmengaji')
//           .doc(currentPengampuData['fase'])
//           .collection('pengampu')
//           .doc(currentPengampuData['namapengampu'])
//           .collection('tempat')
//           .doc(currentPengampuData['tempatmengaji'])
//           .collection('semester')
//           .doc('Semester I')
//           .set({
//             'ummi': "0",
//             'nisn': nisnSiswa,
//             'tempatmengaji': currentPengampuData['tempatmengaji'],
//             'fase': currentPengampuData['fase'],
//             'tahunajaran': idTahunAjaran,
//             'kelompokmengaji': currentPengampuData['namapengampu'],
//             'namasemester': 'Semester I',
//             'namapengampu': currentPengampuData['namapengampu'],
//             'idpengampu': idPengampu,
//             'emailpenginput': emailAdmin,
//             'idpenginput': idUser,
//             'tanggalinput': DateTime.now().toIso8601String(),
//           });

//       // halaqohUntukSiswaNext(nisnSiswa);
//       ubahStatusSiswa(nisnSiswa);
//     }
//   }

//   Stream<QuerySnapshot<Map<String, dynamic>>> getDaftarHalaqohDrawer() async* {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     yield* firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran')
//         .doc(idTahunAjaran)
//         // .collection('semester')
//         // .doc(currentPengampuData['namasemester'])
//         .collection('kelompokmengaji')
//         .doc(currentPengampuData['fase']) // ini nanti diganti otomatis
//         .collection('pengampu')
//         .doc(currentPengampuData['namapengampu'])
//         .collection('tempat')
//         .doc(currentPengampuData['tempatmengaji'])
//         .collection('daftarsiswa')
//         .where('ummi', isNotEqualTo: umidrawerC.text)
//         .snapshots();
//   }
//   Stream<QuerySnapshot<Map<String, dynamic>>> getDaftarHalaqoh() async* {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     yield* firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran')
//         .doc(idTahunAjaran)
//         // .collection('semester')
//         // .doc(currentPengampuData['namasemester'])
//         .collection('kelompokmengaji')
//         .doc(currentPengampuData['fase']) // ini nanti diganti otomatis
//         .collection('pengampu')
//         .doc(currentPengampuData['namapengampu'])
//         .collection('tempat')
//         .doc(currentPengampuData['tempatmengaji'])
//         .collection('daftarsiswa')
//         .snapshots();
//   }

//   Future<List<String>> getDataPengampuFase() async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     List<String> pengampuList = [];
//     await firestore
//         .collection('Sekolah')
//         .doc(idSekolah)
//         .collection('tahunajaran')
//         .doc(idTahunAjaran)
//         // .collection('semester')
//         // .doc(currentPengampuData['namasemester'])
//         .collection('kelompokmengaji')
//         .doc(currentPengampuData['fase'])
//         .collection('pengampu')
//         .where('namapengampu', isNotEqualTo: currentPengampuData['namapengampu'])
//         .get()
//         .then((querySnapshot) {
//           for (var docSnapshot in querySnapshot.docs.where(
//             (doc) => doc['fase'] == currentPengampuData['fase'],
//           )) {
//             pengampuList.add(docSnapshot.data()['namapengampu']);
//           }
//         });
//     return pengampuList;
//   }

//   Future<DocumentSnapshot<Map<String, dynamic>>> dataPengampuPindah() async {
//     String tahunajaranya = await getTahunAjaranTerakhir();
//     String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

//     DocumentSnapshot<Map<String, dynamic>> getPengampuNya =
//         await firestore
//             .collection('Sekolah')
//             .doc(idSekolah)
//             .collection('tahunajaran')
//             .doc(idTahunAjaran)
//             // .collection('semester')
//             // .doc(currentPengampuData['namasemester'])
//             .collection('kelompokmengaji')
//             .doc(currentPengampuData['fase'])
//             .collection('pengampu')
//             // .where('namapengampu', isNotEqualTo: currentPengampuData['namapengampu'])
//             .doc(pengampuC.text)
//             .get();

//     // print('ini get pentampunya = ${getPengampuNya.docs.first.data()['test']}');
//     return getPengampuNya;
//   }

//   Future<void> pindahkan(String nisnSiswa) async {
//     if (pengampuC.text.isEmpty || pengampuC.text == "") {
//       // print('PENGAMPU BELUM DIISI');
//       isLoading.value = false;
//       Get.snackbar('Peringatan', 'Pengampu baru kosong');
//     } else if (alasanC.text.isEmpty) {
//       isLoading.value = false;
//       Get.snackbar('Peringatan', 'Alasan pindah kosong, silahkan diisi dahulu');
//     } else {
//       isLoading.value = true;

//       DocumentSnapshot<Map<String, dynamic>> pengampuSnapshot =
//           await dataPengampuPindah();
//       Map<String, dynamic> pengampuData = pengampuSnapshot.data()!;
//       String tahunajaran = pengampuData['tahunajaran'];
//       String tahunAjaranPengampu = tahunajaran.replaceAll('/', '-');

//       String uid = firestore.collection('Sekolah').doc().id;

//       QuerySnapshot<Map<String, dynamic>> querySnapshotSiswa =
//           await firestore
//               .collection('Sekolah')
//               .doc(idSekolah)
//               .collection('tahunajaran')
//               .doc(tahunAjaranPengampu)
//               // .collection('semester')
//               // .doc(currentPengampuData['namasemester'])
//               .collection('kelompokmengaji')
//               .doc(currentPengampuData['fase']) // ini nanti diganti otomatis
//               .collection('pengampu')
//               .doc(currentPengampuData['namapengampu'])
//               .collection('tempat')
//               .doc(currentPengampuData['tempatmengaji'])
//               .collection('daftarsiswa')
//               .where('nisn', isEqualTo: nisnSiswa)
//               .get();
//       if (querySnapshotSiswa.docs.isNotEmpty) {
//         Map<String, dynamic> dataSiswa = querySnapshotSiswa.docs.first.data();
//         String namasiswa = dataSiswa['namasiswa'];
//         String kelassiswa = dataSiswa['kelas'];

//         QuerySnapshot<Map<String, dynamic>> getNilainya =
//             await firestore
//                 .collection('Sekolah')
//                 .doc(idSekolah)
//                 .collection('tahunajaran')
//                 .doc(tahunAjaranPengampu)
//                 .collection('kelompokmengaji')
//                 .doc(pengampuData['fase'])
//                 .collection('pengampu')
//                 .doc(currentPengampuData['namapengampu'])
//                 .collection('tempat')
//                 .doc(currentPengampuData['tempatmengaji'])
//                 .collection('daftarsiswa')
//                 .doc(nisnSiswa)
//                 .collection('semester')
//                 .doc(pengampuData['namasemester'])
//                 .collection('nilai')
//                 .get();

//         // if (getNilainya.docs.isEmpty) {
//         //   Get.snackbar(
//         //      "Informasi", "No data available");
//         //   return;
//         // }

//         // ambil semua data doc nilai
//         // Map<String, dynamic> allNilaiNya = {};
//         // for (var element in getNilainya.docs) {
//         //   allNilaiNya[element.id] = element.data();
//         // }

//         //ambil semua doc id
//         Map<String, dynamic> allDocId = {};
//         for (var element in getNilainya.docs) {
//           allDocId[element.id] = element.data()[element.id];

//           // print('allNilaiNya = $allNilaiNya');
//           // print('===============================');
//           // print('allDocId = $allDocId');

//           Map<String, dynamic> allDocNilai = {};
//           for (var element in getNilainya.docs) {
//             allDocNilai[element.id] = element.data();

//             // print("allDocNilai[element.id]['tanggalinput'] = ${allDocNilai[element.id]['tanggalinput']}");
//             // print('===============================');
//             // print("allDocNilai[element.id]['ummijilidatausurat'] = ${allDocNilai[element.id]['ummijilidatausurat']}");

//             //  SIMPAN DATA SISWA PADA TAHUN AJARAN SEKOLAH (PENGAMPU BARU)
//             await firestore
//                 .collection('Sekolah')
//                 .doc(idSekolah)
//                 .collection('tahunajaran')
//                 .doc(tahunAjaranPengampu)
//                 // .collection('semester')
//                 // .doc(pengampuData['namasemester'])
//                 .collection('kelompokmengaji')
//                 .doc(pengampuData['fase'])
//                 .collection('pengampu')
//                 .doc(pengampuData['namapengampu'])
//                 .collection('tempat')
//                 .doc(pengampuData['tempatmengaji'])
//                 .collection('daftarsiswa')
//                 .doc(nisnSiswa)
//                 .set({
//                   'ummi' : pengampuData['ummi'],
//                   'namasiswa': namasiswa,
//                   'nisn': nisnSiswa,
//                   'kelas': kelassiswa,
//                   'fase': pengampuData['fase'],
//                   'tempatmengaji': pengampuData['tempatmengaji'],
//                   'tahunajaran': pengampuData['tahunajaran'],
//                   'kelompokmengaji': pengampuData['namapengampu'],
//                   'namasemester': pengampuData['namasemester'],
//                   'namapengampu': pengampuData['namapengampu'],
//                   'idpengampu': pengampuData['idpengampu'],
//                   'emailpenginput': emailAdmin,
//                   'idpenginput': idUser,
//                   'tanggalinput': DateTime.now().toIso8601String(),
//                   'idsiswa': nisnSiswa,
//                 });
//             // print('SIMPAN DATA SISWA PADA TAHUN AJARAN SEKOLAH (PENGAMPU BARU)');

//             // SIMPAN NILAI DATA SISWA PADA TAHUN AJARAN SEKOLAH (PENGAMPU BARU)
//             // Jika nilai pada halaqoh sebelumnya tidak ada maka step ini d lewati
//             // ignore: prefer_is_empty
//             if (element.id.isNotEmpty || element.id.length != 0) {
//               await firestore
//                   .collection('Sekolah')
//                   .doc(idSekolah)
//                   .collection('tahunajaran')
//                   .doc(tahunAjaranPengampu)
                  
//                   .collection('kelompokmengaji')
//                   .doc(pengampuData['fase'])
//                   .collection('pengampu')
//                   .doc(pengampuData['namapengampu'])
//                   .collection('tempat')
//                   .doc(pengampuData['tempatmengaji'])
//                   .collection('daftarsiswa')
//                   .doc(nisnSiswa)
//                   .collection('semester')
//                   .doc(pengampuData['namasemester'])
//                   .collection('nilai')
//                   .doc(element.id)
//                   .set({
//                     'tanggalinput': allDocNilai[element.id]['tanggalinput'],
//                     //=========================================
//                     "emailpenginput": emailAdmin,
//                     "fase": allDocNilai[element.id]['fase'],
//                     "idpengampu": allDocNilai[element.id]['idpengampu'],
//                     "idsiswa": allDocNilai[element.id]['idsiswa'],
//                     "kelas": allDocNilai[element.id]['kelas'],
//                     "kelompokmengaji":
//                         allDocNilai[element.id]['kelompokmengaji'],
//                     "namapengampu": allDocNilai[element.id]['namapengampu'],
//                     "namasemester": allDocNilai[element.id]['namasemester'],
//                     "namasiswa": allDocNilai[element.id]['namasiswa'],
//                     "tahunajaran": allDocNilai[element.id]['tahunajaran'],
//                     "tempatmengaji": allDocNilai[element.id]['tempatmengaji'],
//                     "hafalansurat": allDocNilai[element.id]['hafalansurat'],
//                     "ayathafalansurat":
//                         allDocNilai[element.id]['ayathafalansurat'],
//                     "ummijilidatausurat":
//                         allDocNilai[element.id]['ummijilidatausurat'],
//                     "ummihalatauayat":
//                         allDocNilai[element.id]['ummihalatauayat'],
//                     "materi": allDocNilai[element.id]['materi'],
//                     "nilai": allDocNilai[element.id]['nilai'],
//                     "keteranganpengampu":
//                         allDocNilai[element.id]['keteranganpengampu'],
//                     "keteranganorangtua":
//                         allDocNilai[element.id]['keteranganorangtua'],
//                   });
//               // print('SIMPAN NILAI DATA SISWA PADA TAHUN AJARAN SEKOLAH (PENGAMPU BARU)');
//             }

//             // SIMPAN DATA SISWA PADA (PENGAMPU BARU)
//             // await firestore
//             //     .collection('Sekolah')
//             //     .doc(idSekolah)
//             //     .collection('pegawai')
//             //     .doc(pengampuData['idpengampu'])
//             //     .collection('tahunajarankelompok')
//             //     .doc(tahunAjaranPengampu)
//             //     .collection('semester')
//             //     .doc(pengampuData['namasemester'])
//             //     .collection('kelompokmengaji')
//             //     .doc(pengampuData['fase'])
//             //     .collection('tempat')
//             //     .doc(pengampuData['tempatmengaji'])
//             //     .collection('daftarsiswa')
//             //     .doc(nisnSiswa)
//             //     .set({
//             //   'namasiswa': namasiswa,
//             //   'nisn': nisnSiswa,
//             //   'kelas': kelassiswa,
//             //   'fase': pengampuData['fase'],
//             //   'tempatmengaji': pengampuData['tempatmengaji'],
//             //   'tahunajaran': pengampuData['tahunajaran'],
//             //   'kelompokmengaji': pengampuData['namapengampu'],
//             //   'namasemester': pengampuData['namasemester'],
//             //   'namapengampu': pengampuData['namapengampu'],
//             //   'idpengampu': pengampuData['idpengampu'],
//             //   'emailpenginput': emailAdmin,
//             //   'idpenginput': idUser,
//             //   'tanggalinput': DateTime.now().toIso8601String(),
//             //   'idsiswa': nisnSiswa,
//             // });
//             // print('SIMPAN DATA SISWA PADA (PENGAMPU BARU)');

//             // BUAT TEMPAT di firebase MURID PINDAHAN HALAQOH PADA DATABASE
//             await firestore
//                 .collection('Sekolah')
//                 .doc(idSekolah)
//                 .collection('tahunajaran')
//                 .doc(tahunAjaranPengampu)
//                 .collection('semester')
//                 .doc(pengampuData['namasemester'])
//                 .collection('pindahan')
//                 // .doc(docIdPindah)
//                 .doc(uid)
//                 .set({
//                   'ummi' : pengampuData['ummi'],
//                   'namasiswa': namasiswa,
//                   'nisn': nisnSiswa,
//                   'kelas': kelassiswa,
//                   'fase': pengampuData['fase'],
//                   'emailpenginput': emailAdmin,
//                   'idpenginput': idUser,
//                   'tanggalpindah': DateTime.now().toIso8601String(),
//                   'halaqohlama': currentPengampuData['namapengampu'],
//                   'tempathalaqohlama': currentPengampuData['tempatmengaji'],
//                   'halaqohbaru': pengampuData['namapengampu'],
//                   'tempathalaqohbaru': pengampuData['tempatmengaji'],
//                   'alasanpindah': alasanC.text,
//                   'idsiswa': nisnSiswa,
//                 });

//             //HAPUS DATA PADA PENGAMPU LAMA
//             // jika ada nilai pada siswa di pengampu lama, maka hapus semua data nilai pada pengampu lama

//             DocumentSnapshot<Map<String, dynamic>> docSnapIdSiswa =
//                 await firestore
//                     .collection('Sekolah')
//                     .doc(idSekolah)
//                     .collection('tahunajaran')
//                     .doc(tahunAjaranPengampu)
//                     // .collection('semester')
//                     // .doc(pengampuData['namasemester'])
//                     .collection('kelompokmengaji')
//                     .doc(pengampuData['fase'])
//                     .collection('pengampu')
//                     .doc(currentPengampuData['namapengampu'])
//                     .collection('tempat')
//                     .doc(currentPengampuData['tempatmengaji'])
//                     .collection('daftarsiswa')
//                     .doc(nisnSiswa)
//                     .get();

//             // ignore: prefer_is_empty
//             if (element.id.isNotEmpty || element.id.length != 0) {
//               await firestore
//                   .collection('Sekolah')
//                   .doc(idSekolah)
//                   .collection('tahunajaran')
//                   .doc(tahunAjaranPengampu)
//                   .collection('kelompokmengaji')
//                   .doc(pengampuData['fase'])
//                   .collection('pengampu')
//                   .doc(currentPengampuData['namapengampu'])
//                   .collection('tempat')
//                   .doc(currentPengampuData['tempatmengaji'])
//                   .collection('daftarsiswa')
//                   .doc(nisnSiswa)
//                   .collection('semester')
//                   .doc(pengampuData['namasemester'])
//                   .collection('nilai')
//                   .get()
//                   .then((querySnapshot) {
//                     querySnapshot.docs.forEach((doc) async {
//                       await firestore
//                           .collection('Sekolah')
//                           .doc(idSekolah)
//                           .collection('tahunajaran')
//                           .doc(tahunAjaranPengampu)
//                           .collection('kelompokmengaji')
//                           .doc(pengampuData['fase'])
//                           .collection('pengampu')
//                           .doc(currentPengampuData['namapengampu'])
//                           .collection('tempat')
//                           .doc(currentPengampuData['tempatmengaji'])
//                           .collection('daftarsiswa')
//                           .doc(nisnSiswa)
//                           .collection('semester')
//                           .doc(pengampuData['namasemester'])
//                           .collection('nilai')
//                           .doc(doc.id)
//                           .delete();
//                     });
//                   });
//             }

//             if (docSnapIdSiswa.exists) {
//               //HAPUS DATA PADA PENGAMPU LAMA
//               await firestore
//                   .collection('Sekolah')
//                   .doc(idSekolah)
//                   .collection('tahunajaran')
//                   .doc(tahunAjaranPengampu)
//                   // .collection('semester')
//                   // .doc(pengampuData['namasemester'])
//                   .collection('kelompokmengaji')
//                   .doc(pengampuData['fase'])
//                   .collection('pengampu')
//                   .doc(currentPengampuData['namapengampu'])
//                   .collection('tempat')
//                   .doc(currentPengampuData['tempatmengaji'])
//                   .collection('daftarsiswa')
//                   .doc(nisnSiswa)
//                   .delete();
//             }

            

//             //UBAH DATA PADA DOCUMENT SISWA
//             await firestore
//                 .collection('Sekolah')
//                 .doc(idSekolah)
//                 .collection('siswa')
//                 .doc(nisnSiswa)
//                 .collection('tahunajarankelompok')
//                 .doc(tahunAjaranPengampu)
//                 // .collection('semester')
//                 // .doc(currentPengampuData['namasemester'])
//                 .collection('kelompokmengaji')
//                 .doc(currentPengampuData['fase'])
//                 .update({
//                   "idpengampu": pengampuData['idpengampu'],
//                   "kelompokmengaji": pengampuData['namapengampu'],
//                   "namapengampu": pengampuData['namapengampu'],
//                   "tempatmengaji": pengampuData['tempatmengaji'],
//                   "pernahpindah": "iya",
//                 });

//             //DELETED SEMESTER LAMA PADA SISWA
//             await firestore
//                 .collection('Sekolah')
//                 .doc(idSekolah)
//                 .collection('siswa')
//                 .doc(nisnSiswa)
//                 .collection('tahunajarankelompok')
//                 .doc(tahunAjaranPengampu)
//                 // .collection('semester')
//                 // .doc(pengampuData['namasemester'])
//                 .collection('kelompokmengaji')
//                 .doc(pengampuData['fase'])
//                 .collection('pengampu')
//                 .doc(currentPengampuData['namapengampu'])
//                 .collection('tempat')
//                 .doc(currentPengampuData['tempatmengaji'])
//                 .collection('semester')
//                 .doc(pengampuData['namasemester'])
//                 .delete();

//             //DELETED TEMPAT LAMA PADA SISWA
//             await firestore
//                 .collection('Sekolah')
//                 .doc(idSekolah)
//                 .collection('siswa')
//                 .doc(nisnSiswa)
//                 .collection('tahunajarankelompok')
//                 .doc(tahunAjaranPengampu)
//                 // .collection('semester')
//                 // .doc(pengampuData['namasemester'])
//                 .collection('kelompokmengaji')
//                 .doc(pengampuData['fase'])
//                 .collection('pengampu')
//                 .doc(currentPengampuData['namapengampu'])
//                 .collection('tempat')
//                 .doc(currentPengampuData['tempatmengaji'])
//                 .delete();

//             // BUAT TEMPAT BARU PADA SISWA
//             await firestore
//                 .collection('Sekolah')
//                 .doc(idSekolah)
//                 .collection('siswa')
//                 .doc(nisnSiswa)
//                 .collection('tahunajarankelompok')
//                 .doc(tahunAjaranPengampu)
//                 // .collection('semester')
//                 // .doc(pengampuData['namasemester'])
//                 .collection('kelompokmengaji')
//                 .doc(pengampuData['fase'])
//                 .collection('tempat')
//                 .doc(pengampuData['tempatmengaji'])
//                 .set({
//                   'nisn': nisnSiswa,
//                   'tempatmengaji': pengampuData['tempatmengaji'],
//                   'fase': pengampuData['fase'],
//                   'tahunajaran': pengampuData['tahunajaran'],
//                   'kelompokmengaji': pengampuData['namapengampu'],
//                   'namasemester': pengampuData['namasemester'],
//                   'namapengampu': pengampuData['namapengampu'],
//                   'idpengampu': pengampuData['idpengampu'],
//                   'emailpenginput': emailAdmin,
//                   'idpenginput': idUser,
//                   'tanggalinput': DateTime.now().toIso8601String(),
//                 });

//             // BUAT SEMESTER BARU PADA SISWA
//             // BUAT TEMPAT BARU PADA SISWA
//             await firestore
//                 .collection('Sekolah')
//                 .doc(idSekolah)
//                 .collection('siswa')
//                 .doc(nisnSiswa)
//                 .collection('tahunajarankelompok')
//                 .doc(tahunAjaranPengampu)
//                 // .collection('semester')
//                 // .doc(pengampuData['namasemester'])
//                 .collection('kelompokmengaji')
//                 .doc(pengampuData['fase'])
//                 .collection('tempat')
//                 .doc(pengampuData['tempatmengaji'])
//                 .collection('semester')
//                 .doc(pengampuData['namasemester'])
//                 .set({
//                   'nisn': nisnSiswa,
//                   'tempatmengaji': pengampuData['tempatmengaji'],
//                   'fase': pengampuData['fase'],
//                   'tahunajaran': pengampuData['tahunajaran'],
//                   'kelompokmengaji': pengampuData['namapengampu'],
//                   'namasemester': pengampuData['namasemester'],
//                   'namapengampu': pengampuData['namapengampu'],
//                   'idpengampu': pengampuData['idpengampu'],
//                   'emailpenginput': emailAdmin,
//                   'idpenginput': idUser,
//                   'tanggalinput': DateTime.now().toIso8601String(),
//                 });
//           }
//         }

//         Get.back();
//         Get.snackbar('Berhasil', 'berhasil memindahkan siswa');
//       }
//     }
//   }
// }
