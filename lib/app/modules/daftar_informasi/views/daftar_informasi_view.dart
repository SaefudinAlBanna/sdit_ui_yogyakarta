import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/pages/home.dart';

import '../controllers/daftar_informasi_controller.dart';

class DaftarInformasiView extends GetView<DaftarInformasiController> {
  const DaftarInformasiView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Informasi'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: controller.streamAllInformasiSekolah(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Tidak ada informasi untuk ditampilkan.'));
          }

          final allInfo = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: allInfo.length,
            itemBuilder: (context, index) {
              // Di sini kita bisa membangun card yang sama seperti di home
              // atau membuat widget baru yang bisa digunakan bersama.
              // Untuk kemudahan, kita akan buat ulang card-nya di sini.
              final data = allInfo[index].data();
              // Build Card widget for each informasi
              String formattedDate = "Tanggal tidak valid";
              if (data['tanggalinput'] is String) {
                try {
                  final dt = DateTime.parse(data['tanggalinput']);
                  formattedDate = 
                    // You may need to import intl and initialize locale if not done
                    // import 'package:intl/intl.dart';
                    // Intl.defaultLocale = 'id_ID';
                    // DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(dt);
                    dt.toLocal().toString(); // fallback if DateFormat not available
                } catch (e) {/* biarkan default */}
              }
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Get.toNamed(Routes.TAMPILKAN_INFO_SEKOLAH, arguments: data),
                  child: Row(
                    children: [
                      // If you use CachedNetworkImage, make sure to import it
                      // import 'package:cached_network_image/cached_network_image.dart';
                      // Otherwise, use Image.network as fallback
                      Image.network(
                        data['imageUrl'] ?? "https://picsum.photos/id/${index + 356}/200/200",
                        width: 100, height: 100, fit: BoxFit.cover,
                        // You can add loading/error widgets if needed
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['judulinformasi'] ?? '',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['informasisekolah'] ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedDate,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}