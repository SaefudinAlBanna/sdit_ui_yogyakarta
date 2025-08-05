import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import 'package:intl/intl.dart';

// --- PALET WARNA BARU ---
const Color kPrimaryBlue = Color(0xFF0D47A1); // Biru Tua
const Color kSecondaryBlue = Color(0xFF42A5F5); // Biru Muda
const Color kBackgroundColor = Color(0xFFF4F7FC); // Latar belakang putih kebiruan
const Color kIconColor = Color(0xFF0D47A1);
const Color kTextColor = Color(0xFF333333);

class ProfilePage extends GetView<HomeController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // --- APPBAR DIDESAIN ULANG ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: kTextColor,
        centerTitle: true,
        title: const Text(
          "Profil Saya",
          style: TextStyle(fontWeight: FontWeight.bold, color: kTextColor),
        ),
        actions: [
          IconButton(
            tooltip: "Keluar",
            onPressed: () => Get.defaultDialog(
              title: "Logout",
              middleText: "Apakah Anda yakin ingin keluar?",
              buttonColor: kPrimaryBlue,
              confirmTextColor: Colors.white,
              textConfirm: "Ya, Keluar",
              textCancel: "Batal",
              onConfirm: controller.signOut,
            ),
            icon: const Icon(Icons.logout_rounded, color: kPrimaryBlue),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: controller.userStream(),
        builder: (context, snapProfile) {
          if (snapProfile.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
          }
          if (!snapProfile.hasData || snapProfile.data?.data() == null) {
            return const Center(child: Text('Data pengguna tidak ditemukan.'));
          }
          final data = snapProfile.data!.data()!;
          
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              // --- WIDGET HEADER BARU ---
              _ProfileHeaderCard(data: data),
              const SizedBox(height: 24),
              
              // --- KELOMPOK INFO PRIBADI ---
              _SectionTitle(title: "Info Pribadi"),
              _InfoCard(
                children: [
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    iconColor: Colors.green,
                    title: "Nama Lengkap",
                    subtitle: data['nama'] ?? 'Belum diatur',
                  ),
                  _buildDivider(),
                  _InfoTile(
                    icon: Icons.cake_outlined,
                    iconColor: Colors.orange,
                    title: "Tempat, Tgl Lahir",
                    subtitle: _formatTempatTglLahir(data),
                  ),
                  _buildDivider(),
                  _InfoTile(
                    icon: Icons.wc_outlined,
                    iconColor: Colors.blue,
                    title: "Jenis Kelamin",
                    subtitle: data['jeniskelamin'] ?? '-',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- KELOMPOK INFO KONTAK & LAINNYA ---
              _SectionTitle(title: "Kontak & Lainnya"),
              _InfoCard(
                children: [
                  _InfoTile(
                    icon: Icons.email_outlined,
                    iconColor: Colors.red,
                    title: "Email",
                    subtitle: data['email'] ?? '-',
                  ),
                  _buildDivider(),
                  _InfoTile(
                    icon: Icons.phone_android_outlined,
                    iconColor: Colors.teal,
                    title: "No. HP",
                    subtitle: data['nohp'] ?? '-',
                  ),
                   _buildDivider(),
                  _InfoTile(
                    icon: Icons.home_work_outlined,
                    iconColor: Colors.purple,
                    title: "Alamat",
                    subtitle: data['alamat'] ?? '-',
                  ),
                  if (data['nosertifikat'] != null) ...[
                    _buildDivider(),
                    _InfoTile(
                      icon: Icons.card_membership_outlined,
                      iconColor: Colors.brown,
                      title: "No. Sertifikat",
                      subtitle: data['nosertifikat'],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // --- KELOMPOK AKSI / PENGATURAN ---
              _SectionTitle(title: "Pengaturan Akun"),
              _InfoCard(
                children: [
                  // --- REKOMENDASI FUNGSI BARU ---
                  _ActionTile(
                    icon: Icons.lock_reset_rounded,
                    title: "Ubah Password",
                    onTap: () {
                      // Kosongkan untuk Anda isi
                      // Contoh: Get.toNamed(Routes.CHANGE_PASSWORD);
                    },
                  ),
                  _buildDivider(),
                  _ActionTile(
                    icon: Icons.policy_outlined,
                    title: "Kebijakan Privasi",
                    onTap: () {
                      // Kosongkan untuk Anda isi
                      // Contoh: launchUrl(Uri.parse('https://...'));
                    },
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  // Helper untuk format tanggal lahir
  String _formatTempatTglLahir(Map<String, dynamic> data) {
    String tempatLahir = data['tempatLahir'] ?? '-';
    String tglLahirFormatted = 'N/A';
    if (data['tglLahir'] is Timestamp) {
      final tglLahir = (data['tglLahir'] as Timestamp).toDate();
      tglLahirFormatted = DateFormat('dd MMMM yyyy', 'id_ID').format(tglLahir);
    }
    return "$tempatLahir, $tglLahirFormatted";
  }

  // Divider kustom
  Widget _buildDivider() => Divider(
    height: 1,
    color: Colors.grey.shade200,
    indent: 16,
    endIndent: 16,
  );
}

// --- WIDGET-WIDGET KUSTOM BARU UNTUK UI YANG LEBIH BAIK ---

class _ProfileHeaderCard extends GetView<HomeController> {
  final Map<String, dynamic> data;
  const _ProfileHeaderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = data['profileImageUrl'];
    final String displayName = data['alias'] ?? 'User';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kSecondaryBlue, kPrimaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Menggunakan CachedNetworkImage
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: kSecondaryBlue,
                  // Tampilkan placeholder saat gambar loading atau error
                  backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(imageUrl)
                      : null,
                  child: imageUrl == null || imageUrl.isEmpty
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              // Tombol Edit Foto
              GestureDetector(
                onTap: controller.pickAndUploadProfilePicture,
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.camera_alt_rounded, size: 20, color: kPrimaryBlue),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data['role'] ?? 'Role',
              style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: kTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade100,
        child: Icon(icon, color: Colors.grey.shade700, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: kTextColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }
}


// // lib/app/modules/home/pages/profile_page.dart

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/home_controller.dart';
// import 'package:intl/intl.dart';

// class ProfilePage extends GetView<HomeController> {
//   const ProfilePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         title: const Text("Profil Saya"),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             onPressed: () => Get.defaultDialog(
//               title: "Logout",
//               middleText: "Apakah Anda yakin ingin keluar?",
//               textConfirm: "Ya",
//               textCancel: "Tidak",
//               onConfirm: controller.signOut, // Asumsi ada fungsi signOut
//             ),
//             icon: const Icon(Icons.logout),
//           ),
//         ],
//       ),
//       body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//         stream: controller.userStream(), // Menggunakan stream yang sudah diperbaiki
//         builder: (context, snapProfile) {
//           if (snapProfile.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!snapProfile.hasData || snapProfile.data?.data() == null) {
//             return const Center(child: Text('Data pengguna tidak ditemukan.'));
//           }
//           final data = snapProfile.data!.data()!;
//           return ListView(
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             children: [
//               _ProfileHeaderCard(data: data),
//               const SizedBox(height: 16),
//               _ProfileDetailsCard(data: data),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// class _ProfileHeaderCard extends GetView<HomeController> { // <-- Ubah menjadi GetView<HomeController>
//   final Map<String, dynamic> data;
//   const _ProfileHeaderCard({required this.data});

//   @override
//   Widget build(BuildContext context) {
//     // --- LOGIKA BARU UNTUK MENAMPILKAN GAMBAR ---
//     final String? imageUrl = data['profileImageUrl'];
//     final ImageProvider imageProvider;

//     if (imageUrl != null && imageUrl.isNotEmpty) {
//       // Jika ada URL dari Firestore, gunakan NetworkImage
//       imageProvider = NetworkImage(imageUrl);
//     } else {
//       // Jika tidak ada, gunakan default (misal, dari ui-avatars atau aset lokal)
//       imageProvider = NetworkImage("https://ui-avatars.com/api/?name=${data['alias'] ?? 'User'}&background=random&color=fff");
//     }
//     // --- AKHIR LOGIKA BARU ---

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 24.0),
//       margin: const EdgeInsets.symmetric(horizontal: 16.0),
//       decoration: BoxDecoration(
//         // color: Colors.green.shade700,
//         gradient: LinearGradient(
//                   colors: [Colors.blue.shade900.withOpacity(0.8), Colors.transparent],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                 ),
//         borderRadius: BorderRadius.circular(15),
//         image: const DecorationImage(
//           // image: AssetImage("assets/png/latar2.png"), // Pastikan path aset ini benar
//           image: AssetImage("assets/pictures/sekolah.jpg"), // Pastikan path aset ini benar
//           fit: BoxFit.cover,
//           opacity: 0.7,
//         ),
//       ),
//       child: Column(
//         children: [
//           Stack(
//             children: [
//               CircleAvatar(
//                 radius: 52,
//                 backgroundColor: Colors.white,
//                 child: CircleAvatar(
//                   radius: 50,
//                   backgroundImage: imageProvider, // <-- Gunakan imageProvider
//                 ),
//               ),
//               Positioned(
//                 bottom: 0,
//                 right: 0,
//                 child: CircleAvatar(
//                   radius: 20,
//                   backgroundColor: Colors.white,
//                   child: IconButton(
//                     icon: Icon(Icons.edit, size: 22, color: Colors.green.shade800),
//                     // Panggil fungsi upload dari controller
//                     onPressed: controller.pickAndUploadProfilePicture,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(data['alias'] ?? 'Nama Pengguna', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
//           const SizedBox(height: 4),
//           Text(data['role'] ?? 'Role', style: const TextStyle(fontSize: 14, color: Colors.white70)),
//         ],
//       ),
//     );
//   }
// }

// class _ProfileDetailsCard extends StatelessWidget {
//   final Map<String, dynamic> data;
//   const _ProfileDetailsCard({required this.data});

//   @override
//   Widget build(BuildContext context) {
//     String formattedDateTglLahir = 'N/A';
//     if (data['tglLahir'] is Timestamp) {
//       final tglLahir = (data['tglLahir'] as Timestamp).toDate();
//       formattedDateTglLahir = DateFormat('dd MMMM yyyy', 'id_ID').format(tglLahir);
//     }

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Column(
//           children: [
//             _buildInfoTile(icon: Icons.email_outlined, title: "Email", subtitle: data['email'] ?? '-'),
//             _buildInfoTile(icon: Icons.cake_outlined, title: "Tempat, Tgl Lahir", subtitle: "${data['tempatLahir'] ?? '-'}, $formattedDateTglLahir"),
//             _buildInfoTile(icon: Icons.person_outline, title: "Jenis Kelamin", subtitle: data['jeniskelamin'] ?? '-'),
//             _buildInfoTile(icon: Icons.home_outlined, title: "Alamat", subtitle: data['alamat'] ?? '-'),
//             _buildInfoTile(icon: Icons.phone_android_outlined, title: "No HP", subtitle: data['nohp'] ?? '-'),
//             _buildInfoTile(icon: Icons.card_membership_outlined, title: "No. Sertifikat", subtitle: data['nosertifikat'] ?? '-'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.green.shade700),
//       title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
//       subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
//     );
//   }
// }
