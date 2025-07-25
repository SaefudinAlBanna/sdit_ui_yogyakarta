// lib/app/modules/daftar_kelas/views/daftar_kelas_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// --- TAMBAHAN BARU: Import widget rekap absensi ---
import '../../rekap_absensi/views/rekap_absensi_view.dart';
import '../../rekap_absensi/controllers/rekap_absensi_controller.dart';
import '../../rekap_absensi/bindings/rekap_absensi_binding.dart';

import '../../analisis_akademik/views/analisis_akademik_view.dart';
import '../../analisis_akademik/controllers/analisis_akademik_controller.dart';
import '../../analisis_akademik/bindings/analisis_akademik_binding.dart';

import '../../../routes/app_pages.dart';
import '../controllers/daftar_kelas_controller.dart';

class DaftarKelasView extends GetView<DaftarKelasController> {
  const DaftarKelasView({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Kelas'),
        centerTitle: true,
        actions: [
              Obx(() {
                final isWali = controller.isWaliKelas.value;
                final kelasSudahDipilih = controller.kelasTerpilih.value != null;

                // Tampilkan menu HANYA jika pengguna adalah Wali Kelas dari kelas yang dipilih.
                // Pimpinan dan Observer tidak perlu menu ini karena sifatnya read-only.
                if (isWali && kelasSudahDipilih) {
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rekap_absensi') {
                        Get.toNamed(Routes.REKAP_ABSENSI, arguments: {'idKelas': controller.kelasTerpilih.value});
                      }
                      if (value == 'input_absensi') {
                        _showAbsensiSheet(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'input_absensi',
                        child: ListTile(leading: Icon(Icons.checklist_rtl_rounded), title: Text('Input Absensi Hari Ini')),
                      ),
                      const PopupMenuItem(
                        value: 'rekap_absensi',
                        child: ListTile(leading: Icon(Icons.bar_chart_rounded), title: Text('Rekapitulasi Absensi')),
                      ),
                    ],
                  );
                }
                // Jika bukan Wali Kelas, jangan tampilkan menu apa pun.
                return const SizedBox.shrink(); 
              }),
            ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
      ),

      floatingActionButton: Obx(() {
        if (controller.isTeacher) {
          return FloatingActionButton.extended(
            onPressed: () {
              Get.snackbar(
                "Fitur Dalam Pengembangan",
                "Mode observasi untuk melihat kelas lain akan segera hadir.",
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(Icons.visibility_outlined),
            label: const Text("Lihat Kelas Lain"),
          );
        }
        return const SizedBox.shrink();
      }),
      
      body: Obx(() {
        if (controller.isLoadingKelas.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarKelasDiajar.isEmpty) {
          return const Center(child: Text("Tidak ada data kelas yang bisa ditampilkan."));
        }

        // --- Kembali ke logika 3 cabang yang stabil ---
        if (controller.isSuperUser) {
          return _buildKepsekDashboard(context);
        } else if (controller.isTeacher) {
          return _buildGuruDashboard(context);
        } else {
          return _buildObserverDashboard(context);
        }
      }),
    );
  }

  Widget _buildObserverDashboard(BuildContext context) {
    return Column(
      children: [
        // 1. Pemilih Kelas (tetap ada)
        _buildKelasSelector(context),
        const Divider(height: 1),

        // 2. Konten Halaqoh (langsung ditampilkan, tanpa tab)
        Expanded(
          child: Obx(() {
            if (controller.kelasTerpilih.value == null) {
              return const Center(child: Text("Silakan pilih kelas untuk melihat data halaqoh."));
            }
            // Kita gunakan kembali widget tab halaqoh yang sudah ada
            return _buildHalaqohTab();
          }),
        ),
      ],
    );
  }

  Widget _buildHalaqohTab() {
  return Column(
    children: [
      // 1. Kotak Pencarian
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: TextField(
          onChanged: (value) => controller.searchQueryHalaqoh.value = value,
          decoration: InputDecoration(
            labelText: "Cari Nama Siswa...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      // 2. Daftar Siswa yang Responsif
      Expanded(
        child: Obx(() {
          if (controller.isLoadingHalaqoh.value) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Logika filter pencarian
          final query = controller.searchQueryHalaqoh.value.toLowerCase().trim();
          final filteredList = controller.daftarSiswaHalaqoh.where((siswa) {
            final nama = (siswa['namasiswa'] as String? ?? '').toLowerCase();
            return nama.contains(query);
          }).toList();

          if (filteredList.isEmpty) {
            return const Center(child: Text("Siswa tidak ditemukan atau belum ada data."));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final siswa = filteredList[index];
              return _buildSiswaHalaqohCard(siswa, isReadOnly: controller.isReadOnly); // Panggil kartu baru kita
            },
          );
        }),
      ),
    ],
  );
}
 
  Widget _buildSiswaHalaqohCard(Map<String, dynamic> siswa, {required bool isReadOnly}) {
  // Ambil semua data dengan fallback yang aman
  final String namaSiswa = siswa['namasiswa'] ?? 'Tanpa Nama';
  final String pengampu = siswa['namapengampu'] ?? 'Tanpa Kelompok';
  final String tempat = siswa['tempatmengaji'] ?? 'Lokasi belum diatur';
  final String umi = siswa['ummi'] ?? '-';
  final String capaian = siswa['capaian_terakhir'] ?? 'Belum ada';

  return Card(
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: CircleAvatar(
        child: Text(namaSiswa.isNotEmpty ? namaSiswa[0] : 'S'),
      ),
      title: Text(namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Info Pengampu & Tempat
            _buildInfoRow(Icons.person_pin_rounded, "pengampu: $pengampu"),
            _buildInfoRow(Icons.place_outlined, "tempat: $tempat"),
            const SizedBox(height: 6),
            // Baris Info UMI & Capaian
            _buildInfoRow(Icons.menu_book, "UMI: $umi"),
            _buildInfoRow(Icons.star_outline, "Capaian: $capaian"),
          ],
        ),
      ),
      trailing: isReadOnly ? null : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: isReadOnly ? null : () {
          Get.toNamed(Routes.DAFTAR_NILAI, arguments: siswa);
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 14, color: Colors.grey.shade600),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}


  Widget _buildKepsekDashboard(BuildContext context) {
    return Column(
      children: [
        // 1. Pemilih Kelas (sudah ada)
        _buildKelasSelector(context),
        const Divider(height: 1),

        // 2. TabBar akan muncul setelah kelas dipilih
        Obx(() {
          if (controller.kelasTerpilih.value == null) {
            return const Expanded(
              child: Center(child: Text("Silakan pilih kelas untuk dipantau.")),
            );
          }
          return Expanded(
            child: Column(
              children: [
                // 3. TabBar
                TabBar(
                  controller: controller.tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: "Halaqoh"),
                    Tab(text: "Absensi"),
                    Tab(text: "Akademik (Rapor)"),
                    Tab(text: "Siswa"),
                  ],
                ),
                
                // 4. Konten Tab
                Expanded(
                  child: TabBarView(
                    controller: controller.tabController,
                    children: [
                      // Konten Tab 1: Daftar Siswa
                      _buildHalaqohTab(), 
                      _buildRekapAbsensiTab(),
                      _buildAnalisisAkademikTab(),
                      _buildSiswaListForKepsek(),
                      
                      // Konten Tab 2-4: Placeholder untuk saat ini
                      // const Center(child: Text("Fitur Rekap Absensi akan muncul di sini.")),
                      // const Center(child: Text("Fitur Rekap Rapor akan muncul di sini.")),
                      // const Center(child: Text("Fitur Rekap Halaqoh akan muncul di sini.")),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAnalisisAkademikTab() {
    if (controller.kelasTerpilih.value == null) {
      return const Center(child: Text("Kelas belum dipilih."));
    }

    final String tag = "analisis_akademik_${controller.kelasTerpilih.value}";

    // Daftarkan controller-nya ke memori dengan tag yang benar
    Get.lazyPut<AnalisisAkademikController>(() {
      final c = AnalisisAkademikController();
      // "Suntikkan" data yang diperlukan
      c.idKelas = controller.kelasTerpilih.value!;
      c.idTahunAjaran = controller.homeC.idTahunAjaran.value!;
      c.semesterAktif = controller.homeC.semesterAktifId.value;
      return c;
    }, tag: tag, fenix: true);

    // Panggil widget dan beri tahu tag apa yang harus dicari
    return AnalisisAkademikWidget(
      key: ValueKey(tag),
      tag: tag,
    );
  }

  Widget _buildRekapAbsensiTab() {
    if (controller.kelasTerpilih.value == null) {
      return const Center(child: Text("Kelas belum dipilih."));
    }

    final String tag = "rekap_absensi_${controller.kelasTerpilih.value}";

    // 1. Daftarkan controller-nya ke memori dengan tag yang benar
    //    Get.lazyPut akan membuatnya hanya jika belum ada.
    Get.lazyPut<RekapAbsensiController>(() {
      final c = RekapAbsensiController();
      // "Suntikkan" data yang diperlukan di sini
      c.idKelas = controller.kelasTerpilih.value!;
      c.idTahunAjaran = controller.homeC.idTahunAjaran.value!;
      c.semesterAktif = controller.homeC.semesterAktifId.value;
      return c;
    }, tag: tag);

    // 2. Panggil widget dan BERI TAHU tag apa yang harus dicari
    return RekapAbsensiWidget(
      key: ValueKey(tag), // Key untuk memastikan rebuild saat kelas berganti
      tag: tag,           // <-- INI ADALAH KUNCI PERBAIKANNYA
    );
  }

  Widget _buildSiswaListForKepsek() {
    return Obx(() {
      if (controller.isLoadingMapelDanJadwal.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.daftarSiswaDiKelas.isEmpty) {
        return const Center(child: Text("Belum ada siswa di kelas ini."));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.daftarSiswaDiKelas.length,
        itemBuilder: (context, index) {
          final siswa = controller.daftarSiswaDiKelas[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text("${index + 1}")),
              title: Text(siswa['namasiswa'] ?? 'Tanpa Nama'),
              subtitle: Text("NISN: ${siswa['nisn'] ?? '-'}"),
            ),
          );
        },
      );
    });
  }

  Widget _buildGuruDashboard(BuildContext context) {
    return Column(
      children: [
        _buildKelasSelector(context), // Tetap gunakan pemilih kelas
        Expanded(
          // Gunakan NestedScrollView yang sudah Anda buat sebelumnya
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text("Mata Pelajaran Saya", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            body: _buildMapelDiajarList(),
          ),
        ),
        const Divider(height: 1, thickness: 4),
        Expanded(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text("Mapel Lain", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            body: _buildSemuaMapelList(),
          ),
        ),
      ],
    );
  }

  void _showAbsensiSheet(BuildContext context) {
    final theme = Theme.of(context);
    controller.searchQuery.value = ''; // Selalu reset pencarian saat dialog dibuka
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),  
        child: Column(
          children: [
            // Handle & Judul
            Container(
                  margin: const EdgeInsets.only(bottom: 16), // Memberi jarak ke konten di bawahnya
                  width: 50,                                // Lebar handle
                  height: 5,                                // Tinggi handle
                  decoration: BoxDecoration(
                    color: Colors.grey[300],                // Warna handle
                    borderRadius: BorderRadius.circular(10), // Membuat sudutnya melengkung
                  ),
                ),
            Text("Absensi Kelas ${controller.kelasTerpilih.value}", style: theme.textTheme.headlineSmall),
            Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now())),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              decoration: const InputDecoration(
                labelText: "Cari Nama Siswa...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25.0))),
              ),
            ),
            const Divider(height: 24),
            
            // Daftar Siswa
            Expanded(
              child: Obx(() {
                if (controller.daftarSiswaDiKelas.isEmpty) {
                  return const Center(child: Text("Tidak ada siswa di kelas ini."));
                }

                final query = controller.searchQuery.value.toLowerCase();
                final filteredList = controller.daftarSiswaDiKelas.where((siswa) {
                  final namaSiswa = (siswa['namasiswa'] as String? ?? '').toLowerCase();
                  return namaSiswa.contains(query);
                }).toList();

                if (filteredList.isEmpty) {
                  return const Center(child: Text("Siswa tidak ditemukan."));
                }

                return ListView.builder(
                  // itemCount: controller.daftarSiswaDiKelas.length,
                  itemCount: filteredList.length,
                  itemBuilder: (ctx, index) {
                    final siswa = controller.daftarSiswaDiKelas[index];
                    final nisn = siswa['nisn'];
                    return Obx(() {
                      final status = controller.absensiHariIni[nisn];
                      return ListTile(
                        leading: CircleAvatar(child: Text(siswa['namasiswa'][0])),
                        title: Text(siswa['namasiswa']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAbsensiChip("S", "Sakit", status, nisn, Colors.orange),
                            _buildAbsensiChip("I", "Izin", status, nisn, Colors.blue),
                            _buildAbsensiChip("A", "Alfa", status, nisn, Colors.red),
                          ],
                        ),
                      );
                    });
                  },
                );
              }),
            ),
            
            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isSavingAbsensi.value ? null : controller.simpanAbsensi,
                child: Text(controller.isSavingAbsensi.value ? "Menyimpan..." : "Simpan Absensi"),
              )),
            )
          ],
        ),
      ),
    );
  }

   /// [WIDGET BARU] Menampilkan daftar mapel yang diajar oleh guru ini (bisa diklik).
  Widget _buildMapelDiajarList() {
    return Obx(() {
      if (controller.isLoadingMapelDanJadwal.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.daftarMapelDiajar.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Anda tidak mengajar mata pelajaran apapun di kelas ini.", textAlign: TextAlign.center),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.daftarMapelDiajar.length,
        itemBuilder: (context, index) {
          final mapel = controller.daftarMapelDiajar[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(child: const Icon(Icons.edit_document)),
              title: Text(mapel['namaMapel'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Pengajar: ${mapel['namaGuru']}"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed(
                  Routes.DAFTAR_SISWA_PERMAPEL,
                  arguments: {
                    'idKelas': controller.kelasTerpilih.value,
                    'namaMapel': mapel['namaMapel'],
                  },
                );
              },
            ),
          );
        },
      );
    });
  }

  /// [WIDGET BARU] Menampilkan SEMUA mapel di kelas (read-only).
  Widget _buildSemuaMapelList() {
    return Obx(() {
      if (controller.isLoadingMapelDanJadwal.value) {
        return const SizedBox.shrink(); // Jangan tampilkan apa-apa saat loading
      }
      if (controller.semuaMapelDiKelas.isEmpty) {
        return const Center(child: Text("Jadwal untuk kelas ini belum dibuat."));
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.semuaMapelDiKelas.length,
        itemBuilder: (context, index) {
          final mapel = controller.semuaMapelDiKelas[index];
          // Tandai jika mapel ini diajar oleh guru yang login
          final bool isMyMapel = controller.daftarMapelDiajar.any((m) => m['namaMapel'] == mapel['namaMapel']);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            color: isMyMapel ? Colors.teal.withOpacity(0.05) : Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              dense: true,
              leading: Icon(Icons.book_outlined, size: 20, color: Colors.grey.shade600),
              title: Text(mapel['namaMapel']),
              subtitle: Text(mapel['namaGuru']),
              // Tidak ada onTap, jadi tidak bisa diklik
            ),
          );
        },
      );
    });
  }

  // Helper untuk membuat chip absensi
  Widget _buildAbsensiChip(String label, String statusValue, String? currentStatus, String nisn, Color color) {
    final bool isSelected = currentStatus == statusValue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => controller.updateAbsensi(nisn, statusValue),
        selectedColor: color,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      ),
    );
  }


  /// Widget untuk menampilkan daftar kelas yang bisa dipilih.
  Widget _buildKelasSelector(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.daftarKelasDiajar.length, // <- Gunakan nama state yang lama
        itemBuilder: (context, index) {
          final namaKelas = controller.daftarKelasDiajar[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Obx(() {
              final isSelected = controller.kelasTerpilih.value == namaKelas;
              return ChoiceChip(
                label: Text(namaKelas),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) controller.gantiKelasTerpilih(namaKelas);
                },
                    selectedColor: Colors.green.shade600,
                    backgroundColor: Colors.grey.shade200,
                    avatar: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null, // <-- Tambahkan ini
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
                        width: 1.5
                      )
                    ),
                  );
                }),
              );
            }),
          );
        }

  /// Widget untuk menampilkan daftar mata pelajaran berdasarkan kelas yang dipilih.
  Widget _buildMapelList() {
    return Obx(() {
      if (controller.isLoadingMapel.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (controller.kelasTerpilih.value == null) {
        return const Center(child: Text("Silakan pilih kelas terlebih dahulu."));
      }

      if (controller.daftarMapel.isEmpty) {
        return const Center(child: Text("Tidak ada mata pelajaran di kelas ini."));
      }
      
      // Tampilan daftar mapel dengan Card yang lebih menarik
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.daftarMapel.length,
        itemBuilder: (context, index) {
          final mapel = controller.daftarMapel[index];
          final namaMapel = mapel['namamatapelajaran'] ?? 'Tanpa Nama';
          final idKelas = mapel['idKelas'] ?? 'Tanpa ID';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: Icon(Icons.book_outlined, color: Colors.green.shade700),
              ),
              title: Text(namaMapel, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Guru: ${mapel['guru'] ?? '-'}"), // Kita bisa tampilkan nama gurunya juga!
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Get.toNamed(
                  Routes.DAFTAR_SISWA_PERMAPEL,
                  arguments: {
                    'idKelas': idKelas,
                    'namaMapel': namaMapel,
                  },
                );
              },
            ),
          );
        },
      );
    });
  }
}