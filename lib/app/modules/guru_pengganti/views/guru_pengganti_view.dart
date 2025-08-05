// lib/app/modules/guru_pengganti/views/guru_pengganti_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/guru_pengganti_controller.dart';

class GuruPenggantiView extends GetView<GuruPenggantiController> {
  const GuruPenggantiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Guru Pengganti'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeaderKonteks(context),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(child: _buildJadwalList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderKonteks(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, color: Colors.black54),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(controller.today),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedKelasId.value,
              hint: const Text('Pilih Kelas...'),
              decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder()),
              items: controller.daftarKelas.map((kelas) => DropdownMenuItem<String>(
                value: kelas['id'], child: Text(kelas['nama']))
              ).toList(),
              onChanged: controller.onKelasChanged,
            )),
      ],
    );
  }

  Widget _buildJadwalList() {
    return Obx(() {
      if (controller.selectedKelasId.value == null) {
        return const Center(child: Text("Silakan pilih kelas untuk melihat jadwal."));
      }
      if (controller.isLoadingJadwal.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.jadwalTampil.isEmpty) {
        return const Center(child: Text("Tidak ada jadwal KBM untuk hari ini."));
      }
      return ListView.builder(
        itemCount: controller.jadwalTampil.length,
        itemBuilder: (context, index) {
          final jadwalSlot = controller.jadwalTampil[index];
          return _buildJadwalCard(jadwalSlot);
        },
      );
    });
  }

  Widget _buildJadwalCard(Map<String, dynamic> jadwalSlot) {
    final bool isReplaced = jadwalSlot['isReplaced'];
    final theme = Theme.of(Get.context!);

    return Card(
      color: isReplaced ? Colors.amber.shade50 : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(jadwalSlot['jam'], style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey.shade600)),
            Text(jadwalSlot['namaMapel'], style: theme.textTheme.titleLarge),
            const Divider(),
            isReplaced 
              ? _buildInfoPengganti(jadwalSlot['penggantiInfo'])
              : _buildInfoAsli(jadwalSlot),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoAsli(Map<String, dynamic> jadwalSlot) {
    // [FIX] Ambil nama guru dari List
    final List<dynamic> listNamaGuru = jadwalSlot['listNamaGuru'] ?? [];
    final String namaGuruAsli = listNamaGuru.isNotEmpty ? listNamaGuru.join(', ') : 'Belum Diatur';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text("Guru Asli: $namaGuruAsli")),
        // Nonaktifkan tombol jika guru asli belum diatur di jadwal
        ElevatedButton(
          onPressed: listNamaGuru.isEmpty ? null : () => _showDialogPilihPengganti(jadwalSlot),
          child: const Text("Atur Pengganti"),
        )
      ],
    );
  }

  Widget _buildInfoPengganti(Map<String, dynamic> penggantiInfo) {
    return Column(
      children: [
        Text("Guru Asli: ${penggantiInfo['namaGuruAsli']} (Berhalangan)", style: const TextStyle(decoration: TextDecoration.lineThrough)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text("Digantikan oleh: ${penggantiInfo['namaGuruPengganti']}", style: const TextStyle(fontWeight: FontWeight.bold))),
            TextButton(
              onPressed: () => controller.batalkanPengganti(penggantiInfo['idPenggantiDoc']),
              child: const Text("Batalkan", style: TextStyle(color: Colors.red)),
            )
          ],
        )
      ],
    );
  }

  void _showDialogPilihPengganti(Map<String, dynamic> jadwalSlot) {
    // [FIX] Ambil ID guru asli dari List
    final String idGuruAsli = (jadwalSlot['listIdGuru'] as List?)?.firstOrNull ?? '';
  
    Get.defaultDialog(
      title: "Pilih Guru Pengganti",
      content: FutureBuilder<List<Map<String, dynamic>>>(
        // Kirim ID guru asli yang benar ke fungsi validator
        future: controller.getGuruTersedia(jadwalSlot['jam'], idGuruAsli),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if(!snapshot.hasData || snapshot.data!.isEmpty) return const Text("Tidak ada guru yang tersedia pada jam ini.");

          return SizedBox(
            width: Get.width, height: Get.height * 0.4,
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final guru = snapshot.data![index];
                return ListTile(
                  title: Text(guru['nama']),
                  onTap: () => controller.simpanPengganti(jadwalSlot, guru['uid']),
                );
              },
            ),
          );
        },
      )
    );
  }
}