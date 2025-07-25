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
    Get.put(KelasTahfidzController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelas Tahfidz'),
        actions: [
          Obx(() {
            // Tampilkan tombol ini hanya jika user punya akses dan bukan read-only
            if (controller.hasAccess.value && !controller.isReadOnly.value) {
              return IconButton(
                icon: const Icon(Icons.print_rounded),
                tooltip: 'Cetak Laporan Kelas',
                onPressed: () {
                  // Panggil fungsi baru di controller
                  controller.showCetakLaporanKelasDialog();
                },
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
        
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (!controller.hasAccess.value) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Anda tidak memiliki akses ke fitur ini.", textAlign: TextAlign.center)));
        return _buildMainUI();
      }),
    );
  }

  Widget _buildMainUI() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildHeaderInfo(),
        const SizedBox(height: 24),
        _buildPendampingSection(),
        const SizedBox(height: 24),
        _buildSiswaListSection(),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Obx(() => ListTile(leading: const Icon(Icons.class_outlined, color: Colors.indigo), title: const Text("Kelas"), subtitle: Text(controller.namaKelas.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)))),
            const Divider(),
            Obx(() => ListTile(leading: const Icon(Icons.person_outline, color: Colors.indigo), title: const Text("Wali Kelas"), subtitle: Text(controller.namaWaliKelas.value, style: const TextStyle(fontSize: 16, color: Colors.black87)))),
          ],
        ),
      ),
    );
  }

  Widget _buildPendampingSection() {
    return Obx(() {
      if (!controller.canManagePendamping.value) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Guru Pendamping", style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined, color: Colors.green),
                  title: const Text("Tambah Pendamping Baru"),
                  onTap: () => _showAddPendampingDialog(),
                ),
                const Divider(height: 1),
                if (controller.daftarPendamping.isEmpty)
                  const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text("Belum ada guru pendamping.")))
                else
                  ...controller.daftarPendamping.entries.map((entry) {
                    return ListTile(
                      leading: const Icon(Icons.account_circle, color: Colors.grey),
                      title: Text(entry.value),
                      subtitle: const Text("Klik untuk atur siswa binaan"),
                      onTap: () => _showDelegasiDialog(entry.key, entry.value),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: "Hapus Pendamping",
                        onPressed: () => Get.defaultDialog(
                          title: "Konfirmasi", middleText: "Hapus ${entry.value} dari daftar pendamping?",
                          textConfirm: "Ya, Hapus", textCancel: "Batal", confirmTextColor: Colors.white,
                          onConfirm: () { Get.back(); controller.removePendamping(entry.key); }
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSiswaListSection() {
    return Obx(() {
      final String currentUserUid = controller.auth.currentUser!.uid;
      final List<Widget> grupPendampingLain = controller.siswaPerPendamping.entries
          .where((entry) => entry.key != currentUserUid)
          .map((entry) => _buildSiswaGroup(title: "Binaan: ${controller.daftarPendamping[entry.key] ?? ''}", listSiswa: entry.value))
          .toList();
      final Widget grupWaliKelas = controller.siswaDikelolaWali.isNotEmpty
          ? _buildSiswaGroup(title: "Dikelola oleh Wali Kelas", listSiswa: controller.siswaDikelolaWali)
          : const SizedBox.shrink();
      final Widget grupSayaSendiri = controller.siswaPerPendamping.containsKey(currentUserUid)
          ? _buildSiswaGroup(title: "Siswa Binaan Anda", listSiswa: controller.siswaPerPendamping[currentUserUid]!)
          : const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Daftar Siswa", style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (!controller.isReadOnly.value)
                TextButton.icon(
                  icon: const Icon(Icons.list_alt, size: 18), label: const Text("Input Massal"),
                  onPressed: () {
                    if (controller.homeC.walikelas) {
                      _showPilihanInputMassalDialog();
                    } else {
                      controller.prepareAndShowNilaiMassalDialog(mode: 'pendamping');
                    }
                  },
                )
            ],
          ),
          const SizedBox(height: 12),
          if (controller.siswaDikelolaWali.isEmpty && controller.siswaPerPendamping.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("Belum ada siswa di kelas ini."))),
          
          if (controller.homeC.walikelas) ...[
            grupWaliKelas, ...grupPendampingLain,
          ] else ...[
            grupSayaSendiri, ...grupPendampingLain, grupWaliKelas,
          ],
        ],
      );
    });
  }

  Widget _buildSiswaGroup({required String title, required List<Map<String, dynamic>> listSiswa}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        initiallyExpanded: true,
        children: listSiswa.map((siswa) {
          final nisn = siswa['id'] as String;
          final isCardEditable = controller.nisnBagianSaya.contains(nisn);
          return _SiswaCard(siswa: siswa, isEditable: isCardEditable, view: this);
        }).toList(),
      ),
    );
  }

  void _showPilihanInputMassalDialog() {
    Get.defaultDialog(
      title: "Pilih Target Siswa",
      middleText: "Anda ingin menginput nilai massal untuk siapa?",
      actions: [
        ListTile(title: Text("Hanya Siswa Binaan Saya"), onTap: () { Get.back(); controller.prepareAndShowNilaiMassalDialog(mode: 'wali_saja'); }),
        ListTile(title: Text("Semua Siswa di Kelas Ini"), onTap: () { Get.back(); controller.prepareAndShowNilaiMassalDialog(mode: 'semua_siswa'); }),
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

  
  void _showDelegasiDialog(String uidPendamping, String namaPendamping) {
    // Simpan pilihan sementara dalam RxList agar UI reaktif
    final RxList<String> nisnTerpilih = RxList<String>.from(controller.delegasiSiswa[uidPendamping] ?? []);

    Get.defaultDialog(
      title: "Delegasi untuk $namaPendamping",
      content: SizedBox(
        width: Get.width,
        height: Get.height * 0.5,
        child: ListView.builder(
          itemCount: controller.semuaSiswa.length,
          itemBuilder: (context, index) {
            final siswa = controller.semuaSiswa[index];
            final nisn = siswa['id'] as String;
            return Obx(() => CheckboxListTile(
              title: Text(siswa['namasiswa']),
              value: nisnTerpilih.contains(nisn),
              onChanged: (bool? value) {
                if (value == true) {
                  nisnTerpilih.add(nisn);
                } else {
                  nisnTerpilih.remove(nisn);
                }
              },
            ));
          },
        ),
      ),
      textConfirm: "Simpan",
      textCancel: "Batal",
      onConfirm: () => controller.saveDelegasi(uidPendamping, nisnTerpilih.toList()),
    );
  }

  Widget _buildFormSection(String namaSiswa, String nisn, bool isEditable) {
    return SingleChildScrollView( // Bungkus form dengan SingleChildScrollView
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Obx(() => Text(controller.isEditMode ? "Edit Penilaian" : "Input Penilaian Baru", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Flexible(child: Text(namaSiswa, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis)),
          ]),
          const Divider(height: 20),
          Obx(() => TextFormField(controller: controller.murojaahC, readOnly: !isEditable || controller.isEditMode, validator: (v) => (v!.isEmpty && controller.hafalanC.text.isEmpty) ? 'Isi Murojaah atau Hafalan' : null, decoration: InputDecoration(labelText: "Murojaah (Contoh: QS. An-Naba')", border: OutlineInputBorder(), filled: !isEditable || controller.isEditMode, fillColor: Colors.grey[100]))),
          const SizedBox(height: 10),
          Obx(() => TextFormField(controller: controller.hafalanC, readOnly: !isEditable || controller.isEditMode, validator: (v) => (v!.isEmpty && controller.murojaahC.text.isEmpty) ? 'Isi Murojaah atau Hafalan' : null, decoration: InputDecoration(labelText: "Hafalan Baru (Contoh: QS. Al-Baqarah: 1-5)", border: OutlineInputBorder(), filled: !isEditable || controller.isEditMode, fillColor: Colors.grey[100]))),
          const SizedBox(height: 10),
          TextFormField(controller: controller.nilaiC, readOnly: !isEditable, validator: (v) => (v?.isEmpty ?? true) ? 'Nilai tidak boleh kosong' : null, decoration: InputDecoration(labelText: "Nilai", border: OutlineInputBorder(), filled: !isEditable, fillColor: Colors.grey[100]), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 10),
          TextFormField(controller: controller.catatanGuruC, readOnly: !isEditable, decoration: InputDecoration(labelText: "Catatan Guru (Opsional)", border: OutlineInputBorder(), filled: !isEditable, fillColor: Colors.grey[100])),
          const SizedBox(height: 16),
          if (isEditable)
            Row(children: [
              Expanded(child: Obx(() => ElevatedButton(onPressed: controller.isSaving.value ? null : () => controller.saveCatatanTahfidz(nisn), child: controller.isSaving.value ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(controller.isEditMode ? "Update" : "Simpan")))),
              Obx(() => controller.isEditMode ? Padding(padding: const EdgeInsets.only(left: 8.0), child: IconButton(icon: const Icon(Icons.close), tooltip: "Batal Edit", onPressed: () => controller.clearForm())) : const SizedBox.shrink())
            ]),
        ],
      ),
    );
  }

  void _showPenilaianDetailSheet(Map<String, dynamic> siswa, {required bool isEditable}) {
    final nisn = siswa['id'] as String;
    final namaSiswa = siswa['namasiswa'] as String;
    controller.clearForm();

    Get.bottomSheet(
      Form(
        key: controller.formKey,
        child: Container(
          height: Get.height * 0.9,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          child: Column(
            children: [
              // Bagian Form (tingginya fleksibel seperlunya)
              _buildFormSection(namaSiswa, nisn, isEditable),
              const Divider(height: 1),
              // Bagian Riwayat (mengisi semua sisa ruang yang ada)
              Expanded(
                child: _buildHistorySection(namaSiswa, nisn, isEditable),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildHistorySection(String namaSiswa, String nisn, bool isEditable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Riwayat Penilaian", style: TextStyle(fontWeight: FontWeight.bold)),
            if (isEditable)
              TextButton.icon(icon: const Icon(Icons.print_outlined, size: 18), label: const Text("Cetak"), onPressed: () async {
                final snapshot = await controller.firestore.collection('Sekolah').doc(controller.homeC.idSekolah).collection('tahunajaran').doc(controller.homeC.idTahunAjaran.value!).collection('kelastahunajaran').doc(controller.idKelas.value).collection('semester').doc(controller.homeC.semesterAktifId.value).collection('daftarsiswa').doc(nisn).collection('catatan_tahfidz').orderBy('tanggal_penilaian', descending: true).get();
                controller.generateAndPrintPdf(namaSiswa, nisn, snapshot.docs);
              }),
          ]),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: controller.getCatatanTahfidzStream(nisn),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada riwayat penilaian."));
              final catatanList = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: catatanList.length,
                itemBuilder: (context, index) {
                  final doc = catatanList[index];
                  final data = doc.data();
                  final timestamp = data['tanggal_penilaian'] as Timestamp;
                  final tanggal = DateFormat('dd MMM\nyyyy', 'id_ID').format(timestamp.toDate());
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      title: Text("Murojaah: ${data['murojaah'] ?? '-'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text("Hafalan: ${data['hafalan'] ?? '-'}\nNilai: ${data['nilai']} | Oleh: ${data['penilai_nama']}"),
                      isThreeLine: true,
                      leading: Text(tanggal, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                      trailing: isEditable ? Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20), onPressed: () => controller.startEdit(data, doc.id)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => Get.defaultDialog(title: "Konfirmasi", middleText: "Hapus catatan ini?", onConfirm: () { Get.back(); controller.deleteCatatanTahfidz(nisn, doc.id); })),
                      ]) : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


class _SiswaCard extends StatelessWidget {
  final Map<String, dynamic> siswa;
  final KelasTahfidzView view;
  final bool isEditable;
  const _SiswaCard({required this.siswa, required this.isEditable, required this.view});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KelasTahfidzController>();
    final namaSiswa = siswa['namasiswa'] ?? 'Tanpa Nama';
    final nisn = siswa['id'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Text(namaSiswa.isNotEmpty ? namaSiswa[0] : '-')),
        title: Text(namaSiswa, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
          stream: controller.getLastNilaiStream(nisn),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Text("Memuat nilai...", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic));
            if (!snapshot.hasData || snapshot.data == null) return const Text("Belum ada nilai", style: TextStyle(fontSize: 12, color: Colors.grey));
            final dataNilai = snapshot.data!.data()!;
            final murojaah = dataNilai['murojaah'];
            final hafalan = dataNilai['hafalan'];
            String textToShow = hafalan != null && hafalan.isNotEmpty ? "Hafalan: $hafalan" : "Murojaah: $murojaah";
            return Text(
              "$textToShow - Nilai: ${dataNilai['nilai']}",
              style: const TextStyle(fontSize: 12, color: Colors.deepPurple, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            );
          },
        ),
        trailing: isEditable
            ? OutlinedButton.icon(icon: const Icon(Icons.edit_note, size: 18), label: const Text("Nilai"), onPressed: () => view._showPenilaianDetailSheet(siswa, isEditable: isEditable))
            : OutlinedButton.icon(icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text("Lihat"), onPressed: () => view._showPenilaianDetailSheet(siswa, isEditable: isEditable)),
      ),
    );
  }
}