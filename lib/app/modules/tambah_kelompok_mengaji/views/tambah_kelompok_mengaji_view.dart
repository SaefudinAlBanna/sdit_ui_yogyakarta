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
        _buildDropdown(
          label: "Pilih Fase Kelompok",
          getItems: controller.getDataFase,
          onChanged: (value) => controller.faseC.text = value ?? "",
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: "Pilih Pengampu Halaqoh",
          getItems: controller.getDataPengampu,
          onChanged: (value) => controller.pengampuC.text = value ?? "",
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: "Pilih Tempat Halaqoh",
          getItems: controller.getDataTempat,
          onChanged: (value) => controller.tempatC.text = value ?? "",
        ),
        const SizedBox(height: 40),
        Obx(() => ElevatedButton.icon(
              // PERBAIKAN: Menambahkan `foregroundColor` untuk memastikan teks terlihat.
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white, // Ini akan membuat teks dan ikon menjadi putih
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
        _buildSectionHeader("Langkah 2: Tambah Anggota", Icons.person_add_alt_1_rounded),
        const SizedBox(height: 12),
        const Text("Pilih siswa dari kelas yang tersedia:", style: TextStyle(fontSize: 15)),
        const SizedBox(height: 12),
        FutureBuilder<List<String>>(
          future: controller.getDataKelasYangAda(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Text("Error: ${snapshot.error}");
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("Tidak ada kelas yang sesuai dengan fase ini.", style: TextStyle(fontStyle: FontStyle.italic));
            return Wrap(
              spacing: 8.0, runSpacing: 8.0,
              children: snapshot.data!.map((kelas) => ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade100, foregroundColor: Colors.indigo.shade900),
                  onPressed: () { controller.kelasSiswaC.text = kelas; _showPilihSiswaBottomSheet(context, kelas); },
                  child: Text("Kelas $kelas"),
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text("Anggota Saat Ini:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
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
                      onPressed: () => controller.deleteSiswaFromGroup(siswaData['nisn'], siswaData['namasiswa']),
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: controller.finishAndGoBack,
          child: const Text('Selesai & Kembali ke Home'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), foregroundColor: Colors.orange.shade800, side: BorderSide(color: Colors.orange.shade800)),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Buat Kelompok Baru Lagi'),
          onPressed: controller.resetPage,
        ),
        const SizedBox(height: 12),
        // TOMBOL BARU: Untuk membatalkan dan menghapus kelompok kosong.
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
  Widget _buildDropdown({ required String label, required Future<List<String>> Function() getItems, required void Function(String?) onChanged }) {
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
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
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

  void _showPilihSiswaBottomSheet(BuildContext context, String kelas) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        child: Column(
          children: [
            Text("Pilih Siswa dari Kelas $kelas", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: controller.streamSiswaBaru(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Semua siswa di kelas ini sudah punya kelompok.'));
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final siswaData = snapshot.data!.docs[index].data();
                      final namaSiswa = siswaData['namasiswa'] ?? 'Tanpa Nama';
                      final nisnSiswa = siswaData['nisn'] ?? '';
                      return ListTile(
                        title: Text(namaSiswa),
                        subtitle: Text("NISN: $nisnSiswa"),
                        trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onTap: () {
                          if (nisnSiswa.isNotEmpty) {
                            controller.addSiswaToGroup(namaSiswa, nisnSiswa);
                          } else {
                            Get.snackbar("Error", "Siswa ini tidak memiliki NISN.");
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}