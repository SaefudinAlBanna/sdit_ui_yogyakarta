// lib/app/modules/home/pages/upload_materi_page.dart
// (Contoh path jika ini adalah bagian dari BottomNavigationBar di Home)

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:math'; // untuk format ukuran file
import 'package:dotted_border/dotted_border.dart';

// Palet warna yang bisa Anda gunakan secara konsisten
const Color kPrimaryBlue = Color(0xFF0D47A1);
const Color kSecondaryBlue = Color(0xFF42A5F5);
const Color kBackgroundColor = Color(0xFFF4F7FC);

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // AppBar bisa dihilangkan jika halaman ini bagian dari Scaffold utama dengan AppBar
      appBar: AppBar(
        title: const Text("Upload Materi Baru", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN 1: DETAIL MATERI ---
            _buildSectionCard(
              title: "1. Detail Materi",
              child: Column(
                children: [
                  _buildTextField(
                    label: "Judul Materi",
                    hint: "Contoh: Bab 1 - Persamaan Linear",
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: "Deskripsi (Opsional)",
                    hint: "Materi ini membahas tentang...",
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- BAGIAN 2: TARGET PEMBELAJARAN ---
            _buildSectionCard(
              title: "2. Target Pembelajaran",
              child: Column(
                children: [
                  _buildDropdown(
                    label: "Pilih Kelas",
                    hint: "Tujukan materi untuk kelas...",
                    icon: Icons.class_outlined,
                    items: ["Kelas 10A", "Kelas 10B", "Kelas 11A", "Kelas 11B"], // Data dummy
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: "Pilih Mata Pelajaran",
                    hint: "Materi untuk mata pelajaran...",
                    icon: Icons.book_outlined,
                    items: ["Matematika", "Fisika", "Biologi"], // Data dummy
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- BAGIAN 3: LAMPIRAN FILE ---
            _buildSectionCard(
              title: "3. Lampirkan File",
              child: Column(
                children: [
                  _buildFilePickerBox(
                    onTap: () {
                      // Kosongkan untuk diisi nanti
                      print("Pilih file ditekan!");
                    },
                  ),
                  const SizedBox(height: 16),
                  // Contoh tampilan file yang sudah dipilih (dummy)
                  _buildFileListItem(
                    fileName: "Materi Bab 1 - Aljabar.pdf",
                    fileSize: _formatBytes(1234 * 1024, 2),
                    onDelete: () {},
                  ),
                  _buildFileListItem(
                    fileName: "Presentasi Gravitasi Newton.pptx",
                    fileSize: _formatBytes(5678 * 1024, 2),
                    onDelete: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // --- BAGIAN 4: TOMBOL AKSI UPLOAD ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Kosongkan untuk diisi nanti
                  print("Upload Materi ditekan!");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text(
                  "UPLOAD MATERI",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET-WIDGET HELPER
  // Semua widget ini bersifat stateless dan tidak bergantung pada controller

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kPrimaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kPrimaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFilePickerBox({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: DottedBorder(
        // color: kSecondaryBlue,
        // dashStrokeWidth: 2,
        // dashPattern: const [8, 4],
        // borderRadius: BorderRadius.circular(12),
        // borderType: BorderType.RRect, // Removed due to error
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: kSecondaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 48, color: kPrimaryBlue),
              const SizedBox(height: 12),
              const Text(
                "Ketuk untuk Pilih File",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryBlue),
              ),
              const SizedBox(height: 4),
              Text(
                "PDF, DOC, PPT, JPG, MP4, dll.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileListItem({
    required String fileName,
    required String fileSize,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_rounded, color: kSecondaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                Text(fileSize, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
            onPressed: onDelete,
            tooltip: "Hapus file",
          ),
        ],
      ),
    );
  }

  // Helper untuk format ukuran file
  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}



// // lib/app/modules/home/pages/marketplace_page.dart

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'dart:math';

// import 'package:intl/intl.dart';

// class MarketplacePage extends StatelessWidget {
//   MarketplacePage({super.key});

//   final List<Widget> _carouselItems = [
//     "assets/pictures/1.webp", "assets/pictures/2.webp", "assets/pictures/3.webp", "assets/pictures/4.webp", "assets/pictures/5.webp", "assets/pictures/6.webp",
//   ].map((imgPath) => _CarouselImageSlider(imagePath: imgPath, onTap: () {})).toList();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Marketplace"),
//         backgroundColor: Colors.white,
//         elevation: 1,
//       ),
//       body: Column(
//         children: [
//           CarouselSlider(
//             items: _carouselItems,
//             options: CarouselOptions(
//               height: 180, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.9
//             ),
//           ),
//           const _CategoryRow(),
//           const _SectionHeader(),
//           Expanded( // Kunci performa untuk GridView
//             child: GridView.builder(
//               padding: const EdgeInsets.all(12),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 mainAxisSpacing: 12,
//                 crossAxisSpacing: 12,
//                 childAspectRatio: 0.8,
//               ),
//               itemCount: 50,
//               itemBuilder: (context, index) => _ProductCard(index: index),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CategoryRow extends StatelessWidget {
//   const _CategoryRow();
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 16.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _MarketCategory(title: 'Makanan', icon: Icons.fastfood, onTap: () {}),
//           _MarketCategory(title: 'Properti', icon: Icons.warehouse_outlined, onTap: () {}),
//           _MarketCategory(title: 'Elektronik', icon: Icons.tv, onTap: () {}),
//           _MarketCategory(title: 'Lainnya', icon: Icons.category, onTap: () {}),
//         ],
//       ),
//     );
//   }
// }

// class _MarketCategory extends StatelessWidget {
//   final String title;
//   final IconData icon;
//   final VoidCallback onTap;

//   const _MarketCategory({required this.title, required this.icon, required this.onTap});
  
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(10),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: Colors.green.withOpacity(0.1),
//             child: Icon(icon, color: Colors.green.shade700, size: 28),
//           ),
//           const SizedBox(height: 6),
//           Text(title, style: const TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//   }
// }

// class _SectionHeader extends StatelessWidget {
//   const _SectionHeader();
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text("Produk Terlaris", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
//           TextButton(onPressed: () {}, child: const Text("Lihat Semua")),
//         ],
//       ),
//     );
//   }
// }

// class _ProductCard extends StatelessWidget {
//   final int index;
//   const _ProductCard({required this.index});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       clipBehavior: Clip.antiAlias,
//       child: InkWell(
//         onTap: () {},
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Expanded(
//               child: CachedNetworkImage(
//                 imageUrl: "https://picsum.photos/id/${index + 256}/300/300",
//                 fit: BoxFit.cover,
//                 placeholder: (c, u) => Container(color: Colors.grey.shade200),
//                 errorWidget: (c, u, e) => const Icon(Icons.broken_image, color: Colors.grey),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("Produk ke ${index + 1}", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis,),
//                   const SizedBox(height: 4),
//                   Text("Rp ${NumberFormat.decimalPattern('id').format(Random().nextInt(100000))}", style: theme.textTheme.bodyMedium?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _CarouselImageSlider extends StatelessWidget {
//   final String imagePath;
//   final VoidCallback onTap;
//   const _CarouselImageSlider({required this.imagePath, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.all(5.0),
//         child: ClipRRect(
//           borderRadius: const BorderRadius.all(Radius.circular(10.0)),
//           child: Image.asset(imagePath, fit: BoxFit.cover, width: 1000.0),
//         ),
//       ),
//     );
//   }
// }