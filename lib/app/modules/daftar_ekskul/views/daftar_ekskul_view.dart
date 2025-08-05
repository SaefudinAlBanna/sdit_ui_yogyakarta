import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/daftar_ekskul_controller.dart';

class DaftarEkskulView extends GetView<DaftarEkskulController> {
  const DaftarEkskulView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Ekstrakurikuler Siswa'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownKelas(),
            const SizedBox(height: 20),
            const Text(
              "Daftar Siswa",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(child: _buildDaftarSiswa()),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownKelas() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return DropdownButtonFormField<String>(
        value: controller.selectedKelas.value,
        decoration: InputDecoration(
          labelText: 'Pilih Kelas',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.class_),
        ),
        hint: const Text('Pilih Kelas...'),
        onChanged: (value) {
          if (value != null) {
            controller.fetchSiswaDanEkskul(value);
          }
        },
        items: controller.daftarKelas.map((kelas) {
          return DropdownMenuItem<String>(
            value: kelas,
            child: Text(kelas),
          );
        }).toList(),
      );
    });
  }

  Widget _buildDaftarSiswa() {
    return Obx(() {
     if (controller.isSiswaLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.selectedKelas.value == null) {
        return _buildEmptyState("Silakan pilih kelas terlebih dahulu.", Icons.arrow_upward);
      }
      
      // Gunakan state yang baru
      if (controller.daftarSiswaDenganEkskul.isEmpty) {
        return _buildEmptyState("Tidak ada siswa di kelas ini.", Icons.people_outline);
      }

      return ListView.builder(
        itemCount: controller.daftarSiswaDenganEkskul.length,
        itemBuilder: (context, index) {
          final siswaData = controller.daftarSiswaDenganEkskul[index];
          final List<dynamic> ekskul = siswaData['daftar_ekskul'] ?? [];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: Text(
                  siswaData['nama']?.substring(0, 1) ?? 'S', // Asumsi field 'nama'
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),
              title: Text(siswaData['namasiswa'] ?? 'Nama tidak ada', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ID: ${siswaData['id'] ?? ''}"),
                  const SizedBox(height: 4),
                  if (ekskul.isNotEmpty)
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: ekskul.map((namaEkskul) => Chip(
                        label: Text(namaEkskul.toString(), style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.grey.shade200,
                        padding: EdgeInsets.zero,
                      )).toList(),
                    )
                  else
                    const Text("Belum ada ekskul", style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.teal),
                onPressed: () => controller.goToInputEkskul(siswaData),
              ),
            ),
          );
        },
      );
    });
  }
  
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}