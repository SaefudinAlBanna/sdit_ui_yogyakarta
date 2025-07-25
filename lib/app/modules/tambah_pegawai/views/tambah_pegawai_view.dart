// lib/app/modules/tambah_pegawai/views/tambah_pegawai_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../controllers/tambah_pegawai_controller.dart';

class TambahPegawaiView extends GetView<TambahPegawaiController> {
  const TambahPegawaiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Controller di-binding melalui routing GetX, tidak perlu Get.put di sini
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditMode ? 'Edit Data Pegawai' : 'Tambah Pegawai Baru')
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Nama Lengkap
              TextFormField(
                controller: controller.namaC,
                decoration: _buildInputDecoration(labelText: 'Nama Lengkap', icon: Icons.person),
                validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              
              // Jenis Kelamin
              Text("Jenis Kelamin", style: theme.textTheme.titleMedium),
              Obx(() => Row(
                children: [
                  Expanded(child: RadioListTile<String>(title: Text("Laki-Laki"), value: "Laki-Laki", groupValue: controller.jenisKelamin.value, onChanged: controller.onChangeJenisKelamin)),
                  Expanded(child: RadioListTile<String>(title: Text("Perempuan"), value: "Perempuan", groupValue: controller.jenisKelamin.value, onChanged: controller.onChangeJenisKelamin)),
                ],
              )),
              SizedBox(height: 8),

              // Email
              TextFormField(
                controller: controller.emailC,
              keyboardType: TextInputType.emailAddress,
              // Buat read-only jika dalam mode edit
              readOnly: controller.isEditMode, 
              decoration: _buildInputDecoration(
                labelText: 'Email', 
                icon: Icons.email
              ).copyWith(
                // Beri warna berbeda agar terlihat non-aktif
                fillColor: controller.isEditMode ? Colors.grey[200] : null
              ),
              validator: (v) => !GetUtils.isEmail(v!) ? 'Format email tidak valid' : null,
              ),
              const SizedBox(height: 16),

              // Pemilihan JABATAN (Single Choice Dropdown)
              Obx(() {
                if (controller.isJabatanLoading.isTrue) return Center(child: CircularProgressIndicator());
                return DropdownButtonFormField<String>(
                  value: controller.jabatanTerpilih.value,
                  decoration: _buildInputDecoration(labelText: 'Jabatan Utama', icon: Icons.work),
                  hint: Text('Pilih satu jabatan...'),
                  items: controller.semuaJabatan.map((jabatan) {
                    return DropdownMenuItem(value: jabatan, child: Text(jabatan));
                  }).toList(),
                  onChanged: controller.onJabatanSelected,
                  validator: (v) => v == null ? 'Jabatan wajib dipilih' : null,
                );
              }),
              const SizedBox(height: 16),

              // Pemilihan TUGAS TAMBAHAN (Multi Choice Dialog)
              Obx(() {
                if (controller.isTugasLoading.isTrue) return Center(child: CircularProgressIndicator());
                return MultiSelectDialogField<String>(
                  buttonIcon: Icon(Icons.arrow_downward),
                  buttonText: Text("Tugas Tambahan (Opsional)"),
                  title: Text("Pilih Tugas"),
                  items: controller.semuaTugas.map((tugas) => MultiSelectItem<String>(tugas, tugas)).toList(),
                  listType: MultiSelectListType.CHIP,
                  onConfirm: controller.onTugasSelected,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                  chipDisplay: MultiSelectChipDisplay(
                    onTap: (value) => controller.tugasTerpilih.remove(value),
                  ),
                );
              }),
              const SizedBox(height: 30),

              // Tombol Simpan
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: controller.validasiDanSimpan,
                child: Obx(() => Text(
                  controller.isLoadingProses.isTrue ? 'MEMPROSES...' : (controller.isEditMode ? 'UPDATE DATA PEGAWAI' : 'SIMPAN DATA PEGAWAI')
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(),
    );
  }
}