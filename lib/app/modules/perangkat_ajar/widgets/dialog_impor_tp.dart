// app/modules/perangkat_ajar/widgets/dialog_impor_tp.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sdit_ui_yogyakarta/app/models/atp_model.dart';

class DialogImporTp extends StatelessWidget {
  final List<UnitPembelajaran> units;
  const DialogImporTp({Key? key, required this.units}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // State lokal untuk menyimpan unit yang dipilih
    final RxList<UnitPembelajaran> unitTerpilih = <UnitPembelajaran>[].obs;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Impor Tujuan Pembelajaran", style: Get.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Pilih satu atau lebih Unit Pembelajaran dari ATP untuk diimpor."),
            SizedBox(height: 16),
            
            Container(
              height: 300, // Batas tinggi
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  return Obx(() => CheckboxListTile(
                    title: Text(unit.lingkupMateri),
                    subtitle: Text("${unit.tujuanPembelajaran.length} Tujuan Pembelajaran"),
                    value: unitTerpilih.contains(unit),
                    onChanged: (isSelected) {
                      if (isSelected == true) {
                        unitTerpilih.add(unit);
                      } else {
                        unitTerpilih.remove(unit);
                      }
                    },
                  ));
                },
              ),
            ),
            SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Get.back(), child: Text("Batal")),
                SizedBox(width: 8),
                Obx(() => ElevatedButton(
                  // Kirim hasil pilihan kembali ke pemanggil dialog
                  onPressed: unitTerpilih.isEmpty ? null : () => Get.back(result: unitTerpilih.toList()),
                  child: Text("Impor ${unitTerpilih.length} Unit"),
                )),
              ],
            )
          ],
        ),
      ),
    );
  }
}