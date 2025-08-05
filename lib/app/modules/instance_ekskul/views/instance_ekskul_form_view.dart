// File: lib/app/modules/admin_manajemen/views/instance_ekskul_form_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart'; // <-- Gunakan ini
import '../controllers/instance_ekskul_controller.dart';
import '../../../models/master_ekskul_model.dart';

class InstanceEkskulFormView extends GetView<InstanceEkskulController> {
  final String? instanceId;
  const InstanceEkskulFormView({super.key, this.instanceId});

  bool get isUpdateMode => instanceId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isUpdateMode ? 'Edit Ekskul' : 'Buka Ekskul Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PEROMBAKAN 1: Pemilihan Master Ekskul ---
              _buildMasterEkskulSelector(context),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: controller.namaTampilanC,
                decoration: const InputDecoration(labelText: 'Nama Tampilan Spesifik (cth: Tim Inti)', border: OutlineInputBorder()),
                validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // --- PEROMBAKAN 2: Pemilihan Pembina ---
              _buildPembinaSelector(),
              const SizedBox(height: 16),

              // ... Sisa form tidak berubah ...
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedHari.value,
                      decoration: const InputDecoration(labelText: 'Hari', border: OutlineInputBorder()),
                      items: controller.hariOptions.map((hari) => DropdownMenuItem(value: hari, child: Text(hari))).toList(),
                      onChanged: (value) => controller.selectedHari.value = value,
                      validator: (value) => value == null ? 'Wajib' : null,
                    )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: controller.jamMulaiC,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Mulai', border: OutlineInputBorder()),
                      onTap: () async {
                          await controller.selectTime(context, controller.jamMulaiC);
                          controller.formKey.currentState?.validate();
                      },
                       validator: (value) => (value?.isEmpty ?? true) ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                   Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: controller.jamSelesaiC,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Selesai', border: OutlineInputBorder()),
                      onTap: () async {
                          await controller.selectTime(context, controller.jamSelesaiC);
                          controller.formKey.currentState?.validate();
                      },
                       validator: (value) {
                         if (value?.isEmpty ?? true) return 'Wajib';
                         if (controller.jamMulaiC.text.isNotEmpty) {
                           final startTime = TimeOfDay(hour: int.parse(controller.jamMulaiC.text.split(":")[0]), minute: int.parse(controller.jamMulaiC.text.split(":")[1]));
                           final endTime = TimeOfDay(hour: int.parse(value!.split(":")[0]), minute: int.parse(value.split(":")[1]));
                           final startMinutes = startTime.hour * 60 + startTime.minute;
                           final endMinutes = endTime.hour * 60 + endTime.minute;
                           if (endMinutes <= startMinutes) {
                             return 'Jam Selesai harus setelah Jam Mulai';
                           }
                         }
                         return null;
                       },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: controller.lokasiC,
                decoration: const InputDecoration(labelText: 'Lokasi', border: OutlineInputBorder()),
                 validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton( // Bungkus dengan Obx
                  onPressed: controller.isLoading.value 
                    ? null // Nonaktifkan saat menyimpan
                    : () {
                      // Panggil fungsi yang baru kita buat
                      controller.saveInstanceEkskul(existingInstanceId: instanceId);
                    },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey,
                  ),
                  child: controller.isLoading.value 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan'),
                )),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER BARU ---
  Widget _buildMasterEkskulSelector(BuildContext context) {
    // Gunakan controller sementara untuk textfield ini agar tidak mengganggu state utama
    final TextEditingController textEditingController = TextEditingController();
    
    return Obx(() {
      // Update text di field setiap kali state berubah
      textEditingController.text = controller.selectedMasterEkskul.value?.namaMaster ?? '';
      
      return TextFormField(
        controller: textEditingController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Jenis Ekskul Induk',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.arrow_drop_down)
        ),
        onTap: () => _showPilihMasterEkskulDialog(context),
        validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
      );
    });
  }

  Future<void> _showPilihMasterEkskulDialog(BuildContext context) {
    // State lokal hanya untuk dialog ini
    final RxString searchQuery = ''.obs;

    return Get.dialog(
      AlertDialog(
        title: const Text('Pilih Ekskul Induk'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => searchQuery.value = value,
                decoration: const InputDecoration(
                  labelText: 'Cari...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              Obx(() {
                  final filteredList = controller.opsiMasterEkskul.where((ekskul) =>
                      ekskul.namaMaster.toLowerCase().contains(searchQuery.value.toLowerCase())
                  ).toList();

                  return Expanded(
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final ekskul = filteredList[index];
                        return ListTile(
                          title: Text(ekskul.namaMaster),
                          onTap: () {
                            controller.selectedMasterEkskul.value = ekskul;
                            Get.back(); // Tutup dialog
                          },
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildPembinaSelector() {
    return Obx(() => MultiSelectDialogField<PembinaOption>(
          items: controller.opsiPembina
              .map((p) => MultiSelectItem<PembinaOption>(p, p.nama))
              .toList(),
          initialValue: controller.selectedPembina.toList(),
          title: const Text("Pilih Pembina"),
          buttonText: const Text("Pembina"),
          buttonIcon: const Icon(Icons.people),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          onConfirm: (values) {
            controller.selectedPembina.value = values;
          },
          chipDisplay: MultiSelectChipDisplay(
            onTap: (value) {
              controller.selectedPembina.remove(value);
            },
          ),
          validator: (value) => (value == null || value.isEmpty) ? 'Wajib pilih minimal satu pembina' : null,
        ));
  }
}


// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../models/master_ekskul_model.dart';
// import '../controllers/instance_ekskul_controller.dart';

// class InstanceEkskulFormView extends GetView<InstanceEkskulController> {
//   final String? instanceId;
//   const InstanceEkskulFormView({super.key, this.instanceId});

//   bool get isUpdateMode => instanceId != null;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(isUpdateMode ? 'Edit Ekskul' : 'Buka Ekskul Baru'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: controller.formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // --- Pilih Master Ekskul ---
//               // --- PERUBAHAN STRATEGIS: Menggunakan asyncItems ---
//               Obx(() => DropdownSearch<MasterEkskulModel>(
//                 // `items` properti DIBUANG, diganti dengan asyncItems
//                 items: (f, cs) async {
//                   // Kita membuat future sederhana yang langsung mengembalikan list dari controller
//                   return Future.value(controller.opsiMasterEkskul.toList());
//                 },
//                 selectedItem: controller.selectedMasterEkskul.value,
//                 itemAsString: (MasterEkskulModel m) => m.namaMaster,
//                 popupProps: const PopupProps.menu(showSearchBox: true, searchFieldProps: TextFieldProps(decoration: InputDecoration(labelText: 'Cari Ekskul'))),
//                 decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "Jenis Ekskul Induk", border: OutlineInputBorder())),
//                 onChanged: (value) => controller.selectedMasterEkskul.value = value,
//                 validator: (value) => value == null ? 'Wajib diisi' : null,
//               )),
//               const SizedBox(height: 16),
              
//               TextFormField(
//                 controller: controller.namaTampilanC,
//                 decoration: const InputDecoration(labelText: 'Nama Tampilan Spesifik (cth: Tim Inti)', border: OutlineInputBorder()),
//                 validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
//               ),
//               const SizedBox(height: 16),

//               // --- Pilih Pembina ---
//               // --- PERUBAHAN STRATEGIS: Menggunakan asyncItems ---
//               Obx(() => DropdownSearch.multiSelection<PembinaOption>(
//                   selectedItems: controller.selectedPembina.toList(),
//                   itemAsString: (p) => p.nama,
//                   asyncItems: (String? filter) async {
//                     return controller.opsiPembina.toList();
//                   },
//                   popupProps: PopupPropsMultiSelection.menu(
//                     showSearchBox: true,
//                     searchFieldProps: const TextFieldProps(decoration: InputDecoration(labelText: 'Cari Pembina')),
//                     itemBuilder: (context, item, isSelected) {
//                       return ListTile(
//                         title: Text(item.nama),
//                         subtitle: Text(item.detail),
//                         trailing: isSelected
//                             ? const Icon(Icons.check_box, color: Colors.blue)
//                             : const Icon(Icons.check_box_outline_blank),
//                       );
//                     },
//                   ),
//                   decoratorProps: const DropDownDecoratorProps(decoration: InputDecoration(labelText: "Pilih Pembina", border: OutlineInputBorder())),
//                   onChanged: (value) => controller.selectedPembina.value = value,
//                   validator: (value) => (value == null || value.isEmpty) ? 'Wajib pilih minimal satu pembina' : null,
//                 )),
//               const SizedBox(height: 16),

//               Row(
//                 children: [
//                   Expanded(
//                     flex: 3,
//                     child: DropdownButtonFormField<String>(
//                       value: controller.selectedHari.value,
//                       decoration: const InputDecoration(labelText: 'Hari', border: OutlineInputBorder()),
//                       items: controller.hariOptions.map((hari) => DropdownMenuItem(value: hari, child: Text(hari))).toList(),
//                       onChanged: (value) => controller.selectedHari.value = value,
//                       validator: (value) => value == null ? 'Wajib' : null,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     flex: 2,
//                     child: TextFormField(
//                       controller: controller.jamMulaiC,
//                       readOnly: true,
//                       decoration: const InputDecoration(labelText: 'Mulai', border: OutlineInputBorder()),
//                       onTap: () async {
//                           await controller.selectTime(context, controller.jamMulaiC);
//                           // Setelah jam mulai dipilih, trigger validasi pada form
//                           controller.formKey.currentState?.validate();
//                       },
//                        validator: (value) => (value?.isEmpty ?? true) ? 'Wajib' : null,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                    Expanded(
//                     flex: 2,
//                     child: TextFormField(
//                       controller: controller.jamSelesaiC,
//                       readOnly: true,
//                       decoration: const InputDecoration(labelText: 'Selesai', border: OutlineInputBorder()),
//                       onTap: () async {
//                           await controller.selectTime(context, controller.jamSelesaiC);
//                           // Setelah jam selesai dipilih, trigger validasi pada form
//                           controller.formKey.currentState?.validate();
//                       },
//                        // --- PENAMBAHAN: "PENJAGA WAKTU" ---
//                        validator: (value) {
//                          if (value?.isEmpty ?? true) {
//                            return 'Wajib';
//                          }
//                          if (controller.jamMulaiC.text.isNotEmpty) {
//                            final startTime = TimeOfDay(hour: int.parse(controller.jamMulaiC.text.split(":")[0]), minute: int.parse(controller.jamMulaiC.text.split(":")[1]));
//                            final endTime = TimeOfDay(hour: int.parse(value!.split(":")[0]), minute: int.parse(value.split(":")[1]));
//                            final startMinutes = startTime.hour * 60 + startTime.minute;
//                            final endMinutes = endTime.hour * 60 + endTime.minute;

//                            if (endMinutes <= startMinutes) {
//                              return 'Jam Selesai harus setelah Jam Mulai';
//                            }
//                          }
//                          return null;
//                        },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
              
//               TextFormField(
//                 controller: controller.lokasiC,
//                 decoration: const InputDecoration(labelText: 'Lokasi', border: OutlineInputBorder()),
//                  validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
//               ),
//               const SizedBox(height: 32),

//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                      if(controller.formKey.currentState!.validate()){
//                        // Placeholder ini akan kita ganti di Bravo-3
//                        Get.snackbar("Siap Disimpan!", "Semua data valid. Logika penyimpanan akan diimplementasikan selanjutnya.");
//                      } else {
//                        Get.snackbar("Perhatian", "Mohon periksa kembali semua isian yang wajib diisi.");
//                      }
//                   },
//                   style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
//                   child: const Text('Simpan'),
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }