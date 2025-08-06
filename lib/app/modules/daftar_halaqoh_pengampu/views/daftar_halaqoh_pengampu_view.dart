// lib/app/modules/daftar_halaqoh_pengampu/views/daftar_halaqoh_pengampu_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../models/siswa_halaqoh.dart';
import '../../../routes/app_pages.dart';
import '../controllers/daftar_halaqoh_pengampu_controller.dart';
import '../../../widgets/input_nilai_massal_sheet.dart';
import '../../../widgets/tandai_siap_ujian_sheet.dart';

class DaftarHalaqohPengampuView extends GetView<DaftarHalaqohPengampuController> {
  const DaftarHalaqohPengampuView({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller diinisialisasi oleh Get.put di tempat lain atau via binding
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelas Tahsin'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey.shade800,
        // actions: [
        //   Obx(() {
        //     // Tampilkan menu HANYA jika tidak loading DAN ada kelompok terpilih
        //     if (!controller.isLoading.value && controller.halaqohTerpilih.value != null) {
        actions: [
          Obx(() {
            if (!controller.isLoading.value && controller.halaqohTerpilih.value != null) {
              return Row( // Bungkus dengan Row
                children: [
                  // --- TOMBOL BARU DI SINI ---
                  IconButton(
                    icon: const Icon(Icons.assessment_outlined),
                    tooltip: 'Kelola Nilai Rapor Tahsin',
                    onPressed: () {
                      // Ambil idKelas dari data santri pertama (asumsi semua sama)
                      if (controller.daftarSiswa.isNotEmpty) {
                        final String idKelas = controller.daftarSiswa.first.kelas;
                        Get.toNamed(
                          Routes.PENILAIAN_RAPOR_HALAQOH,
                          arguments: {
                            'idKelas': idKelas,
                            'jenisHalaqoh': 'Tahsin',
                            'infoKelompok': controller.halaqohTerpilih.value,
                          },
                        );
                      } else {
                        Get.snackbar("Info", "Tidak ada siswa di kelompok ini untuk dinilai.");
                      }
                    },
                  ),
               PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                      if (value == 'input_nilai') _showInputNilaiMassalSheet(context);
                      if (value == 'tandai_ujian') _showTandaiUjianSheet(context);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'input_nilai', child: ListTile(leading: Icon(Icons.edit_note), title: Text('Input Nilai Massal'))),
                  const PopupMenuItem(value: 'tandai_ujian', child: ListTile(leading: Icon(Icons.assignment_turned_in), title: Text('Tandai Siap Ujian'))
                  ),
               
                ],
               ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),

       floatingActionButton: Obx(() {
        // Kita bertanya langsung ke HomeController
        if (controller.homeC.isPenggantiHariIni) {
          // Jika ada tugas pengganti, tampilkan tombolnya
          return FloatingActionButton.extended(
            onPressed: () {
              Get.toNamed(Routes.HALAMAN_PENGGANTI);
            },
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text("Lihat Tugas Pengganti"),
            tooltip: 'Anda memiliki tugas pengganti hari ini',
          );
        } else {
          // Jika tidak ada, jangan tampilkan apa-apa
          return const SizedBox.shrink();
        }
      }),
      
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarHalaqoh.isEmpty) {
          return const Center(child: Text("Anda tidak mengampu kelompok halaqoh manapun."));
        }
        return _buildMainContent();
      }),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHalaqohSelector(),
        _buildTempatInfo(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text("Daftar Santri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(child: _buildSantriList()),
      ],
    );
  }

  Widget _buildHalaqohSelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.daftarHalaqoh.length,
        itemBuilder: (context, index) {
          final kelompok = controller.daftarHalaqoh[index];
          final namaTampilan = kelompok['fase'] ?? 'Kelompok';
          final bool isPengganti = kelompok['isPengganti'] ?? false;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Obx(() {
              final isSelected = controller.halaqohTerpilih.value?['fase'] == kelompok['fase'];
              return ChoiceChip(
                // [VISUAL] Tambahkan ikon jika ini sesi pengganti
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(namaTampilan),
                    if (isPengganti)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.blueAccent),
                      )
                  ],
                ),
                // [VISUAL] Beri warna berbeda
                selectedColor: isPengganti ? Colors.blue.shade100 : Theme.of(context).primaryColor,
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) controller.gantiHalaqohTerpilih(kelompok);
                },
              );
            }),
          );
        },
      ),
    );
  }

  void _showInputNilaiMassalSheet(BuildContext context) {
    // PERBAIKAN: Bersihkan state SEBELUM menampilkan sheet.
    // Ini memastikan setiap kali sheet dibuka, kondisinya bersih dan siap pakai.
    controller.clearNilaiForm();

    Get.bottomSheet(
      // Widget sheet sekarang benar-benar 'bodoh' dan hanya menampilkan state.
      InputNilaiMassalSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).whenComplete(() {
      // OPSIONAL TAPI SANGAT DIREKOMENDASIKAN:
      // Membersihkan list santri terpilih jika sheet ditutup tanpa menyimpan
      // (misalnya dengan swipe ke bawah atau menekan tombol back).
      controller.santriTerpilihUntukNilai.clear();
    });
  }

    void _showTandaiUjianSheet(BuildContext context) {
  Get.bottomSheet(
    TandaiSiapUjianSheet(controller: controller),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

  void _showEditLokasiDialog() {
    // --- PERBAIKAN DI SINI ---
    final kelompok = controller.halaqohTerpilih.value;
    if (kelompok == null) return; // Pengaman jika tidak ada kelompok terpilih
    
    // Ambil lokasi saat ini dari data kelompok terpilih
    controller.lokasiC.text = kelompok['lokasi_terakhir'] ?? kelompok['tempatmengaji'];
    // --- AKHIR PERBAIKAN ---

    Get.defaultDialog(
      title: "Ubah Lokasi Halaqoh",
      content: TextField(
        controller: controller.lokasiC,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: "Nama Lokasi Baru",
          border: OutlineInputBorder(),
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: controller.isDialogLoading.value ? null : controller.updateLokasiHalaqoh,
        child: controller.isDialogLoading.value 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Text("Simpan"),
      )),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("Batal"),
      ),
    );
  }

  Widget _buildTempatInfo() {
    return Obx(() {
      final kelompok = controller.halaqohTerpilih.value;
      if (kelompok == null) return const SizedBox.shrink();
      final tempat = kelompok['lokasi_terakhir'] ?? kelompok['tempatmengaji'];
      if (tempat == null || tempat.isEmpty) return const SizedBox.shrink();
      return InkWell(
        // onTap: () { /* Logika edit lokasi */ },
        onTap: _showEditLokasiDialog,        
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, color: Colors.teal.shade700, size: 18),
              const SizedBox(width: 8),
              Flexible(child: Text("Lokasi: $tempat", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800))),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSantriList() {
    return Obx(() {
      // Periksa dari variabel yang benar
      if (controller.daftarSiswa.isEmpty) {
        return const Center(child: Text("Tidak ada santri di kelompok ini."));
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        // Baca panjang dari variabel yang benar
        itemCount: controller.daftarSiswa.length,
        itemBuilder: (context, index) {
          // Ambil data dari variabel yang benar
          final santri = controller.daftarSiswa[index];
          return _SantriCard(siswa: santri);
        },
      );
    });
  }

}

class _SantriCard extends StatelessWidget {
  final SiswaHalaqoh siswa;
  const _SantriCard({required this.siswa});

  @override
  Widget build(BuildContext context) {
    // [PERBAIKAN KUNCI] Temukan controller yang aktif menggunakan Get.find()
    // Ini membuat 'controller' tersedia di dalam scope build method ini.
    final controller = Get.find<DaftarHalaqohPengampuController>();
    
    final bool isSiapUjian = siswa.statusUjian == 'siap_ujian';

    ImageProvider? backgroundImageProvider;
    if (siswa.profileImageUrl != null && siswa.profileImageUrl!.trim().isNotEmpty) {
      backgroundImageProvider = NetworkImage(siswa.profileImageUrl!);
    }

    return Card(
      elevation: isSiapUjian ? 4 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isSiapUjian 
          ? BorderSide(color: Colors.amber.shade700, width: 2) 
          : BorderSide.none,
      ),
      color: isSiapUjian ? Colors.amber.shade50 : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        // Sekarang, 'controller' sudah dikenali dan bisa digunakan di sini
        onTap: () {
          final arguments = {
            ...siswa.rawData,
            ...controller.halaqohTerpilih.value!,
          };
          Get.toNamed(Routes.DAFTAR_NILAI, arguments: arguments);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.teal.shade50,
                    backgroundImage: backgroundImageProvider,
                    onBackgroundImageError: backgroundImageProvider != null 
                        ? (exception, stackTrace) {
                            print('Error memuat gambar untuk ${siswa.namaSiswa}: $exception');
                          }
                        : null,
                     child: (backgroundImageProvider == null)
                        ? Text(
                            siswa.namaSiswa.isNotEmpty ? siswa.namaSiswa[0] : 'S',
                            style: const TextStyle(fontSize: 26, color: Colors.teal),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(siswa.namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 4),
                        Text("Kelas: ${siswa.kelas}", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            Chip(
                              label: Text("UMI: ${siswa.ummi}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              backgroundColor: _getUmiColor(siswa.ummi),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            _buildCapaianInfo(siswa.capaian),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              if (isSiapUjian)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Chip(
                    avatar: Icon(Icons.star, color: Colors.yellow.shade800),
                    label: const Text("SIAP UJIAN", style: TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.amber.shade200,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// [BARU] Tambahkan dua fungsi helper ini di bagian bawah file view Anda
Widget _buildCapaianInfo(String capaian) {
  // [PERBAIKAN] Cek apakah capaian null atau string kosong setelah di-trim
  if (capaian.trim().isEmpty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Row( mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.history_toggle_off, color: Colors.grey.shade500, size: 16), // Ikon yang lebih sesuai
          const SizedBox(width: 8),
          Text("Belum ada capaian", style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 13)),
        ],
      ),
    );
  }
  // Jika ada isinya, tampilkan seperti ini
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade100)),
    child: Row( mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.trending_up_rounded, color: Colors.green.shade700, size: 16), 
        const SizedBox(width: 8),
        // Gunakan Flexible agar tidak overflow jika teks panjang
        Flexible( child: Text(capaian, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

Color _getUmiColor(String level) {
  final l = level.toLowerCase();
  if (l.contains('alquran')) return Colors.green.shade600;
  if (l.contains('jilid 6')) return Colors.blue.shade600;
  if (l.contains('jilid 5')) return Colors.purple.shade500;
  if (l.contains('jilid 4')) return Colors.deepOrange.shade500;
  if (l.startsWith('jilid')) return Colors.orange.shade700;
  return Colors.grey.shade500;
}