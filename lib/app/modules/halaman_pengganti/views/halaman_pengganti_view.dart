// lib/app/modules/halaman_pengganti/views/halaman_pengganti_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/siswa_halaqoh.dart';
import '../../../routes/app_pages.dart';
import '../controllers/halaman_pengganti_controller.dart';
import '../../../widgets/input_nilai_massal_sheet.dart';
import '../../../widgets/tandai_siap_ujian_sheet.dart';

class HalamanPenggantiView extends GetView<HalamanPenggantiController> {
  const HalamanPenggantiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas Pengganti Hari Ini'),
        centerTitle: true,
        actions: [
          Obx(() {
            if (!controller.isLoading.value && controller.halaqohTerpilih.value != null) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'input_nilai') _showInputNilaiMassalSheet(context);
                  if (value == 'tandai_ujian') _showTandaiUjianSheet(context);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'input_nilai', child: ListTile(leading: Icon(Icons.edit_note), title: Text('Input Nilai Massal'))),
                  const PopupMenuItem(value: 'tandai_ujian', child: ListTile(leading: Icon(Icons.assignment_turned_in), title: Text('Tandai Siap Ujian'))),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.daftarHalaqoh.isEmpty) {
          return const Center(child: Text("Anda tidak memiliki tugas pengganti untuk hari ini."));
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
        // [DIHAPUS] _buildTempatInfo() dihapus dari sini.
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text("Daftar Santri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(child: _buildSantriList()),
      ],
    );
  }

  // Fungsi yang sudah diperbaiki
  Widget _buildHalaqohSelector() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.daftarHalaqoh.length,
        itemBuilder: (context, index) {
          final kelompok = controller.daftarHalaqoh[index];
          final namaTampilan = "${kelompok['fase']} (${kelompok['namaPengampuAsli']})";
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Obx(() {
              final isSelected = controller.halaqohTerpilih.value?['fase'] == kelompok['fase'] &&
                                 controller.halaqohTerpilih.value?['tempatmengaji'] == kelompok['tempatmengaji'];
              return ChoiceChip(
                label: Text(namaTampilan),
                avatar: const Icon(Icons.swap_horiz_rounded, size: 16),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) controller.gantiHalaqohTerpilih(kelompok);
                },
                selectedColor: Colors.blue.shade100,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              );
            }),
          );
        },
      ),
    );
  }

  // Pemanggilan widget terpusat (sudah benar)
  void _showInputNilaiMassalSheet(BuildContext context) {
    Get.bottomSheet(
      InputNilaiMassalSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showTandaiUjianSheet(BuildContext context) {
    Get.bottomSheet(
      TandaiSiapUjianSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // [DIHAPUS] Fungsi _showEditLokasiDialog() dihapus dari file ini.

  Widget _buildSantriList() {
    return Obx(() {
      if (controller.daftarSiswa.isEmpty) {
        return const Center(child: Text("Tidak ada santri di kelompok ini."));
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: controller.daftarSiswa.length,
        itemBuilder: (context, index) {
          final santri = controller.daftarSiswa[index];
          return _SantriCard(siswa: santri);
        },
      );
    });
  }
}

// Widget _SantriCard dan helper-nya (tidak berubah, bisa disalin dari DaftarHalaqohPengampuView)
class _SantriCard extends StatelessWidget {
  final SiswaHalaqoh siswa;
  const _SantriCard({required this.siswa});

  @override
  Widget build(BuildContext context) {
    final bool isSiapUjian = siswa.statusUjian == 'siap_ujian';

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
        onTap: () => Get.toNamed(Routes.DAFTAR_NILAI, arguments: siswa.rawData),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.teal.shade50,
                    backgroundImage: siswa.profileImageUrl != null ? NetworkImage(siswa.profileImageUrl!) : null,
                    child: siswa.profileImageUrl == null ? Text(siswa.namaSiswa.isNotEmpty ? siswa.namaSiswa[0] : 'S', style: const TextStyle(fontSize: 26, color: Colors.teal)) : null,
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
  if (capaian.trim().isEmpty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Row( mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.hourglass_empty_rounded, color: Colors.grey.shade500, size: 16), const SizedBox(width: 8),
          Text("Belum ada capaian", style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 13)),
        ],
      ),
    );
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade100)),
    child: Row( mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.trending_up_rounded, color: Colors.green.shade700, size: 16), const SizedBox(width: 8),
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