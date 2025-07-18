// app/modules/perangkat_ajar/widgets/dialog_salin_data.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/perangkat_ajar_controller.dart';
import '../../../models/atp_model.dart';
import '../../../models/modul_ajar_model.dart';

class DialogSalinData extends StatelessWidget {
  final String jenisPerangkat; // 'ATP' atau 'Modul Ajar'

  const DialogSalinData({Key? key, required this.jenisPerangkat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PerangkatAjarController>();
    
    // State lokal khusus untuk dialog ini
    final RxString tahunTerpilih = ''.obs;
    final RxList<dynamic> daftarItemTersedia = <dynamic>[].obs;
    final RxList<String> idItemTerpilih = <String>[].obs;
    final RxBool isLoadingItem = false.obs;

    void fetchItemsFromTahun(String tahunNama) async {
      isLoadingItem.value = true;
      daftarItemTersedia.clear();
      idItemTerpilih.clear();
      String tahunId = tahunNama.replaceAll('/', '-');
      
      if (jenisPerangkat == 'ATP') {
        daftarItemTersedia.value = await controller.getAtpListFromTahun(tahunId);
      } else {
        daftarItemTersedia.value = await controller.getModulAjarListFromTahun(tahunId);
      }
      isLoadingItem.value = false;
    }

    void salinItemTerpilih() async {
      if (idItemTerpilih.isEmpty) {
        Get.snackbar("Peringatan", "Pilih minimal satu item untuk disalin.");
        return;
      }
      
      String tahunTujuanId = controller.tahunAjaranAktif.value;
      String tahunTujuanNama = controller.homeC.idTahunAjaran.value ?? "ini";
      List<Future> salinTasks = [];

      for (var id in idItemTerpilih) {
        if (jenisPerangkat == 'ATP') {
          final atpUntukDisalin = daftarItemTersedia.firstWhere((item) => item.idAtp == id, orElse: () => null) as AtpModel?;
          if (atpUntukDisalin != null) {
            salinTasks.add(controller.duplikasiAtp(atpUntukDisalin, tahunTujuanId));
          }
        } else {
          final modulUntukDisalin = daftarItemTersedia.firstWhere((item) => item.idModul == id, orElse: () => null) as ModulAjarModel?;
          if (modulUntukDisalin != null) {
            // Memanggil fungsi duplikasi modul ajar yang baru dibuat
            salinTasks.add(controller.duplikasiModulAjar(modulUntukDisalin, tahunTujuanId));
          }
        }
      }

      if (salinTasks.isEmpty) {
        Get.snackbar("Error", "Gagal menemukan item yang valid untuk disalin.");
        return;
      }
      
      Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
      
      try {
        await Future.wait(salinTasks);
        
        if (Get.isDialogOpen ?? false) Get.back(); // Tutup dialog loading
        await Future.delayed(Duration(milliseconds: 100));
        if (Get.isDialogOpen ?? false) Get.back(); // Tutup dialog salin data

        await controller.fetchAllData();
        
        Get.snackbar(
          "Berhasil", 
          "${idItemTerpilih.length} item berhasil disalin ke tahun ajaran $tahunTujuanNama",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
      } catch (e) {
        if (Get.isDialogOpen ?? false) Get.back();
        controller.showErrorSnackbar("Gagal Menyalin", e.toString());
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Salin $jenisPerangkat", style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            
            Obx(() => DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(border: OutlineInputBorder(), labelText: "Tahun Ajaran Sumber"),
              hint: Text("Pilih Tahun Ajaran"),
              value: tahunTerpilih.value.isEmpty ? null : tahunTerpilih.value,
              items: controller.daftarTahunAjaranLama.map((tahun) {
                return DropdownMenuItem(value: tahun, child: Text(tahun));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  tahunTerpilih.value = value;
                  fetchItemsFromTahun(value);
                }
              },
            )),
            SizedBox(height: 16),
            
            Text("Pilih item untuk disalin:", style: Get.textTheme.titleSmall),
            SizedBox(height: 8),

            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Obx(() {
                if (isLoadingItem.value) return Center(child: CircularProgressIndicator());
                if (daftarItemTersedia.isEmpty) return Center(child: Text("Tidak ada data di tahun ajaran ini.", style: TextStyle(color: Colors.grey)));
                
                return ListView.builder(
                    itemCount: daftarItemTersedia.length,
                    itemBuilder: (ctx, idx) {
                      final item = daftarItemTersedia[idx];
                      final String id = (jenisPerangkat == 'ATP') ? item.idAtp : item.idModul;
                      final String title = (jenisPerangkat == 'ATP') ? item.namaMapel : item.mapel;
                      
                      return Obx(() => CheckboxListTile(
                        title: Text(title),
                        value: idItemTerpilih.contains(id),
                        onChanged: (isSelected) {
                          if (isSelected == true) {
                            idItemTerpilih.add(id);
                          } else {
                            idItemTerpilih.remove(id);
                          }
                        },
                      ));
                    }
                );
              }),
            ),
            SizedBox(height: 24),
            
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: Get.back, child: Text("Batal")),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: idItemTerpilih.isEmpty ? null : salinItemTerpilih,
                  child: Text("Salin ${idItemTerpilih.length} Item"),
                ),
              ],
            ))
          ],
        ),
      ),
    );
  }
}