// lib/app/modules/home/pages/profile_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import 'package:intl/intl.dart';

class ProfilePage extends GetView<HomeController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Profil Saya"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Get.defaultDialog(
              title: "Logout",
              middleText: "Apakah Anda yakin ingin keluar?",
              textConfirm: "Ya",
              textCancel: "Tidak",
              onConfirm: controller.signOut, // Asumsi ada fungsi signOut
            ),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: controller.userStream(), // Menggunakan stream yang sudah diperbaiki
        builder: (context, snapProfile) {
          if (snapProfile.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapProfile.hasData || snapProfile.data?.data() == null) {
            return const Center(child: Text('Data pengguna tidak ditemukan.'));
          }
          final data = snapProfile.data!.data()!;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: [
              _ProfileHeaderCard(data: data),
              const SizedBox(height: 16),
              _ProfileDetailsCard(data: data),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeaderCard extends GetView<HomeController> { // <-- Ubah menjadi GetView<HomeController>
  final Map<String, dynamic> data;
  const _ProfileHeaderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // --- LOGIKA BARU UNTUK MENAMPILKAN GAMBAR ---
    final String? imageUrl = data['profileImageUrl'];
    final ImageProvider imageProvider;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Jika ada URL dari Firestore, gunakan NetworkImage
      imageProvider = NetworkImage(imageUrl);
    } else {
      // Jika tidak ada, gunakan default (misal, dari ui-avatars atau aset lokal)
      imageProvider = NetworkImage("https://ui-avatars.com/api/?name=${data['alias'] ?? 'User'}&background=random&color=fff");
    }
    // --- AKHIR LOGIKA BARU ---

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: BorderRadius.circular(15),
        image: const DecorationImage(
          image: AssetImage("assets/png/latar2.png"), // Pastikan path aset ini benar
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: imageProvider, // <-- Gunakan imageProvider
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.edit, size: 22, color: Colors.green.shade800),
                    // Panggil fungsi upload dari controller
                    onPressed: controller.pickAndUploadProfilePicture,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(data['alias'] ?? 'Nama Pengguna', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(data['role'] ?? 'Role', style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProfileDetailsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    String formattedDateTglLahir = 'N/A';
    if (data['tglLahir'] is Timestamp) {
      final tglLahir = (data['tglLahir'] as Timestamp).toDate();
      formattedDateTglLahir = DateFormat('dd MMMM yyyy', 'id_ID').format(tglLahir);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _buildInfoTile(icon: Icons.email_outlined, title: "Email", subtitle: data['email'] ?? '-'),
            _buildInfoTile(icon: Icons.cake_outlined, title: "Tempat, Tgl Lahir", subtitle: "${data['tempatLahir'] ?? '-'}, $formattedDateTglLahir"),
            _buildInfoTile(icon: Icons.person_outline, title: "Jenis Kelamin", subtitle: data['jeniskelamin'] ?? '-'),
            _buildInfoTile(icon: Icons.home_outlined, title: "Alamat", subtitle: data['alamat'] ?? '-'),
            _buildInfoTile(icon: Icons.phone_android_outlined, title: "No HP", subtitle: data['nohp'] ?? '-'),
            _buildInfoTile(icon: Icons.card_membership_outlined, title: "No. Sertifikat", subtitle: data['nosertifikat'] ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Colors.green.shade700),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
    );
  }
}
