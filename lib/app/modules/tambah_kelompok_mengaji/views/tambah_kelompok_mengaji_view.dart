import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/tambah_kelompok_mengaji_controller.dart';

class TambahKelompokMengajiView extends GetView<TambahKelompokMengajiController> {
  const TambahKelompokMengajiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isGroupCreated.value
            ? 'Kelola Anggota Halaqoh'
            : 'Buat Kelompok Halaqoh')),
        backgroundColor: Colors.indigo[400],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Obx(() {
          return controller.isGroupCreated.value
              ? _buildManageMembersUI(context)
              : _buildCreateGroupUI(context);
        }),
      ),
    );
  }

  // WIDGET UNTUK KONDISI 1: FORM MEMBUAT KELOMPOK
  Widget _buildCreateGroupUI(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader("Langkah 1: Tentukan Detail Kelompok", Icons.group_add_outlined),
        const SizedBox(height: 24),
        DropdownSearch<String>(
          items: (f, cs) => controller.getDataFase(),
          popupProps: const PopupProps.menu(showSearchBox: true, fit: FlexFit.loose),
          onChanged: (value) {
            if (value != null) {
              controller.faseC.text = value;
              controller.fetchAvailablePengampu(value); 
            }
          },
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              labelText: "Pilih Fase Kelompok",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // --- PERUBAHAN UTAMA: Dropdown Pengampu yang Cerdas ---
        Obx(() => DropdownSearch<Map<String, dynamic>>(
              items: (f, cs) => controller.availablePengampu.toList(),
              itemAsString: (item) => item['alias']!,
              compareFn: (item1, item2) => item1['uid'] == item2['uid'],
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                searchFieldProps: TextFieldProps(decoration: InputDecoration(labelText: "Cari nama pengampu...")),
              ),
              onChanged: (value) => controller.selectedPengampuData.value = value,
              enabled: controller.isFaseSelected.value,
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: "Pilih Pengampu Halaqoh",
                  hintText: controller.isFaseSelected.value ? "Pilih dari daftar..." : "Pilih fase terlebih dahulu",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )),
        const SizedBox(height: 20),
        TextField(
          controller: controller.tempatC,
          decoration: InputDecoration(
            labelText: "Ketik Nama Tempat Halaqoh",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 40),

        Obx(() => ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              icon: controller.isProcessing.value
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Icon(Icons.arrow_forward_ios_rounded),
              label: Text(controller.isProcessing.value ? 'MEMPROSES...' : 'Buat & Lanjutkan'),
              onPressed: controller.isProcessing.value ? null : controller.createGroupAndContinue,
            )),
        const SizedBox(height: 16),
        TextButton(onPressed: ()=> Get.back(), child: const Text("Kembali"))
      ],
    );
  }

  // WIDGET UNTUK KONDISI 2: MENAMBAH ANGGOTA
  Widget _buildManageMembersUI(BuildContext context) {
  final groupData = controller.createdGroupData.value!;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _buildSectionHeader("Informasi Kelompok", Icons.check_circle_outline, color: Colors.green),
      const SizedBox(height: 16),
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildInfoRow(Icons.person_pin_rounded, "Pengampu", groupData['namapengampu']),
              _buildInfoRow(Icons.place_outlined, "Tempat", groupData['tempatmengaji']),
              _buildInfoRow(Icons.flag_rounded, "Fase", groupData['fase']),
              _buildInfoRow(Icons.calendar_today_rounded, "Tahun Ajaran", groupData['tahunajaran']),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 16),
      _buildSectionHeader("Langkah 2: Kelola Anggota", Icons.person_add_alt_1_rounded),
      const SizedBox(height: 12),
      
      // --- PERUBAHAN UTAMA: Tombol tunggal untuk membuka BottomSheet ---
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.group_add_outlined),
          label: const Text("Pilih / Tambah Anggota Baru"),
          onPressed: () async {
            // 1. Minta controller untuk menyiapkan data
            await controller.openSiswaPicker(context); 
            // 2. BARU tampilkan sheet-nya
            _showPilihSiswaBottomSheet(context); 
          },
        ),
      ),
      const SizedBox(height: 24),
      const Text("Anggota Saat Ini:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),

      // --- StreamBuilder untuk menampilkan anggota yang sudah ditambahkan (tidak berubah) ---
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamAddedSiswa(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Card(child: Padding(padding: EdgeInsets.all(24.0), child: Center(child: Text("Belum ada anggota di kelompok ini.", style: TextStyle(fontStyle: FontStyle.italic)))));
          }
          return Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                var siswaData = snapshot.data!.docs[index].data();
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.indigo[100], child: Text(siswaData['namasiswa']?[0] ?? 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                  title: Text(siswaData['namasiswa'] ?? 'Nama tidak ada'),
                  subtitle: Text("Kelas: ${siswaData['kelas'] ?? 'N/A'} | NISN: ${siswaData['nisn'] ?? 'N/A'}"),
                  trailing: IconButton(
                    tooltip: "Hapus siswa dari kelompok",
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => controller.deleteSiswaFromGroup(siswaData['nisn'], siswaData['namasiswa'], siswaData['kelas'] ?? ''), 
                  ),
                );
              },
            ),
          );
        },
      ),
      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 16),
      
      // --- Tombol-tombol aksi di bawah (tidak berubah) ---
      ElevatedButton(
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: controller.finishAndGoBack,
        child: const Text('Selesai & Kembali'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), foregroundColor: Colors.orange.shade800, side: BorderSide(color: Colors.orange.shade800)),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Buat Kelompok Baru Lagi'),
        onPressed: controller.resetPage,
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        icon: const Icon(Icons.delete_forever_outlined),
        label: const Text('Batalkan & Hapus Kelompok'),
        onPressed: controller.cancelEmptyGroup,
      ),
    ],
  );
 }

  // WIDGET HELPER


  Widget _buildDropdown({
  required String label,
  required Future<List<String>> Function() getItems,
  required void Function(String?) onChanged,
}) {
  return DropdownSearch<String>(
    items: (f, cs) => getItems(),
    popupProps: const PopupProps.menu(showSearchBox: true, fit: FlexFit.loose),
    onChanged: onChanged,
    decoratorProps: DropDownDecoratorProps(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.indigo, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.indigo),
        const SizedBox(width: 12),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
      ]),
    );
  }

  void _showPilihSiswaBottomSheet(BuildContext context) {
  Get.bottomSheet(
    Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 50, height: 5,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 12),
          const Text("Pilih Siswa untuk Ditambahkan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // TextField Pencarian
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

          // Filter Kelas (Chip) menggunakan Obx
          Obx(() {
            if (controller.availableKelas.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text("Tidak ada kelas yang sesuai dengan fase ini."),
              );
            }
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
                    onSelected: (selected) {
                      if (selected) controller.gantiKelasDiSheet(kelas);
                    },
                  )),
                )).toList(),
              ),
            );
          }),
          
          const Divider(),

          // Daftar Siswa dengan Checkbox
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
}