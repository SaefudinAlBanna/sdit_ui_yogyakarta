import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/tampilkan_info_sekolah_controller.dart';

class TampilkanInfoSekolahView extends GetView<TampilkanInfoSekolahController> {
  const TampilkanInfoSekolahView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Kita gunakan CustomScrollView untuk efek AppBar yang bisa collapse
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                controller.judul,
                style: const TextStyle(fontSize: 16, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: true,
              background: Obx(() => CachedNetworkImage(
                imageUrl: controller.gambarUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey.shade300),
                errorWidget: (context, url, error) => const Center(child: Icon(Icons.image_not_supported, color: Colors.white, size: 50)),
              )),
            ),
          ),
          // Bagian konten di bawah AppBar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul utama yang besar
                  Obx(() => Text(
                    controller.judul,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  )),
                  const SizedBox(height: 12),
                  // Metadata: Penginput dan Tanggal
                  Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    color: Colors.grey.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          _buildMetaRow(context, Icons.person_outline, "Diinput oleh", controller.penginput),
                          const Divider(height: 16),
                          _buildMetaRow(context, Icons.calendar_today_outlined, "Tanggal", controller.tanggal),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Isi informasi
                  Obx(() => Text(
                    controller.isi,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5), // Beri jarak antar baris
                  )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Widget helper untuk baris metadata agar rapi
  Widget _buildMetaRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text("$label: ", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}