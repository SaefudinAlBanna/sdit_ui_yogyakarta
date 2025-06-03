import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DaftarHalaqohnyaController extends GetxController {
  var dataMapArgumen = Get.arguments;

  RxBool isLoading = false.obs;

  TextEditingController pengampuC = TextEditingController();
  TextEditingController kelasSiswaC = TextEditingController();
  TextEditingController alasanC = TextEditingController();
  TextEditingController umiC = TextEditingController();
  TextEditingController umidrawerC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  String idUser = FirebaseAuth.instance.currentUser!.uid;
  String idSekolah = '20404148';
  String emailAdmin = FirebaseAuth.instance.currentUser!.email!;

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

  Stream<QuerySnapshot<Map<String, dynamic>>> getDataSiswaHalaqoh() async* {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(dataMapArgumen['fase'])
        .collection('pengampu')
        .doc(dataMapArgumen['namapengampu'])
        .collection('tempat')
        .doc(dataMapArgumen['tempatmengaji'])
        .collection('daftarsiswa')
        .snapshots();
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
        .where('fase', isEqualTo: dataMapArgumen['fase'])
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
    // ... (kode Anda sepertinya OK, tapi pastikan 'dataMapArgumen' punya semua field yang dibutuhkan)
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
          .doc(dataMapArgumen['fase'])
          .collection('pengampu')
          .doc(dataMapArgumen['namapengampu'])
          .collection('tempat')
          .doc(dataMapArgumen['tempatmengaji'])
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
          .doc(dataMapArgumen['fase'])
          .collection('pengampu')
          .doc(dataMapArgumen['namapengampu'])
          .collection('tempat')
          .doc(dataMapArgumen['tempatmengaji'])
          .collection('semester')
          .doc(
            'Semester I',
          ); // Asumsi Semester I, pastikan ini dinamis jika perlu
      batch.update(ref2, {'ummi': umiC.text});

      // Path 3 (jika ada path nilai spesifik per semester di daftarsiswa)
      DocumentReference ref3 = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataMapArgumen['fase'])
          .collection('pengampu')
          .doc(dataMapArgumen['namapengampu'])
          .collection('tempat')
          .doc(dataMapArgumen['tempatmengaji'])
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
          .doc(dataMapArgumen['fase'])
          .collection('pengampu')
          .doc(dataMapArgumen['namapengampu'])
          .collection('tempat')
          .doc(dataMapArgumen['tempatmengaji'])
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
          .doc(dataMapArgumen['fase'])
          .collection('pengampu')
          .doc(dataMapArgumen['namapengampu'])
          .collection('tempat')
          .doc(dataMapArgumen['tempatmengaji'])
          .collection('semester')
          .doc('Semester I');
      batch.update(ref2, {'ummi': umidrawerC.text});

      DocumentReference ref3 = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataMapArgumen['fase'])
          .collection('pengampu')
          .doc(dataMapArgumen['namapengampu'])
          .collection('tempat')
          .doc(dataMapArgumen['tempatmengaji'])
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

  Future<void> simpanSiswaKelompok(String namaSiswa, String nisnSiswa) async {
    // ... (kode Anda sepertinya OK, tapi sangat panjang. Pertimbangkan WriteBatch)
    // Pastikan semua dataMapArgumen[...] dan kelasSiswaC.text tersedia dan benar.
    // Gunakan try-catch dan WriteBatch untuk atomicity
    isLoading.value = true;
    try {
      String tahunajaranya = await getTahunAjaranTerakhir();
      String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

      QuerySnapshot<Map<String, dynamic>> querySnapshotKelompok =
          await firestore
              .collection('Sekolah')
              .doc(idSekolah)
              .collection('pegawai')
              .where('alias', isEqualTo: dataMapArgumen['namapengampu'])
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
      String semesterSaatIni =
          "Semester I"; // Asumsi, buat ini dinamis jika perlu

      // 1. Simpan di daftarsiswa pengampu
      DocumentReference refDaftarSiswaPengampu = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataMapArgumen['fase'])
          .collection('pengampu')
          .doc(dataMapArgumen['namapengampu'])
          .collection('tempat')
          .doc(dataMapArgumen['tempatmengaji'])
          .collection('daftarsiswa')
          .doc(nisnSiswa);
      batch.set(refDaftarSiswaPengampu, {
        'ummi': "0", // Default UMMI
        'namasiswa': namaSiswa,
        'nisn': nisnSiswa,
        'kelas': kelasSiswaC.text,
        'fase': dataMapArgumen['fase'],
        'tempatmengaji': dataMapArgumen['tempatmengaji'],
        'tahunajaran':
            dataMapArgumen['tahunajaran'], // Seharusnya tahunajaranya dari getTahunAjaranTerakhir
        'kelompokmengaji': dataMapArgumen['namapengampu'],
        'namapengampu': dataMapArgumen['namapengampu'],
        'idpengampu':
            idPengampu, // Gunakan idPengampu yang didapat dari query pegawai
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
        'idsiswa': nisnSiswa,
      });

      // 1.1 Sub-koleksi semester di daftarsiswa pengampu
      DocumentReference refSemesterDaftarSiswa = refDaftarSiswaPengampu
          .collection('semester')
          .doc(semesterSaatIni);
      batch.set(refSemesterDaftarSiswa, {
        'ummi': "0",
        'namasiswa': namaSiswa,
        'nisn': nisnSiswa,
        'kelas': kelasSiswaC.text,
        'fase': dataMapArgumen['fase'],
        'tempatmengaji': dataMapArgumen['tempatmengaji'],
        'tahunajaran': tahunajaranya,
        'kelompokmengaji': dataMapArgumen['namapengampu'],
        'namasemester': semesterSaatIni,
        'namapengampu': dataMapArgumen['namapengampu'],
        'idpengampu': idPengampu,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
        'idsiswa': nisnSiswa,
      });

      // 2. Update data di bawah collection siswa
      DocumentReference refSiswaTahunAjaran = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran);
      batch.set(refSiswaTahunAjaran, {
        'fase': dataMapArgumen['fase'],
        'nisn': nisnSiswa,
        'namatahunajaran': tahunajaranya,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
      }, SetOptions(merge: true)); // Merge jika sudah ada data lain

      DocumentReference refSiswaKelompokMengaji = refSiswaTahunAjaran
          .collection('kelompokmengaji')
          .doc(dataMapArgumen['fase']);
      batch.set(refSiswaKelompokMengaji, {
        'fase': dataMapArgumen['fase'],
        'tempatmengaji': dataMapArgumen['tempatmengaji'],
        'namapengampu': dataMapArgumen['namapengampu'],
        'idpengampu': idPengampu,
        'tahunajaran': tahunajaranya,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
      }, SetOptions(merge: true));

      DocumentReference refSiswaPengampu = refSiswaKelompokMengaji
          .collection('pengampu')
          .doc(dataMapArgumen['namapengampu']);
      batch.set(refSiswaPengampu, {
        'nisn': nisnSiswa,
        'fase': dataMapArgumen['fase'],
        'tahunajaran': idTahunAjaran, // atau tahunajaranya
        'namapengampu': dataMapArgumen['namapengampu'],
        'idpengampu': idPengampu,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
      }, SetOptions(merge: true));

      DocumentReference refSiswaTempat = refSiswaPengampu
          .collection('tempat')
          .doc(dataMapArgumen['tempatmengaji']);
      batch.set(refSiswaTempat, {
        'nisn': nisnSiswa,
        'tempatmengaji': dataMapArgumen['tempatmengaji'],
        'fase': dataMapArgumen['fase'],
        'tahunajaran': idTahunAjaran, // atau tahunajaranya
        'namapengampu': dataMapArgumen['namapengampu'],
        'idpengampu': idPengampu,
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': tanggalInput,
      }, SetOptions(merge: true));

      DocumentReference refSiswaSemester = refSiswaTempat
          .collection('semester')
          .doc(semesterSaatIni);
      batch.set(refSiswaSemester, {
        'ummi': "0",
        'nisn': nisnSiswa,
        'tempatmengaji': dataMapArgumen['tempatmengaji'],
        'fase': dataMapArgumen['fase'],
        'tahunajaran': idTahunAjaran, // atau tahunajaranya
        'namasemester': semesterSaatIni,
        'namapengampu': dataMapArgumen['namapengampu'],
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

  Future<void> ubahStatusSiswa(String nisnSiSwa) async {
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

  Stream<QuerySnapshot<Map<String, dynamic>>> getDaftarHalaqohDrawer() async* {
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    yield* firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .doc(idTahunAjaran)
        .collection('kelompokmengaji')
        .doc(dataMapArgumen['fase'])
        .collection('pengampu')
        .doc(dataMapArgumen['namapengampu'])
        .collection('tempat')
        .doc(dataMapArgumen['tempatmengaji'])
        .collection('daftarsiswa')
        .where(
          'ummi',
          isNotEqualTo: umidrawerC.text,
        ) // Pastikan umidrawerC.text tidak kosong
        .snapshots();
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
            .doc(
              dataMapArgumen['fase'],
            ) // Asumsi fase tetap sama, jika bisa beda, ini perlu dipertimbangkan
            .collection('pengampu')
            .doc(pengampuC.text) // pengampuC.text adalah nama pengampu baru
            .get();
    return getPengampuNya;
  }

  Future<List<String>> getDataPengampuFase() async {
    // ... (kode Anda sudah benar)
    String tahunajaranya = await getTahunAjaranTerakhir();
    String idTahunAjaran = tahunajaranya.replaceAll("/", "-");

    List<String> pengampuList = [];
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await firestore
            .collection('Sekolah')
            .doc(idSekolah)
            .collection('tahunajaran')
            .doc(idTahunAjaran)
            .collection('kelompokmengaji')
            .doc(dataMapArgumen['fase'])
            .collection('pengampu')
            // .where('namapengampu', isNotEqualTo: dataMapArgumen['namapengampu']) // Bisa difilter di client side jika jumlahnya tidak banyak
            .get();

    for (var docSnapshot in querySnapshot.docs) {
      // Filter tambahan jika diperlukan (misal berdasarkan fase lagi, meskipun sudah di path)
      if (docSnapshot.data()['namapengampu'] !=
              dataMapArgumen['namapengampu'] &&
          docSnapshot.data()['fase'] == dataMapArgumen['fase']) {
        pengampuList.add(docSnapshot.data()['namapengampu']);
      }
    }
    return pengampuList;
  }

  Future<void> pindahkan(String nisnSiswa) async {
    if (pengampuC.text.isEmpty) {
      Get.snackbar('Peringatan', 'Pengampu baru belum dipilih.');
      return;
    }
    if (alasanC.text.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Alasan pindah kosong, silahkan diisi dahulu.',
      );
      return;
    }

    isLoading.value = true;
    try {
      String tahunAjaranAktif = await getTahunAjaranTerakhir();
      String idTahunAjaran = tahunAjaranAktif.replaceAll('/', '-');
      String semesterAktif = "Semester I"; // Asumsi, buat dinamis jika perlu

      WriteBatch batch = firestore.batch();

      // 1. Dapatkan data pengampu tujuan (baru)
      DocumentSnapshot<Map<String, dynamic>> snapPengampuBaru =
          await dataPengampuPindah();
      if (!snapPengampuBaru.exists) {
        throw Exception("Data pengampu tujuan tidak ditemukan.");
      }
      Map<String, dynamic> dataPengampuBaru = snapPengampuBaru.data()!;
      // Pastikan dataPengampuBaru memiliki field: 'fase', 'namapengampu', 'tempatmengaji', 'idpengampu', 'ummi' (jika ada default)

      // 2. Dapatkan data siswa dari pengampu lama
      DocumentReference refSiswaDiPengampuLama = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataMapArgumen['fase']) // FASE LAMA
          .collection('pengampu')
          .doc(dataMapArgumen['namapengampu']) // NAMA PENGAMPU LAMA
          .collection('tempat')
          .doc(dataMapArgumen['tempatmengaji']) // TEMPAT LAMA
          .collection('daftarsiswa')
          .doc(nisnSiswa);

      DocumentSnapshot<Map<String, dynamic>> snapSiswaLama =
          await refSiswaDiPengampuLama.get()
              as DocumentSnapshot<Map<String, dynamic>>;
      if (!snapSiswaLama.exists) {
        throw Exception("Data siswa di pengampu lama tidak ditemukan.");
      }
      Map<String, dynamic> dataSiswaYangDipindah = snapSiswaLama.data()!;
      String namaSiswa = dataSiswaYangDipindah['namasiswa'];
      String kelasSiswa = dataSiswaYangDipindah['kelas'];
      // String ummiSiswaLama = dataSiswaYangDipindah['ummi'] ?? "0"; // Ambil ummi lama

      // 3. Dapatkan nilai-nilai siswa dari semester di pengampu lama
      //    Path: /Sekolah/{idSekolah}/tahunajaran/{idTahunAjaran}/kelompokmengaji/{dataMapArgumen['fase']}/pengampu/{dataMapArgumen['namapengampu']}/tempat/{dataMapArgumen['tempatmengaji']}/daftarsiswa/{nisnSiswa}/semester/{semesterAktif}/nilai
      QuerySnapshot<Map<String, dynamic>> snapNilaiLama =
          await refSiswaDiPengampuLama
              .collection('semester')
              .doc(semesterAktif) // SEMESTER LAMA
              .collection('nilai')
              .get();

      List<Map<String, dynamic>> daftarNilaiLama = [];
      for (var docNilai in snapNilaiLama.docs) {
        daftarNilaiLama.add({...docNilai.data(), 'idNilai': docNilai.id});
      }

      // === OPERASI PADA PENGAMPU BARU ===
      // 4. Tambahkan siswa ke daftarsiswa pengampu baru
      DocumentReference refSiswaDiPengampuBaru = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataPengampuBaru['fase']) // FASE BARU
          .collection('pengampu')
          .doc(dataPengampuBaru['namapengampu']) // NAMA PENGAMPU BARU
          .collection('tempat')
          .doc(dataPengampuBaru['tempatmengaji']) // TEMPAT BARU
          .collection('daftarsiswa')
          .doc(nisnSiswa);

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
          .collection('semester')
          .doc(semesterAktif); // Atau dataPengampuBaru['namasemester'] jika ada

      batch.set(refSemesterDiPengampuBaru, {
        // Buat dokumen semester jika belum ada
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
        String idNilaiLama = nilai.remove(
          'idNilai',
        ); // Ambil dan hapus id dari map
        DocumentReference refNilaiBaru = refSemesterDiPengampuBaru
            .collection('nilai')
            .doc(idNilaiLama); // Gunakan ID lama agar tidak duplikat
        batch.set(refNilaiBaru, {
          ...nilai, // Salin semua data nilai lama
          // Update field yang relevan dengan pengampu baru jika perlu
          'fase': dataPengampuBaru['fase'],
          'tempatmengaji': dataPengampuBaru['tempatmengaji'],
          'kelompokmengaji': dataPengampuBaru['namapengampu'],
          'namapengampu': dataPengampuBaru['namapengampu'],
          'idpengampu': dataPengampuBaru['idpengampu'],
          'tanggalinput':
              nilai['tanggalinput'], // Pertahankan tanggal input nilai asli
        });
      }

      // === CATAT RIWAYAT PINDAH ===
      // 6. Buat catatan pindahan
      String idPindahan =
          firestore.collection('_placeholder_').doc().id; // Generate unique ID
      DocumentReference refRiwayatPindah = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idTahunAjaran)
          // .collection('semester').doc(semesterAktif) // Struktur riwayat pindah bisa disesuaikan
          .collection('riwayatpindahan')
          .doc(idPindahan); // Atau langsung di root 'pindahan'

      batch.set(refRiwayatPindah, {
        // 'ummi': ummiSiswaLama,
        'namasiswa': namaSiswa,
        'nisn': nisnSiswa,
        'kelas': kelasSiswa,
        'fase_lama': dataMapArgumen['fase'],
        'fase_baru': dataPengampuBaru['fase'],
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalpindah': DateTime.now().toIso8601String(),
        'pengampu_lama': dataMapArgumen['namapengampu'],
        'tempat_lama': dataMapArgumen['tempatmengaji'],
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
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataPengampuBaru['fase']); // FASE BARU (jika fase bisa berubah)
      // Jika fase selalu sama, gunakan dataMapArgumen['fase']

      batch.update(refKelompokDiSiswa, {
        // Asumsi dokumen ini sudah ada dari proses simpanSiswaKelompok
        "idpengampu": dataPengampuBaru['idpengampu'],
        "kelompokmengaji":
            dataPengampuBaru['namapengampu'], // alias nama pengampu
        "namapengampu": dataPengampuBaru['namapengampu'],
        "tempatmengaji": dataPengampuBaru['tempatmengaji'],
        "pernahpindah": "iya",
        // "fase": dataPengampuBaru['fase'], // jika fase di path atas adalah dataPengampuBaru['fase']
      });

      // Hapus struktur pengampu lama di bawah dokumen siswa
      DocumentReference refPengampuLamaDiSiswa = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataMapArgumen['fase']) // FASE LAMA
          .collection('pengampu')
          .doc(dataMapArgumen['namapengampu']); // NAMA PENGAMPU LAMA

      // Untuk menghapus subkoleksi, Anda perlu menghapus semua dokumen di dalamnya satu per satu.
      // Atau, jika Anda hanya ingin menghapus dokumen 'tempat' dan 'semester' di bawahnya:
      QuerySnapshot snapTempatLamaDiSiswa =
          await refPengampuLamaDiSiswa.collection('tempat').get();
      for (var docTempat in snapTempatLamaDiSiswa.docs) {
        QuerySnapshot snapSemesterLamaDiSiswa =
            await docTempat.reference.collection('semester').get();
        for (var docSemester in snapSemesterLamaDiSiswa.docs) {
          batch.delete(docSemester.reference);
        }
        batch.delete(docTempat.reference);
      }
      batch.delete(
        refPengampuLamaDiSiswa,
      ); // Hapus dokumen pengampu lama itu sendiri

      // Buat struktur pengampu baru di bawah dokumen siswa
      DocumentReference refPengampuBaruDiSiswa = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('siswa')
          .doc(nisnSiswa)
          .collection('tahunajarankelompok')
          .doc(idTahunAjaran)
          .collection('kelompokmengaji')
          .doc(dataPengampuBaru['fase']) // FASE BARU
          .collection('pengampu')
          .doc(dataPengampuBaru['namapengampu']); // NAMA PENGAMPU BARU
      batch.set(refPengampuBaruDiSiswa, {
        /* data relevan pengampu baru */
        'nisn': nisnSiswa,
        'fase': dataPengampuBaru['fase'],
        'tahunajaran': idTahunAjaran,
        'namapengampu': dataPengampuBaru['namapengampu'],
        'idpengampu': dataPengampuBaru['idpengampu'],
        'emailpenginput': emailAdmin,
        'idpenginput': idUser,
        'tanggalinput': DateTime.now().toIso8601String(),
      });

      DocumentReference refTempatBaruDiSiswa = refPengampuBaruDiSiswa
          .collection('tempat')
          .doc(dataPengampuBaru['tempatmengaji']);
      batch.set(refTempatBaruDiSiswa, {
        /* data relevan tempat baru */
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

      DocumentReference refSemesterBaruDiSiswa = refTempatBaruDiSiswa
          .collection('semester')
          .doc(semesterAktif);
      batch.set(refSemesterBaruDiSiswa, {
        /* data relevan semester baru */
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
          .collection('semester')
          .doc(semesterAktif); // SEMESTER LAMA
      for (var nilai in daftarNilaiLama) {
        batch.delete(
          refSemesterDiPengampuLama.collection('nilai').doc(nilai['idNilai']),
        );
      }
      // Hapus dokumen semester itu sendiri di pengampu lama jika sudah tidak ada nilai & tidak ada data lain yang penting
      // batch.delete(refSemesterDiPengampuLama); // Hati-hati jika ada data lain di doc semester ini

      // 9. Hapus siswa dari daftarsiswa pengampu lama
      batch.delete(refSiswaDiPengampuLama);

      // COMMIT SEMUA OPERASI
      await batch.commit();

      Get.back(); // Tutup dialog
      Get.snackbar(
        'Berhasil',
        '$namaSiswa berhasil dipindahkan ke ${dataPengampuBaru['namapengampu']}.',
      );
      pengampuC.clear();
      alasanC.clear();
    } catch (e) {
      Get.back(); // Tutup dialog jika masih terbuka
      Get.snackbar(
        'Error Pindah',
        'Gagal memindahkan siswa: ${e.toString()}',
        duration: Duration(seconds: 5),
      );
      print("Error pindahkan: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
