// lib/app/modules/kelas_tahfidz/views/kelas_tahfidz_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/kelas_tahfidz_controller.dart';

class KelasTahfidzView extends GetView<KelasTahfidzController> {
  const KelasTahfidzView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelas Tahfidz'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.hasAccess.value) {
          return _buildWaliKelasUI();
        }
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Anda tidak memiliki akses ke fitur ini atau Anda bukan Wali Kelas di tahun ajaran ini.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        );
      }),
    );
  }

  /// Membangun UI utama untuk Wali Kelas setelah data berhasil dimuat.
  /// Ini adalah kerangka utama yang menampung semua komponen UI lainnya.
  Widget _buildWaliKelasUI() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildHeaderInfo(),
        const SizedBox(height: 24),
        _buildPendampingSection(),
        const SizedBox(height: 24),
        _buildSiswaList(),
      ],
    );
  }

  /// Menampilkan Card informasi yang berisi nama kelas dan nama Wali Kelas.
  /// Data diambil dari state reaktif di controller.
  Widget _buildHeaderInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Obx(() => ListTile(
                  leading: const Icon(Icons.class_outlined, color: Colors.indigo),
                  title: const Text("Kelas"),
                  subtitle: Text(
                    controller.namaKelas.value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                )),
            const Divider(),
            Obx(() => ListTile(
                  leading: const Icon(Icons.person_outline, color: Colors.indigo),
                  title: const Text("Wali Kelas"),
                  subtitle: Text(
                    controller.namaWaliKelas.value,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Membangun UI untuk manajemen Guru Pendamping.
  /// Termasuk tombol untuk menambah dan daftar pendamping yang sudah ada.
  Widget _buildPendampingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Guru Pendamping",
          style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Obx(() => Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_outlined),
                title: const Text("Tambah Pendamping Baru"),
                trailing: const Icon(Icons.add_circle, color: Colors.green),
                onTap: () => _showAddPendampingDialog(),
              ),
              const Divider(height: 1),
              if (controller.daftarPendamping.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text("Belum ada guru pendamping.")),
                )
              else
                ...controller.daftarPendamping.entries.map((entry) {
                  final uid = entry.key;
                  final nama = entry.value;
                  return ListTile(
                    leading: const Icon(Icons.account_circle, color: Colors.grey),
                    title: Text(nama),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: "Hapus Pendamping",
                      onPressed: () {
                        Get.defaultDialog(
                          title: "Konfirmasi",
                          middleText: "Anda yakin ingin menghapus $nama dari daftar pendamping?",
                          textConfirm: "Ya, Hapus",
                          textCancel: "Batal",
                          confirmTextColor: Colors.white,
                          onConfirm: () {
                            Get.back();
                            controller.removePendamping(uid);
                          }
                        );
                      },
                    ),
                  );
                }).toList(),
            ],
          )),
        ),
      ],
    );
  }

  /// Menampilkan dialog popup untuk memilih guru pendamping yang tersedia.
  void _showAddPendampingDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Pilih Pendamping"),
        content: SizedBox(
          width: Get.width * 0.8,
          child: DropdownSearch<Map<String, dynamic>>(
            items: (c, fs) => controller.getAvailablePendamping(),
            itemAsString: (item) => item['nama']!,
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: const TextFieldProps(
                decoration: InputDecoration(labelText: "Cari Nama Guru"),
              ),
              emptyBuilder: (context, searchEntry) => const Center(
                child: Text("Tidak ada guru pengampu yang tersedia."),
              ),
            ),
            decoratorProps: const DropDownDecoratorProps(
              decoration: InputDecoration(
                labelText: "Guru Pengampu",
                hintText: "Pilih guru yang tersedia",
              ),
            ),
            compareFn: (item, selectedItem) => item['uid'] == selectedItem['uid'],
            onChanged: (selectedItem) {
              if (selectedItem != null) {
                final uid = selectedItem['uid']! as String;
                final nama = selectedItem['nama']! as String;
                Get.back();
                controller.addPendamping(uid, nama);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Batal"),
          ),
        ],
      ),
    );
  }
  
  /// Membangun daftar siswa yang ada di kelas ini.
  /// Setiap siswa akan dirender sebagai `_SiswaCard`.
  Widget _buildSiswaList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Penilaian Siswa",
              style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            // --- TOMBOL BARU DI SINI ---
            TextButton.icon(
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text("Input Massal"),
              onPressed: () => _showNilaiMassalDialog(),
            )
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.daftarSiswa.isEmpty) {
            return const Center(child: Text("Belum ada siswa di kelas ini."));
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.daftarSiswa.length,
            itemBuilder: (context, index) {
              final siswa = controller.daftarSiswa[index];
              return _SiswaCard(siswa: siswa, view: this);
            },
          );
        }),
      ],
    );
  }

  /// Menampilkan panel dari bawah (Bottom Sheet) untuk detail penilaian seorang siswa.
  /// Ini adalah inti dari fitur input, edit, hapus, dan cetak.
  void _showPenilaianDetailSheet(Map<String, dynamic> siswa) {
    final nisn = siswa['id'] as String;
    final namaSiswa = siswa['namasiswa'] as String;
    controller.clearForm();

    Get.bottomSheet(
      Form(
        key: controller.formKey,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9, maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Column(
              children: [
                _buildFormSection(namaSiswa, nisn),
                _buildHistorySection(scrollController, namaSiswa, nisn),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Membangun bagian atas dari Bottom Sheet, yaitu form untuk input atau edit.
  Widget _buildFormSection(String namaSiswa, String nisn) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(
                controller.editingDocId.value == null ? "Input Penilaian Baru" : "Edit Penilaian",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )),
              Flexible(child: Text(namaSiswa, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Divider(height: 20),
          DropdownButtonFormField<String>(
            value: controller.selectedKategori.value,
            items: ['Hafalan Baru', 'Murojaah', 'Ujian Semester', 'Lainnya']
                .map((label) => DropdownMenuItem(child: Text(label), value: label))
                .toList(),
            onChanged: (value) {
              if (value != null) controller.selectedKategori.value = value;
            },
            decoration: const InputDecoration(labelText: "Kategori Penilaian", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller.materiC,
            decoration: const InputDecoration(labelText: "Materi (Contoh: QS. Al-Baqarah: 1-5)", border: OutlineInputBorder()),
            validator: (value) => (value?.isEmpty ?? true) ? 'Materi tidak boleh kosong' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller.nilaiC,
            decoration: const InputDecoration(labelText: "Nilai", border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) => (value?.isEmpty ?? true) ? 'Nilai tidak boleh kosong' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller.catatanGuruC,
            decoration: const InputDecoration(labelText: "Catatan Guru (Opsional)", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Row(
  children: [
    Expanded(
      child: Obx(() => ElevatedButton(
        onPressed: controller.isSaving.value 
            ? null // Nonaktifkan tombol saat loading
            : () => controller.saveCatatanTahfidz(nisn),
        child: controller.isSaving.value
            ? const SizedBox( // Tampilkan spinner jika loading
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(controller.editingDocId.value == null ? "Simpan" : "Update"),
                )),
              ),
              Obx(() {
                if (controller.editingDocId.value != null) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: "Batal Edit",
                      onPressed: () => controller.clearForm(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              })
            ],
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog untuk input nilai secara massal.
  void _showNilaiMassalDialog() {
    final kategoriC = TextEditingController();
    final materiC = TextEditingController();

    Get.defaultDialog(
      title: "Input Nilai Massal",
      content: Form(
        child: SizedBox(
          width: Get.width,
          height: Get.height * 0.6,
          child: Column(
            children: [
              // Form Kategori & Materi
              DropdownButtonFormField<String>(
                items: ['Hafalan Baru', 'Murojaah', 'Ujian Semester', 'Lainnya']
                    .map((label) => DropdownMenuItem(child: Text(label), value: label))
                    .toList(),
                onChanged: (value) {
                  if (value != null) kategoriC.text = value;
                },
                decoration: const InputDecoration(labelText: "Kategori"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: materiC,
                decoration: const InputDecoration(labelText: "Materi (Untuk Semua Siswa)"),
              ),
              const Divider(height: 20),
              const Text("Daftar Siswa", style: TextStyle(fontWeight: FontWeight.bold)),
              // Daftar Siswa
              Expanded(
                child: ListView.builder(
                  itemCount: controller.daftarSiswa.length,
                  itemBuilder: (context, index) {
                    final siswa = controller.daftarSiswa[index];
                    return ListTile(
                      title: Text(siswa['namasiswa']),
                      trailing: SizedBox(
                        width: 60,
                        child: TextFormField(
                          // Gunakan controller dari map
                          controller: controller.nilaiMassalControllers[siswa['id']],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: "Nilai"),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      textConfirm: "Simpan Semua",
      textCancel: "Batal",
      onConfirm: () {
        controller.saveNilaiMassal(kategoriC.text, materiC.text);
      },
    );
  }

  /// Membangun bagian bawah dari Bottom Sheet, yaitu riwayat penilaian dan tombol cetak.
  Widget _buildHistorySection(ScrollController scrollController, String namaSiswa, String nisn) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Riwayat Penilaian", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: controller.getCatatanTahfidzStream(nisn),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada riwayat penilaian."));
                }
                final catatanList = snapshot.data!.docs;
                return Scaffold(
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => controller.generateAndPrintPdf(namaSiswa, catatanList),
                    tooltip: "Cetak Riwayat",
                    child: const Icon(Icons.print),
                  ),
                  body: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: catatanList.length,
                    itemBuilder: (context, index) {
                      final doc = catatanList[index];
                      final data = doc.data();
                      final timestamp = data['tanggal_penilaian'] as Timestamp;
                      final tanggal = DateFormat('dd MMM\nyyyy').format(timestamp.toDate());
                      
                      return Card(
                        elevation: 1,
                        child: ListTile(
                          title: Text("${data['kategori']}: ${data['materi']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Nilai: ${data['nilai']} | Oleh: ${data['penilai_nama']}\nCatatan: ${data['catatan_guru'] ?? '-'}"),
                          isThreeLine: true,
                          leading: Text(tanggal, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                onPressed: () => controller.startEdit(data, doc.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () {
                                   Get.defaultDialog(
                                    title: "Konfirmasi Hapus",
                                    middleText: "Anda yakin ingin menghapus catatan penilaian ini secara permanen?",
                                    textConfirm: "Ya, Hapus",
                                    textCancel: "Batal",
                                    onConfirm: () {
                                      Get.back();
                                      controller.deleteCatatanTahfidz(nisn, doc.id);
                                    }
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget Card kustom untuk setiap siswa.
/// Ini adalah komponen yang akan ditampilkan di halaman utama fitur.
class _SiswaCard extends StatelessWidget {
  final Map<String, dynamic> siswa;
  final KelasTahfidzView view;
  const _SiswaCard({required this.siswa, required this.view});

  @override
  Widget build(BuildContext context) {
    final namaSiswa = siswa['namasiswa'] ?? 'Tanpa Nama';
    final nisn = siswa['nisn'] ?? 'Tanpa NISN';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(child: Text(namaSiswa.isNotEmpty ? namaSiswa[0] : '-')),
          title: Text(namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("NISN: $nisn"),
          trailing: OutlinedButton.icon(
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text("Detail"),
            onPressed: () {
              // Saat tombol ditekan, panggil method di dalam view utama untuk menampilkan bottom sheet
              view._showPenilaianDetailSheet(siswa);
            },
          ),
        ),
      ),
    );
  }
}