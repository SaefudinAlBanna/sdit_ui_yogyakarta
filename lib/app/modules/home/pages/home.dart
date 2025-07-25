import 'dart:ui'; // Diperlukan untuk ImageFilter.blur
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../models/jurnal_model.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';
import '../../../widgets/future_options_dialog.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang gradien yang halus untuk seluruh halaman
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.grey.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: controller.streamUserProfile(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final userData = userSnapshot.data!.data() ?? {};
              return CustomScrollView(
                slivers: [
                  _ProfileHeader(userData: userData),
                  _MenuGrid(userData: userData, onShowAllMenus: () => _showAllMenus(context, userData)),
                  const _SectionHeader(title: "Jurnal Kelas Hari Ini"),
                  _JurnalCarousel(),
                  const _SectionHeader(title: "Informasi Sekolah", showSeeAll: true),
                  _InformasiList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              );
            },
          );
        }),
      ),
    );
  }
}

// --- WIDGET-WIDGET KOMPONEN ---

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;
  const _ProfileHeader({required this.userData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String? imageUrlFromDb = userData['profileImageUrl'];
    final String alias = (userData['alias'] as String?)?.toUpperCase() ?? 'USER';
    final String namaLengkap = userData['alias'] ?? 'Nama Pengguna';

    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue[800],
      elevation: 2,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Latar belakang dengan gambar dan gradien
            Image.asset("assets/pictures/sekolah.jpg", fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Konten header
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0, top: 60.0), // Padding untuk konten
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundImage: CachedNetworkImageProvider(
                        imageUrlFromDb != null && imageUrlFromDb.isNotEmpty
                            ? imageUrlFromDb
                            : "https://ui-avatars.com/api/?name=$alias&background=random&color=fff",
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    namaLengkap,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [const Shadow(blurRadius: 2, color: Colors.black38)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Selamat Datang Kembali!",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAllMenus(BuildContext context, Map<String, dynamic> userData) {
  final controller = Get.find<HomeController>();
  // Daftar semua menu yang mungkin ada
  final List<Widget> allMenuItems = [
    
    // if (controller.userRole.value == 'Kepala Sekolah' || controller.userRole.value == 'Admin')
  //   if (controller.isSuperUser)
  // _MenuItem(
  //   title: 'Pesan Akhir Sekolah',
  //   imagePath: "assets/png/update_waktu.png", // Ganti ikon jika perlu
  //   onTap: () {
  //     Get.back(); // Tutup bottom sheet menu
  //     // Panggil dialog untuk edit
  //     final pesanC = TextEditingController(text: controller.pesanAkhirSekolahKustom.value);
  //     Get.defaultDialog(
  //       title: "Ubah Pesan Akhir Sekolah",
  //       content: TextField(
  //         controller: pesanC,
  //         autofocus: true,
  //         maxLines: 4,
  //         decoration: const InputDecoration(labelText: "Pesan untuk ditampilkan", border: OutlineInputBorder()),
  //       ),
  //       confirm: ElevatedButton(
  //         onPressed: () {
  //           controller.simpanPesanAkhirSekolah(pesanC.text.trim());
  //           Get.back();
  //         },
  //         child: const Text("Simpan"),
  //       ),
  //       cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
  //     );
  //   },
  // ),
  //   if (controller.userRole.value == 'Koordinator Halaqoh' || controller.userRole.value =='Admin')
  //   _MenuItem(title: 'Tambah Tahsin', imagePath: "assets/png/daftar_list.png", onTap: () {
  //     Get.back();
  //     Get.toNamed(Routes.TAMBAH_KELOMPOK_MENGAJI);}),
    if( controller.isAdmin || controller.isDalang)
    _MenuItem(title: 'Ekskul', imagePath: "assets/png/play.png", onTap: () { Get.toNamed(Routes.DAFTAR_EKSKUL);}),
    // if (controller.userRole.value == 'Koordinator Halaqoh' || controller.userRole.value =='Admin')
    // _MenuItem(title: 'Tahsin Tahfidz', imagePath: "assets/png/daftar_tes.png", onTap: () { Get.toNamed(Routes.DAFTAR_HALAQOH_PERFASE);}),
    
    // if (controller.userRole.value == 'Koordinator Halaqoh' || controller.userRole.value =='Admin')
    if(controller.canManageTahsin || controller.isDalang)
    _MenuItem(title: 'Siap Ujian', imagePath: "assets/png/play.png", onTap: () { Get.toNamed(Routes.LAKSANAKAN_UJIAN);}),

    if (controller.isAdmin || controller.isDalang)
    _MenuItem(title: 'Bayar SPP', imagePath: "assets/png/uang.png", onTap: () {
      Get.toNamed(Routes.PEMBAYARAN_SPP);
    }),
    if (controller.isAdminKepsek || controller.isDalang)
    _MenuItem(title: 'Tambah Info', imagePath: "assets/png/tumpukan_buku.png", onTap: () {
    
      Get.back();
      Get.toNamed(Routes.INPUT_INFO_SEKOLAH);}),
    
    _MenuItem(title: 'Daftar Jurnal', imagePath: "assets/png/tumpukan_buku.png", onTap: () {
      Get.back();
      Get.toNamed(Routes.DAFTAR_JURNAL_AJAR);}),
    // if (controller.userRole.value == 'Admin' || controller.userRole.value == 'Koordinator Halaqoh')

    if(controller.isAdminKepsek || controller.canManageTahsin || controller.isDalang)
    _MenuItem(title: 'Pemberian Mapel Guru', imagePath: "assets/png/jurnal_ajar.png",
          onTap: () {
            // Tutup bottom sheet menu dulu, lalu langsung navigasi tanpa argumen.
            Get.back(); 
            Get.toNamed(Routes.PEMBERIAN_GURU_MAPEL);
          },
        ),
    
    if (controller.isAdmin || controller.canManageTahsin || controller.isDalang)
    _MenuItem(title: 'Tambah Siswa', imagePath: "assets/png/jurnal_ajar.png", onTap: () { Get.toNamed(Routes.TAMBAH_SISWA);}),
    
    _MenuItem(title: 'Daftar Pegawai', imagePath: "assets/png/kamera_layar.png", onTap: () { Get.toNamed(Routes.DAFTAR_PEGAWAI); }),
    

    if (controller.isAdmin || controller.canManageTahsin || controller.isDalang)
    _MenuItem(title: 'Tambah Kelas', imagePath: "assets/png/layar.png", onTap: () { Get.back(); Get.toNamed(Routes.PEMBERIAN_KELAS_SISWA); }),
    
    if (controller.isDalang)
    _MenuItem(title: 'Tahun Ajaran', imagePath: "assets/png/layar_list.png", onTap: () {
     Get.defaultDialog(
                                              onCancel: () {
                                                Get.back();
                                              },
                                              title: 'Tahun Ajaran Baru',
                                              middleText:
                                                  'Silahkan tambahkan tahun ajaran baru',
                                              content: Column(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'tahun ajaran baru',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: 10),
                                                      TextField(
                                                        textCapitalization:
                                                            TextCapitalization
                                                                .sentences,
                                                        controller:
                                                            controller
                                                                .tahunAjaranBaruC,
                                                        decoration: InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          labelText:
                                                              'Tahun Ajaran',
                                                        ),
                                                      ),
                                                      SizedBox(height: 20),
                                                      Center(
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            controller
                                                                .simpanTahunAjaran();
                                                            Get.back();
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      40,
                                                                  vertical: 15,
                                                                ),
                                                            textStyle:
                                                                TextStyle(
                                                                  fontSize: 16,
                                                                ),
                                                          ),
                                                          child: Text('Simpan'),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },),
    // _MenuItem(title: 'Tanggapan Catatan (KS, WK)', imagePath: "assets/png/update_waktu.png", onTap: () {
    //   Get.toNamed(Routes.TANGGAPAN_CATATAN);
    // }),
    

    if (controller.isDalang)
    _MenuItem(title: 'Rekapitulasi Sekolah', imagePath: "assets/png/layar.png", onTap: () { Get.toNamed(Routes.REKAPITULASI_PEMBAYARAN); }),
    
    if (controller.isDalang)
    _MenuItem(title: 'Rekapitulasi Rinci', imagePath: "assets/png/kamera_layar.png", onTap: () { Get.toNamed(Routes.REKAPITULASI_PEMBAYARAN_RINCI); }),
    
    if (controller.canManageTahsin || controller.canManageTahsin || controller.isDalang)
    _MenuItem(title: 'Buat Jadwal Pelajaran', imagePath: "assets/png/papan_list.png", onTap: () { Get.toNamed(Routes.BUAT_JADWAL_PELAJARAN); }),
    
    if (controller.isAdmin || controller.canManageTahsin || controller.isDalang)
    _MenuItem(title: 'Input Sarpras', imagePath: "assets/png/tumpukan_buku.png", onTap: () { Get.toNamed(Routes.BUAT_SARPRAS); }),
    _MenuItem(title: 'Info Sarpras', imagePath: "assets/png/toga_lcd.png", onTap: () { Get.toNamed(Routes.DATA_SARPRAS); }),
    
    if (controller.isAdmin || controller.canManageTahsin || controller.isDalang)
    _MenuItem(title: 'Import Siswa Excel', imagePath: "assets/png/layar.png", onTap: () { Get.toNamed(Routes.IMPORT_SISWA_EXCEL); }),
    
    if (controller.isAdmin || controller.canManageTahsin || controller.isDalang)
    _MenuItem(title: 'Import Pegawai Excel', imagePath: "assets/png/toga_lcd.png", onTap: () { Get.toNamed(Routes.IMPORT_PEGAWAI); }),
    // _MenuItem(title: 'Hapus Pegawai', imagePath: "assets/png/update_waktu.png", onTap: () { }),
    // _MenuItem(title: 'Hapus Siswa', imagePath: "assets/png/ktp.png", onTap: () { }),
    // _MenuItem(title: 'Absen', imagePath: "assets/png/layar.png", onTap: () {Get.toNamed(Routes.ABSENSI); }),
    _MenuItem(title: 'Jurnal Guru', imagePath: "assets/png/layar.png", onTap: () {Get.toNamed(Routes.REKAP_JURNAL_GURU); }),
     _MenuItem(title: 'Jurnal Admin', imagePath: "assets/png/layar.png", onTap: () {Get.toNamed(Routes.REKAP_JURNAL_ADMIN); }),
    _MenuItem(
  title: 'Perangkat Ajar',
  imagePath: "assets/png/jurnal_ajar.png", // Ganti dengan ikon yang sesuai
  onTap: () {
    Get.back(); // Tutup bottom sheet
    Get.toNamed(Routes.PERANGKAT_AJAR); // Navigasi ke halaman baru Anda
  },
),
    // ... tambahkan semua menu lainnya di sini
  ];

  Get.bottomSheet(
    Container(
      height: MediaQuery.of(context).size.height * 0.5, // Setengah layar
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle untuk drag
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Judul
          const Text("Semua Menu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Grid untuk menu
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allMenuItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 15,
                mainAxisSpacing: 5,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                return allMenuItems[index];
              },
            ),
          ),
        ],
      ),
    ),
    isScrollControlled: true, // Penting agar bisa set tinggi
  );
}

class _MenuGrid extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onShowAllMenus;
  const _MenuGrid({required this.userData, required this.onShowAllMenus});
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid.count(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
        children: [
          if(controller.informasiKelas)
           _MenuItem(
                title: 'Informasi Kelas',
                imagePath: "assets/png/tas.png",
                onTap: () {
                  // Langsung navigasi ke halaman tujuan, tanpa dialog, tanpa argumen.
                  Get.toNamed(Routes.DAFTAR_KELAS);
                },
              ),

              // if(controller.kelasTahsin)
            _MenuItem(
                title: 'Kelas Tahsin',
                imagePath: "assets/png/toga_lcd.png",
                onTap: () {
                  // Terapkan logika kondisional
                  if (controller.kelasTahsin) {
                    Get.toNamed(Routes.DAFTAR_HALAQOH_PENGAMPU);
                  } else if (controller.kapten || controller.canManageTahsin || controller.isAdminKepsek) {
                    Get.toNamed(Routes.DAFTAR_HALAQOH_PERFASE);
                  } else {
                    Get.snackbar("Informasi", "Maaf, kelas khusus Tahsin");
                  }
                },
              ),
              _MenuItem(
                title: 'Tahfidz Kelas',
                imagePath: "assets/png/toga_lcd.png",
                onTap: () {
                    // Cek jika pengguna adalah Pimpinan
                    if (controller.isPimpinan) {
                      // Arahkan ke dasbor pemantauan BARU
                      Get.toNamed(Routes.PANTAU_TAHFIDZ); // Anda perlu menambahkan route ini di app_pages.dart
                    } 
                    // Cek jika pengguna adalah Guru (Wali Kelas atau Pendamping)
                    else if (controller.tahfidzKelas) {
                      // Arahkan ke halaman operasional yang sudah ada
                      Get.toNamed(Routes.KELAS_TAHFIDZ);
                    } 
                    // Jika bukan keduanya
                    else {
                    // Pesan ini sekarang berlaku untuk semua yang tidak punya akses.
                    Get.snackbar("Akses Ditolak", "Fitur ini khusus untuk kelas Tahfidz.");
                  }
                },
              ),
            _MenuItem(
              title: 'Jurnal Harian',
              imagePath: "assets/png/faq.png",
              onTap: () { 
                if(controller.jurnalHarian || controller.isDalang) {
                Get.toNamed(Routes.JURNAL_AJAR_HARIAN, arguments: userData);
                } else if (controller.isKepsek) {
                  // Get.snackbar("Info", "Ini buat kepala sekolah");
                  Get.toNamed(Routes.REKAP_JURNAL_ADMIN);
                } else {
                  Get.snackbar("Info", "Maaf, khusus jurnal harian");
                }
              }
            ),

            _MenuItem(
              title: 'Catatan Siswa(BK)',
              imagePath: "assets/png/daftar_list.png",
              onTap: () { 
                if(controller.walikelas || controller.isKepsek || controller.guruBK || controller.isDalang) {
                Get.toNamed(Routes.CATATAN_SISWA); 
                } else {
                  Get.snackbar("Info", "Maaf, khusus catatan siswa");
                }
              }
            ),
            _MenuItem(
              title: 'Jadwal',
              imagePath: "assets/png/pengumuman.png",
              onTap: () => Get.toNamed(Routes.JADWAL_PELAJARAN),
            ),
            _MenuItem(
              title: 'Kalender',
              imagePath: "assets/png/papan_list.png",
              onTap: () => Get.toNamed(Routes.KALENDER_AKADEMIK, arguments: userData),
            ),
            // _MenuItem(
            //   title: 'Tambah Info',
            //   imagePath: "assets/png/tumpukan_buku.png",
            //   onTap: () => Get.toNamed(Routes.INPUT_INFO_SEKOLAH),
            // ),
            _MenuItem(
              title: 'Lainnya',
              imagePath: "assets/png/layar.png",
              onTap: onShowAllMenus,
            ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;
  const _MenuItem({required this.title, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SingleChildScrollView(
        child: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), spreadRadius: 2, blurRadius: 10)],
      ),
      child: Image.asset(imagePath, width: 32, height: 32),
    ),
    // --- Kurangi spasi vertikal sedikit ---
    const SizedBox(height: 4), // Diubah dari 8 menjadi 4

    // --- Atau, kurangi ukuran font sedikit ---
    Text(
      title, 
      textAlign: TextAlign.center, 
      // Diubah dari 11 menjadi 10.5 atau 10
      style: const TextStyle(fontSize: 10.5, height: 1.2), 
      maxLines: 2, 
      overflow: TextOverflow.ellipsis
    ),
  ],
),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  const _SectionHeader({required this.title, this.showSeeAll = false});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            if (showSeeAll) TextButton(onPressed: () {}, child: const Text("Lihat Semua")),
          ],
        ),
      ),
    );
  }
}

class _JurnalCarousel extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    if (controller.kelasAktifList.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 160,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: Text("Anda tidak mengajar di kelas manapun.")),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: CarouselSlider.builder(
        itemCount: controller.kelasAktifList.length,
        itemBuilder: (context, index, realIndex) => _JurnalCard(kelasDoc: controller.kelasAktifList[index]),
        options: CarouselOptions(
          height: 200, // Tinggi card ditambah sedikit
          viewportFraction: 0.92,
          enlargeCenterPage: true,
          enableInfiniteScroll: controller.kelasAktifList.length > 1,
          autoPlay: controller.kelasAktifList.length > 1,
          autoPlayInterval: const Duration(seconds: 10),
        ),
      ),
    );
  }
}

class _JurnalCard extends GetView<HomeController> {
  final DocumentSnapshot<Map<String, dynamic>> kelasDoc;
  const _JurnalCard({required this.kelasDoc});

  // --- BUAT FUNGSI DIALOG DI SINI ---
  void _showEditPesanLiburDialog(BuildContext context, String pesanSaatIni) {
    final TextEditingController pesanC = TextEditingController(text: pesanSaatIni);
    Get.defaultDialog(
      title: "Ubah Pesan Libur",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          controller: pesanC,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Pesan untuk orang tua",
            border: OutlineInputBorder(),
          ),
        ),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          if (pesanC.text.trim().isNotEmpty) {
            controller.simpanPesanLibur(pesanC.text.trim());
            Get.back(); // Tutup dialog
          } else {
            Get.snackbar("Peringatan", "Pesan tidak boleh kosong.");
          }
        },
        child: const Text("Simpan"),
      ),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String namaKelas = kelasDoc.data()?['namakelas'] ?? 'N/A';
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Kartu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(namaKelas, style: theme.textTheme.titleLarge?.copyWith(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              controller.jamPelajaranDocId.value,
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                          )),
                    ],
                  ),
                  const Spacer(), // Memberi ruang dinamis
                  // Konten Jurnal
                  Expanded(
                    flex: 3,
                    child: Obx(() => StreamBuilder<JurnalModel?>(
                          stream: controller.streamJurnalDetail(kelasDoc.id),
                          builder: (context, snapJurnal) {
                            if (snapJurnal.connectionState == ConnectionState.waiting) {
                              return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
                            }
                            final JurnalModel? dataJurnal = snapJurnal.data;
                            if (dataJurnal == null) {
                              return const Center(child: Text("Jurnal untuk jam ini belum diisi.", style: TextStyle(color: Colors.black54)));
                            }
                             // KASUS 1: INI ADALAH KARTU PESAN LIBUR
                    if (dataJurnal.jampelajaran == "Hari Libur") {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dataJurnal.materipelajaran ?? "Selamat Berlibur!",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          // Tampilkan tombol Edit HANYA untuk Kepala Sekolah
                          Obx(() {
                            if (controller.userRole.value == 'Kepala Sekolah') {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: ActionChip(
                                  avatar: const Icon(Icons.edit, size: 16),
                                  label: const Text("Ubah Pesan"),
                                  onPressed: () => _showEditPesanLiburDialog(
                                    context,
                                    dataJurnal.materipelajaran ?? "",
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink(); // Widget kosong untuk role lain
                            }
                          }),
                        ],
                      );
                    }

                    // KASUS 2: INI ADALAH KARTU JURNAL BIASA
                    // (Kode lama Anda untuk menampilkan jurnal, sudah benar)
                    return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Materi Pelajaran (Info Utama)
                                Text(
                                  dataJurnal.materipelajaran ?? 'Materi belum tersedia',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                // Nama Pengajar (Info Sekunder)
                                Row(
                                  children: [
                                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      dataJurnal.namapenginput ?? 'Pengajar tidak diketahui',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
                                    ),
                                  ],
                                ),
                                
                                // --- TAMBAHAN BARU: Tampilkan Catatan Jurnal ---
                                // Cek jika catatan ada dan tidak kosong
                                if (dataJurnal.catatanjurnal != null && dataJurnal.catatanjurnal!.trim().isNotEmpty) ...[
                                  const Divider(height: 12, thickness: 0.5), // Garis pemisah tipis
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.notes_rounded, size: 14, color: Colors.black54),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          dataJurnal.catatanjurnal!,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.black.withOpacity(0.7),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ]
                              ],
                            );
                          },
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InformasiList extends GetView<HomeController> {
  // Kode untuk _InformasiList tidak perlu diubah, sudah cukup baik.
  // ... (salin kode _InformasiList Anda yang lama di sini)
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: controller.streamInformasiSekolah(),
      builder: (context, snapInfo) {
        if (snapInfo.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        if (!snapInfo.hasData || snapInfo.data!.docs.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Belum ada informasi.'))));
        
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList.separated(
            itemCount: snapInfo.data!.docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final dataInfo = snapInfo.data!.docs[index].data();
              String formattedDate = "Tanggal tidak valid";
              // ... (kode format tanggal Anda)
               if (dataInfo['tanggalinput'] is String) {
                try {
                  final dt = DateTime.parse(dataInfo['tanggalinput']);
                  formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(dt);
                } catch(e) {/* biarkan default */}
              }

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Get.toNamed(Routes.TAMPILKAN_INFO_SEKOLAH, arguments: dataInfo),
                  child: Row( /* ... konten Anda ... */ 
                     children: [
                      CachedNetworkImage(
                        imageUrl: dataInfo['url_gambar'] ?? "https://picsum.photos/id/${index + 356}/200/200",
                        width: 100, height: 100, fit: BoxFit.cover,
                        placeholder: (c, u) => Container(color: Colors.grey.shade200),
                        errorWidget: (c, u, e) => const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dataInfo['judulinformasi'], style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(dataInfo['informasisekolah'], style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(Icons.access_time_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(formattedDate, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                              ])
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}