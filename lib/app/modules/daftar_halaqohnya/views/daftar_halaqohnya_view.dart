// lib/app/modules/daftar_halaqohnya/views/daftar_halaqohnya_view.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../models/siswa_halaqoh.dart';
import '../../tambah_kelompok_mengaji/controllers/tambah_kelompok_mengaji_controller.dart';
import '../controllers/daftar_halaqohnya_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/tandai_siap_ujian_sheet.dart';

class DaftarHalaqohnyaView extends GetView<DaftarHalaqohnyaController> {
  const DaftarHalaqohnyaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(controller.fase.value, style: const TextStyle(fontSize: 18)),
            Text(controller.namaPengampu.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        )),
        centerTitle: true,
        // --- PERBAIKAN: Struktur AppBar dan PopupMenuButton yang Benar ---
        actions: [
          Obx(() {
            if (controller.canPerformWriteActions) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: "Menu Aksi",
                onSelected: (value) async {
                  if (value == 'ganti_pengampu') _showGantiPengampuDialog();
                  if (value == 'input_nilai') _showInputNilaiMassalSheet(context);
                  if (value == 'update_umi') _showBulkUpdateDialog();
                  if (value == 'tambah_siswa') {
                    await controller.openSiswaPicker();
                    _showPilihSiswaBottomSheet(context);
                  }
                  if (value == 'tandai_ujian') _showTandaiUjianSheet(context);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'ganti_pengampu', child: ListTile(leading: Icon(Icons.person_search), title: Text('Ganti Pengampu'))),
                  const PopupMenuItem(value: 'tambah_siswa', child: ListTile(leading: Icon(Icons.person_add_alt_1), title: Text('Tambah Siswa'))),
                  const PopupMenuItem(value: 'tandai_ujian', child: ListTile(leading: Icon(Icons.assignment_turned_in_outlined), title: Text('Tandai Siap Ujian'))),
                  const PopupMenuItem(value: 'input_nilai', child: ListTile(leading: Icon(Icons.edit_note), title: Text('Input Nilai Massal'))),
                  const PopupMenuItem(value: 'update_umi', child: ListTile(leading: Icon(Icons.group_work_outlined), title: Text('Update UMI Massal'))),
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
        if (controller.daftarSiswa.isEmpty) {
          return _buildEmptyState(context);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: controller.daftarSiswa.length,
          itemBuilder: (context, index) {
            final siswa = controller.daftarSiswa[index];
            return _buildSiswaCard(siswa);
          },
        );
      }),
    );
  }

  void _showGantiPengampuDialog() {
    // [BARU] Buat state lokal di dalam dialog untuk menampung pilihan sementara.
    final Rxn<Map<String, dynamic>> pengampuTerpilih = Rxn<Map<String, dynamic>>();

    Get.dialog(
      AlertDialog(
        title: const Text("Pilih Pengampu Baru"),
        content: SizedBox(
          width: Get.width * 0.8,
          // [DIUBAH] Dropdown sekarang hanya akan memperbarui state lokal.
          child: DropdownSearch<Map<String, dynamic>>(
            // items-nya tidak perlu diubah, tapi kita pinjam service sekarang
            items: (f, cs) => controller.halaqohService.fetchAvailablePengampu(controller.fase.value),
            itemAsString: (item) => item['alias']!,
            compareFn: (item1, item2) => item1['uid'] == item2['uid'],
            popupProps: const PopupProps.menu(showSearchBox: true),
            decoratorProps: const DropDownDecoratorProps(
              decoration: InputDecoration(labelText: "Pengampu Tersedia"),
            ),
            // onChanged sekarang hanya mengisi variabel sementara, tidak memanggil aksi besar.
            onChanged: (selected) {
              pengampuTerpilih.value = selected;
            },
          ),
        ),
        // [BARU] Tambahkan tombol aksi untuk konfirmasi.
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Batal"),
          ),
          // Bungkus tombol Ganti dengan Obx agar bisa aktif/nonaktif.
          Obx(() => ElevatedButton(
                // Tombol akan nonaktif sampai ada pengampu yang dipilih.
                onPressed: pengampuTerpilih.value == null
                    ? null
                    : () {
                        // Aksi besar dipanggil di sini, SETELAH konfirmasi.
                        controller.gantiPengampu(pengampuTerpilih.value);
                      },
                child: const Text("Ganti"),
              )),
        ],
      ),
      // Kita tidak perlu lagi menghapus controller sementara karena kita memanggil service.
    );
  }

  void _showPilihSiswaBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.only(top: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 12),
            const Text("Pilih Siswa untuk Ditambahkan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) => controller.searchQueryInSheet.value = value,
                decoration: InputDecoration(
                  labelText: "Cari Nama atau NISN...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.availableKelas.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Tidak ada kelas yang sesuai dengan fase ini."));
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: controller.availableKelas.map((kelas) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Obx(() => ChoiceChip(
                      label: Text("Kelas $kelas"),
                      selected: controller.kelasAktifDiSheet.value == kelas,
                      onSelected: (selected) { if (selected) controller.gantiKelasDiSheet(kelas); },
                    )),
                  )).toList(),
                ),
              );
            }),
            const Divider(),
            Expanded(
            child: Obx(() {
              // Pastikan ada kelas aktif sebelum mencoba stream
              if (controller.kelasAktifDiSheet.isEmpty) {
                return const Center(child: Text("Pilih kelas di atas untuk menampilkan siswa."));
              }
              // Update stream berdasarkan kelas yang aktif
              controller.kelasSiswaC.text = controller.kelasAktifDiSheet.value;
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: controller.streamSiswaBaru(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Semua siswa di kelas ini sudah punya kelompok.'));
                  
                  // Logika filter berdasarkan pencarian
                  return Obx(() {
                      final query = controller.searchQueryInSheet.value.toLowerCase().trim();
                      final allSiswa = snapshot.data!.docs.map((doc) => doc.data()..['kelas'] = controller.kelasAktifDiSheet.value).toList();
                      
                      final filteredSiswa = allSiswa.where((siswa) {
                        final nama = (siswa['namasiswa'] as String? ?? '').toLowerCase();
                        final nisn = (siswa['nisn'] as String? ?? '').toLowerCase();
                        return nama.contains(query) || nisn.contains(query);
                      }).toList();

                      // Jika setelah filter tidak ada hasil
                      if (filteredSiswa.isEmpty) {
                        return const Center(child: Text("Siswa tidak ditemukan."));
                      }

                      // ListView sekarang menggunakan data yang sudah difilter secara reaktif
                      return ListView.builder(
                        itemCount: filteredSiswa.length,
                        itemBuilder: (context, index) {
                          final siswaData = filteredSiswa[index];
                          // Obx di sini hanya untuk status checkbox, ini sudah benar
                          return Obx(() => CheckboxListTile(
                            title: Text(siswaData['namasiswa']),
                            subtitle: Text("NISN: ${siswaData['nisn']}"),
                            value: controller.siswaTerpilih.containsKey(siswaData['nisn']),
                            onChanged: (selected) => controller.toggleSiswaSelection(siswaData),
                          ));
                        },
                      );
                  });
                },
              );
            }),
          ),

          // Tombol Aksi di Bawah (tidak berubah)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Obx(() => ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: controller.siswaTerpilih.isEmpty ? null : controller.simpanSiswaTerpilih,
              child: Text("Tambahkan ${controller.siswaTerpilih.length} Siswa Terpilih"),
            )),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}

  // --- FUNGSI BARU UNTUK MENAMPILKAN BOTTOM SHEET UJIAN (VERSI LENGKAP & FINAL) ---
  void _showTandaiUjianSheet(BuildContext context) {
    Get.bottomSheet(
      TandaiSiapUjianSheet(controller: controller), // Cukup panggil widget terpusat
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showBulkUpdateDialog() {
    controller.siswaTerpilihUntukUpdateMassal.clear(); controller.bulkUpdateUmiC.clear();
    Get.defaultDialog( title: "Update UMI Massal", content: SizedBox( width: Get.width, height: Get.height * 0.5,
        child: Column( children: [
            Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: DropdownSearch<String>( popupProps: const PopupProps.menu(showSearchBox: true), items: (f, cs) => controller.listLevelUmi,
                onChanged: (value) => controller.bulkUpdateUmiC.text = value ?? '',
                decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "Pilih Level UMI Tujuan", border: OutlineInputBorder())),
              ),
            ),
            const Divider(),
            Expanded( child: Obx(() => ListView.builder( itemCount: controller.daftarSiswa.length,
                itemBuilder: (context, index) {
                  final siswa = controller.daftarSiswa[index];
                  return Obx(() => CheckboxListTile(
                    title: Text(siswa.namaSiswa), subtitle: Text("Level saat ini: ${siswa.ummi}"),
                    value: controller.siswaTerpilihUntukUpdateMassal.contains(siswa.nisn),
                    onChanged: (isSelected) {
                      if (isSelected == true) { controller.siswaTerpilihUntukUpdateMassal.add(siswa.nisn); } else { controller.siswaTerpilihUntukUpdateMassal.remove(siswa.nisn); }
                    },
                  ));
                },
              ))),
          ],
        ),
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: controller.isDialogLoading.value ? null : () => controller.updateUmiMassal(),
        child: controller.isDialogLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Simpan Perubahan"),
      )),
      cancel: TextButton( onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }

  Widget _buildKeteranganSection(ThemeData theme) {
    final List<Map<String, String>> keteranganOptions = [
      { "title": "Lancar", "value": "Alhamdulillah, Ananda hari ini menunjukkan pemahaman yang sangat baik dan lancar. InsyaAllah, besok bisa melanjutkan ke materi berikutnya. Barokallohu fiik." },
      { "title": "Baik", "value": "Alhamdulillah, Ananda hari ini sudah baik dan lancar. Tetap semangat belajar ya, Nak. Barokallohu fiik." },
      { "title": "Perlu Pengulangan", "value": "Alhamdulillah, Ananda hari ini sudah ada peningkatan. Mohon untuk dipelajari kembali di rumah, materi hari ini akan kita ulangi pada pertemuan berikutnya. Semangat!" }
    ];
    return Obx(() => Column( children: keteranganOptions.map((option) =>
        RadioListTile<String>(
          title: Text(option['title']!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          value: option['value']!, groupValue: controller.keteranganHalaqoh.value,
          onChanged: (val) { if (val != null) controller.keteranganHalaqoh.value = val; },
          activeColor: theme.colorScheme.primary, contentPadding: EdgeInsets.zero,
        )).toList(),
    ));
  }

  InputDecoration _inputDecorator(ThemeData theme, String label, IconData icon) {
     return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22, color: theme.colorScheme.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _showInputNilaiMassalSheet(BuildContext context) {
    final theme = Theme.of(context);
    controller.clearNilaiForm();

    // Pastikan controller nilai per siswa di-inisialisasi
    controller.nilaiMassalControllers.clear();
    for (var siswa in controller.daftarSiswa) {
      controller.nilaiMassalControllers[siswa.nisn] = TextEditingController();
    }
    
    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            Expanded(
              child: ListView(
                children: [
                  Text("1. Isi Template Materi (Untuk Semua)", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: controller.suratC, decoration: _inputDecorator(theme, 'Surat Hafalan', Icons.book_outlined)),
                  const SizedBox(height: 12),
                  TextField(controller: controller.ayatHafalC, decoration: _inputDecorator(theme, 'Ayat yang Dihafal', Icons.format_list_numbered_rtl_outlined)),
                  const SizedBox(height: 12),
                  TextField(controller: controller.capaianC, decoration: _inputDecorator(theme, 'Capaian', Icons.flag_outlined)),
                  const SizedBox(height: 12),
                  TextField(controller: controller.materiC, decoration: _inputDecorator(theme, 'Materi', Icons.lightbulb_outline)),
                  // Hapus TextField nilai tunggal dari sini
                  const SizedBox(height: 24),
                  Text("Catatan Pengampu", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  _buildKeteranganSection(theme), // Fungsi ini harus ada di view
                  const SizedBox(height: 24),
                  Text("2. Pilih Santri & Input Nilai Individual", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Obx(() => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.daftarSiswa.length,
                    itemBuilder: (ctx, index) {
                      final santri = controller.daftarSiswa[index];
                      return Obx(() {
                        final isSelected = controller.santriTerpilihUntukNilai.contains(santri.nisn);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (val) { controller.toggleSantriSelection(santri.nisn); },
                            activeColor: theme.colorScheme.primary,
                          ),
                          title: Text(santri.namaSiswa),
                          trailing: SizedBox(
                            width: 70, // Lebarkan sedikit
                            child: TextFormField(
                              // Gunakan controller yang spesifik per siswa
                              controller: controller.nilaiMassalControllers[santri.nisn],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2), // Maks 2 digit
                              ],
                              decoration: const InputDecoration(
                                hintText: "Nilai",
                                isDense: true,
                              ),
                            ),
                          ),
                        );
                      });
                    },
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton.icon(
              icon: controller.isSavingNilai.value 
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary)) 
                  : const Icon(Icons.save),
              label: Text(controller.isSavingNilai.value ? "Menyimpan..." : "Simpan untuk Santri Terpilih"),
              onPressed: controller.isSavingNilai.value ? null : controller.simpanNilaiMassal,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Membangun tampilan saat daftar siswa masih kosong
  Widget _buildEmptyState(BuildContext context) {
    return Center( child: Padding( padding: const EdgeInsets.all(24.0),
        child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.group_add_outlined, size: 80, color: Colors.grey.shade400), const SizedBox(height: 16),
            const Text("Belum Ada Siswa", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 8),
            const Text("Kelompok ini masih kosong. Tambahkan siswa pertama Anda untuk memulai.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)), const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text("Tambah Siswa"),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async { // <-- Menjadi async
                await controller.openSiswaPicker();
                _showPilihSiswaBottomSheet(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapaianInfo(String? capaian) {
  // Kondisi jika capaian kosong atau null
  if (capaian == null || capaian.trim().isEmpty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Warna netral untuk status kosong
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Membuat container seukuran kontennya
        children: [
          Icon(Icons.hourglass_empty_rounded, color: Colors.grey.shade500, size: 16),
          const SizedBox(width: 8),
          Text(
            "Belum ada capaian",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Kondisi jika ada data capaian
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.green.shade50, // Warna latar yang lembut dan positif
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green.shade100), // Border halus
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min, // Penting agar container tidak melebar penuh
      children: [
        Icon(Icons.trending_up_rounded, color: Colors.green.shade700, size: 16),
        const SizedBox(width: 8),
        // Flexible mencegah overflow jika teks sangat panjang di layar sempit
        Flexible(
          child: Text(
            capaian,
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis, // Mencegah teks meluber
          ),
        ),
      ],
    ),
  );
 }

  /// Membangun Card Siswa yang informatif dan interaktif
  Widget _buildSiswaCard(SiswaHalaqoh siswa) {
    final bool isSiapUjian = siswa.statusUjian == 'siap_ujian';
    
    return Card(
      elevation: isSiapUjian ? 4 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        // [VISUAL] Tambahkan border jika siap ujian
        side: isSiapUjian 
          ? BorderSide(color: Colors.amber.shade700, width: 2) 
          : BorderSide.none,
      ),
      // [VISUAL] Beri warna latar yang berbeda
      color: isSiapUjian ? Colors.amber.shade50 : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        // onTap: () { Get.toNamed(Routes.DAFTAR_NILAI, arguments: siswa.rawData); },
        onTap: () {
            // Buat map baru yang bisa diubah
            final arguments = Map<String, dynamic>.from(siswa.rawData);
            // Tambahkan informasi konteks dari controller halaman ini
            arguments['idpengampu'] = controller.idPengampu.value;
            arguments['tempatmengaji'] = controller.namaTempat.value;
            arguments['fase'] = controller.fase.value;
            
            Get.toNamed(Routes.DAFTAR_NILAI, arguments: arguments);
          },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blueGrey.shade50,
              backgroundImage: siswa.profileImageUrl != null ? NetworkImage(siswa.profileImageUrl!) : null,
              child: siswa.profileImageUrl == null ? Text(siswa.namaSiswa.isNotEmpty ? siswa.namaSiswa[0] : 'S', style: const TextStyle(fontSize: 26, color: Colors.blueGrey)) : null,
            ),
            const SizedBox(width: 16),
            
            // --- [PERBAIKAN] SUSUNAN INFORMASI SISWA ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(siswa.namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text("Kelas: ${siswa.kelas}", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  const SizedBox(height: 10),
                  
                  // Baris untuk UMI dan Capaian agar rapi
                  Wrap(
                    spacing: 8.0, // Jarak horizontal antar item
                    runSpacing: 8.0, // Jarak vertikal jika item pindah ke baris baru
                    children: [
                      // Chip untuk level UMI (tidak berubah)
                      Chip(
                        label: Text("UMI: ${siswa.ummi}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        backgroundColor: _getUmiColor(siswa.ummi),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Membuat chip lebih kecil
                      ),

                      // Memanggil widget baru kita untuk menampilkan capaian
                      _buildCapaianInfo(siswa.capaian),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tombol Aksi (tidak berubah)
                  Obx(() {
                    if (controller.canPerformWriteActions) {
                      return PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'update') _showUpdateUmiDialog(siswa);
                          if (value == 'pindah') _showPindahHalaqohDialog(siswa);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'update', child: Text('Update UMI')),
                          const PopupMenuItem(value: 'pindah', child: Text('Pindah Halaqoh')),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),
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

      void _showPindahHalaqohDialog(SiswaHalaqoh siswa) {
    final Rxn<Map<String, dynamic>> tujuanTerpilih = Rxn<Map<String, dynamic>>();

    Get.defaultDialog(
      title: "Pindahkan: ${siswa.namaSiswa}",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Pilih kelompok tujuan di fase yang sama:"),
          const SizedBox(height: 16),
          DropdownSearch<Map<String, dynamic>>(
            items: (f, cs) => controller.getTujuanHalaqoh(),
            itemAsString: (item) => "${item['namapengampu']} - ${item['namatempat']}",
            compareFn: (item1, item2) => item1['idpengampu'] == item2['idpengampu'],
            popupProps: const PopupProps.menu(showSearchBox: true),
            decoratorProps: const DropDownDecoratorProps(
              decoration: InputDecoration(labelText: "Kelompok Tujuan", border: OutlineInputBorder()),
            ),
            onChanged: (value) {
              tujuanTerpilih.value = value;
            },
          ),
        ],
      ),
      textConfirm: "Pindahkan",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (tujuanTerpilih.value != null) {
          controller.pindahHalaqoh(siswa, tujuanTerpilih.value!);
        } else {
          Get.snackbar("Peringatan", "Anda harus memilih kelompok tujuan.");
        }
      },
    );
  }

  /// Dialog untuk mengupdate UMI (adaptasi dari Al-Husna)
  void _showUpdateUmiDialog(SiswaHalaqoh siswa) {
    controller.umiC.text = siswa.ummi;
    Get.defaultDialog( title: "Update UMI", content: Column( children: [
          Text(siswa.namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 16),
          DropdownSearch<String>( popupProps: const PopupProps.menu(showSearchBox: true), items: (f, cs) => controller.listLevelUmi, selectedItem: controller.umiC.text,
            onChanged: (value) => controller.umiC.text = value ?? '',
            decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "Level UMI", border: OutlineInputBorder())),
          ),
        ],
      ),
      confirm: Obx(() => ElevatedButton(
        onPressed: controller.isDialogLoading.value ? null : () => controller.updateUmi(siswa.nisn),
        child: controller.isDialogLoading.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Simpan"),
      )),
      cancel: TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
    );
  }
  
}

/// Fungsi helper untuk memberi warna pada Chip UMI
Color _getUmiColor(String level) {
  final l = level.toLowerCase();
  if (l.contains('alquran')) return Colors.green.shade600;
  if (l.contains('jilid 6')) return Colors.blue.shade600;
  if (l.contains('jilid 5')) return Colors.purple.shade500;
  if (l.contains('jilid 4')) return Colors.deepOrange.shade500;
  if (l.startsWith('jilid')) return Colors.orange.shade700;
  return Colors.grey.shade500;
}