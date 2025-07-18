// app/modules/perangkat_ajar/atp_form_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/atp_form_controller.dart';

class AtpFormView extends GetView<AtpFormController> {
  const AtpFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditMode.value ? 'Edit ATP' : 'Tambah ATP')),
        actions: [
          IconButton(
            icon: Icon(Icons.save_rounded),
            onPressed: () => controller.saveAtp(),
            tooltip: 'Simpan',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainInfoSection(),
            SizedBox(height: 24),
            _buildUnitPembelajaranSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Informasi Umum", style: Get.textTheme.titleLarge),
        SizedBox(height: 16),
        TextField(
          controller: controller.mapelC,
          decoration: InputDecoration(labelText: 'Mata Pelajaran', border: OutlineInputBorder()),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: controller.faseC, decoration: InputDecoration(labelText: 'Fase', border: OutlineInputBorder()))),
            SizedBox(width: 12),
            Expanded(child: TextField(controller: controller.kelasC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()))),
          ],
        ),
        SizedBox(height: 12),
        TextField(
          controller: controller.capaianPembelajaranC,
          maxLines: 4,
          decoration: InputDecoration(labelText: 'Capaian Pembelajaran (CP)', border: OutlineInputBorder(), alignLabelWithHint: true),
        ),
      ],
    );
  }

  Widget _buildUnitPembelajaranSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Unit Pembelajaran", style: Get.textTheme.titleLarge),
            ElevatedButton.icon(
              onPressed: () => controller.addUnitPembelajaran(),
              icon: Icon(Icons.add),
              label: Text("Tambah Unit"),
            ),
          ],
        ),
        SizedBox(height: 16),
        Obx(() {
          if (controller.unitPembelajaranForms.isEmpty) {
            return Center(child: Text("Klik 'Tambah Unit' untuk memulai."));
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: controller.unitPembelajaranForms.length,
            separatorBuilder: (ctx, idx) => SizedBox(height: 16),
            itemBuilder: (context, index) {
              final unitForm = controller.unitPembelajaranForms[index];
              return _UnitCard(unitForm: unitForm, index: index);
            },
          );
        }),
      ],
    );
  }
}


// WIDGET KARTU UNTUK SETIAP UNIT PEMBELAJARAN
class _UnitCard extends GetView<AtpFormController> {
  final UnitPembelajaranForm unitForm;
  final int index;
  const _UnitCard({required this.unitForm, required this.index, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Kartu dengan Judul dan Tombol Hapus
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Unit ${index + 1}", style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.delete_forever_rounded, color: Colors.red),
                  onPressed: () => controller.removeUnitPembelajaran(index),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 12),
            TextField(controller: unitForm.lingkupMateriC, decoration: InputDecoration(labelText: 'Lingkup Materi (Judul Bab)')),
            SizedBox(height: 12),
            TextField(controller: unitForm.alokasiWaktuC, decoration: InputDecoration(labelText: 'Alokasi Waktu (Contoh: 12 JP)')),
            SizedBox(height: 12),
            TextField(controller: unitForm.gramatikaC, decoration: InputDecoration(labelText: 'Gramatika')),
            SizedBox(height: 24),

            // Bagian untuk mengelola daftar dinamis (TP & Alur)
            _buildDynamicListSection(
              title: "Tujuan Pembelajaran (TP)",
              list: unitForm.tujuanPembelajaran,
              onAdd: (text) => unitForm.tujuanPembelajaran.add(text),
              onRemove: (idx) => unitForm.tujuanPembelajaran.removeAt(idx),
            ),
            SizedBox(height: 24),
            _buildDynamicListSection(
              title: "Alur Tujuan Pembelajaran (ATP)",
              list: unitForm.alurPembelajaran,
              onAdd: (text) => unitForm.alurPembelajaran.add(text),
              onRemove: (idx) => unitForm.alurPembelajaran.removeAt(idx),
            ),
          ],
        ),
      ),
    );
  }

  // Widget generik untuk menampilkan dan mengelola list dinamis
  Widget _buildDynamicListSection({
    required String title,
    required RxList<String> list,
    required Function(String) onAdd,
    required Function(int) onRemove,
  }) {
    final textController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Obx(() => ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (ctx, idx) => ListTile(
                leading: Text("${idx + 1}."),
                title: Text(list[idx]),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () => onRemove(idx),
                ),
              ),
            )),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextField(controller: textController, decoration: InputDecoration(labelText: 'Tambah baru...'))),
            IconButton(
              icon: Icon(Icons.add_box_rounded, color: Get.theme.primaryColor),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  onAdd(textController.text);
                  textController.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}