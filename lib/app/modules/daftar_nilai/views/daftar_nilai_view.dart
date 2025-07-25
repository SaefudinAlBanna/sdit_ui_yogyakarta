// lib/app/modules/daftar_nilai/views/daftar_nilai_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/nilai_halaqoh_umi.dart'; // <-- Pastikan path model ini benar
import '../controllers/daftar_nilai_controller.dart';

class DaftarNilaiView extends GetView<DaftarNilaiController> {
  const DaftarNilaiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Gunakan Obx untuk bereaksi terhadap perubahan state dari controller
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        // Tampilan jika tidak ada nilai sama sekali
        if (controller.daftarNilai.isEmpty) {
          return _buildEmptyState();
        }
        // Tampilan utama jika ada data nilai
        return _buildNilaiList();
      }),
    );
  }

  // --- WIDGET UTAMA (Struktur sama dengan Al-Husna) ---
  /// Membangun daftar nilai dengan AppBar yang bisa mengecil (SliverAppBar)
  Widget _buildNilaiList() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(), // Header info siswa
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final nilai = controller.daftarNilai[index];
                return _buildNilaiCard(nilai); // Kartu untuk setiap entri nilai
              },
              childCount: controller.daftarNilai.length,
            ),
          ),
        ),
      ],
    );
  }
  
  // --- APPBAR (Adaptasi dari Al-Husna) ---
  /// Membangun AppBar fleksibel yang menampilkan foto dan nama siswa
  SliverAppBar _buildSliverAppBar() {
    final Map<String, dynamic> siswa = controller.dataSiswa;
    final String? imageUrl = siswa['profileImageUrl'];
    final ImageProvider imageProvider = (imageUrl != null && imageUrl.isNotEmpty)
        ? NetworkImage(imageUrl)
        : NetworkImage("https://ui-avatars.com/api/?name=${siswa['namasiswa'] ?? 'S'}&background=random&color=fff");

    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.indigo, // Ganti warna sesuai tema Anda
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          siswa['namasiswa'] ?? 'Riwayat Nilai',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: imageProvider, fit: BoxFit.cover),
            // Gradient agar judul lebih mudah terbaca
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Color(0xAA000000), Color(0x00000000)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

   void _showEditDialog(NilaiHalaqohUmi nilai) {
    // Isi controller dengan data yang ada saat ini
    controller.suratEditC.text = nilai.hafalanSurat;
    controller.ayatEditC.text = nilai.ayatHafalan;
    controller.capaianEditC.text = nilai.capaian;
    controller.nilaiEditC.text = nilai.nilai.toString();

    Get.defaultDialog(
      title: "Edit Nilai",
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: controller.suratEditC, decoration: const InputDecoration(labelText: 'Surat Hafalan')),
            const SizedBox(height: 8),
            TextField(controller: controller.ayatEditC, decoration: const InputDecoration(labelText: 'Ayat')),
            const SizedBox(height: 8),
            TextField(controller: controller.capaianEditC, decoration: const InputDecoration(labelText: 'Capaian')),
            const SizedBox(height: 8),
            TextField(controller: controller.nilaiEditC, decoration: const InputDecoration(labelText: 'Nilai (Maks. 98)'), keyboardType: TextInputType.number),
          ],
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: controller.isDialogLoading.value ? null : () => controller.updateNilai(nilai),
        child: controller.isDialogLoading.value 
          ? const CircularProgressIndicator() 
          : const Text("Simpan Perubahan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  // --- KARTU NILAI (Inti dari halaman ini, adaptasi dari Al-Husna) ---
  /// Membangun kartu nilai yang bisa diperluas (ExpansionTile) untuk melihat detail

  Widget _buildNilaiCard(NilaiHalaqohUmi nilai) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(
          nilai.formattedDate,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Surat: ${nilai.hafalanSurat}"),
            
            // --- PERBAIKAN UTAMA DI SINI ---
            // Ambil lokasi SAAT INI dari controller, bukan dari data nilai yang lama.
            const SizedBox(height: 3),
            Text(
              "Lokasi: ${controller.dataSiswa['tempatmengaji']}", 
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.normal),
            ),
            // --- AKHIR PERBAIKAN ---
          ],
        ),
        leading: Icon(Icons.event_note, color: Colors.indigo.shade300, size: 32),
        trailing: controller.canEditOrDelete
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') _showEditDialog(nilai);
                  if (value == 'delete') controller.deleteNilai(nilai);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Nilai')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus Nilai')),
                ],
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.format_list_numbered, 'Ayat', nilai.ayatHafalan),
                _buildDetailRow(Icons.class_, 'Nilai', nilai.nilai.toString()),
                _buildDetailRow(Icons.menu_book, 'Konversi', nilai.nilaihuruf),
                _buildDetailRow(Icons.star_border_outlined, 'Materi', nilai.materi),
                _buildDetailRow(Icons.star_border_outlined, 'Capaian', nilai.capaian),
                const SizedBox(height: 10),
                _buildCatatanSection('Catatan Pengampu', Icons.edit_note, Colors.blue, nilai),
                const SizedBox(height: 10),
                _buildCatatanSection('Respon Orang Tua', Icons.family_restroom, Colors.green, nilai),
              ],
            ),
          )
        ],
      ),
    );
  }


  void _showEditCatatanDialog(NilaiHalaqohUmi nilai) {
    // Isi controller dengan catatan yang ada saat ini
    controller.catatanEditC.text = nilai.keteranganPengampu;

    Get.defaultDialog(
      title: "Edit Catatan Pengampu",
      content: TextField(
        controller: controller.catatanEditC,
        autofocus: true,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: "Catatan",
          border: OutlineInputBorder(),
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: controller.isDialogLoading.value 
            ? null 
            : () => controller.updateCatatanPengampu(nilai),
        child: controller.isDialogLoading.value
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text("Simpan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  
  // --- WIDGET HELPER ---

  /// Helper untuk menampilkan baris detail (adaptasi untuk UMI)
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  /// Helper untuk menampilkan bagian catatan (sama seperti Al-Husna)
  Widget _buildCatatanSection(String title, IconData icon, Color color, NilaiHalaqohUmi nilai) {
    String catatan = title == 'Catatan Pengampu' ? nilai.keteranganPengampu : nilai.keteranganOrangTua;

    if (catatan.isEmpty || catatan == '-' || catatan == 'Belum ada respon.') {
      return _buildDetailRow(icon, title, catatan);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Judul dan Ikon
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            // --- TOMBOL EDIT BARU DI SINI ---
            // Hanya tampilkan tombol edit untuk "Catatan Pengampu" dan jika user punya izin
            if (title == 'Catatan Pengampu' && controller.canEditOrDelete)
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: "Edit Catatan",
                onPressed: () => _showEditCatatanDialog(nilai),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3))
          ),
          child: Text(catatan, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
        ),
        // --- TAMBAHAN BARU: TAMPILKAN INFO EDIT DI SINI ---
        // Tampilkan hanya jika data edit ada (untuk Catatan Pengampu)
        if (title == 'Catatan Pengampu' && nilai.terakhirDiubah != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
            child: Row(
              children: [
                const Icon(Icons.history_edu, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Diubah oleh ${nilai.diubahOlehNama ?? ''} pada ${DateFormat('dd MMM, HH:mm', 'id_ID').format(nilai.terakhirDiubah!.toDate())}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }
  
  /// Helper untuk menampilkan tampilan jika data kosong (sama seperti Al-Husna)
  Widget _buildEmptyState() {
    final Map<String, dynamic> siswa = controller.dataSiswa;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Riwayat Nilai',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Nilai yang diinput untuk ${siswa['namasiswa'] ?? 'siswa ini'} akan muncul di sini.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}