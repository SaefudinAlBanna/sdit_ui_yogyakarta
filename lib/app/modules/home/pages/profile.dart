import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class ProfilePage extends GetView<HomeController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: controller.getProfileBaru(),
      builder: (context, snapsprofile) {
        if (snapsprofile.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapsprofile.data?.data == null) {
          return Center(child: Text('Data tidak ditemukan'));
        }
        if (snapsprofile.hasData) {
          Map<String, dynamic> data = snapsprofile.data!.data()!;
          // Format tanggal lahir
          String formattedDateTglLahir = '';
          if (data['tglLahir'] != null) {
            DateTime? tglLahir;
            if (data['tglLahir'] is Timestamp) {
              tglLahir = (data['tglLahir'] as Timestamp).toDate();
            } else if (data['tglLahir'] is String) {
              tglLahir = DateTime.tryParse(data['tglLahir']);
            }
            if (tglLahir != null) {
              formattedDateTglLahir = "${tglLahir.day.toString().padLeft(2, '0')}-${tglLahir.month.toString().padLeft(2, '0')}-${tglLahir.year}";
            }
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(
                "Profile",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.indigo[400],
              actions: [
                IconButton(
                  onPressed: () {
                    Get.defaultDialog(
                      onCancel: Get.back,
                      title: 'Peringatan',
                      middleText: 'Apakah anda yakin akan logout?',
                      onConfirm: () => controller.signOut(),
                    );
                  },
                  icon: Icon(
                    Icons.power_settings_new_outlined,
                    size: 25,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                ClipPath(
                  clipper: ClassClipPathTop(),
                  child: Container(
                    height: 250,
                    width: Get.width,
                    color: Colors.indigo[400],
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Column(
                            children: [
                              Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      "https://picsum.photos/200",
                                    ),
                                    // "https://photos.google.com/photo/AF1QipO0EuuqmPsza1Ljrdy6roeFI9BbjQ043BrYtxpc"),
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                data['alias'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                data['role'].toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  // fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 50),
                          // Container(height: 7, color: Colors.grey[400]),
                        ],
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(horizontal: 25),
                          children: [
                            SizedBox(height: 20),
                            Text("Menu", style: TextStyle(fontSize: 20)),
                            SizedBox(height: 5),
                            Card(
                              color: Colors.grey[200],
                              child: Container(
                                alignment: Alignment.topLeft,
                                padding: EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    ...ListTile.divideTiles(
                                      color: Colors.grey,
                                      tiles: [
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          leading: Icon(Icons.email_outlined),
                                          title: Text("email"),
                                          subtitle: Text(data['email']),
                                        ),
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          leading: Icon(Icons.local_hospital),
                                          title: Text("Tempat, Tgl Lahir"),
                                          subtitle: Text("${data['tempatLahir']}, - $formattedDateTglLahir",)
                                        ),
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          leading: Icon(Icons.male_outlined),
                                          title: Text("Jenis Kelamin"),
                                          subtitle: Text(
                                            data['jeniskelamin']
                                          ),
                                        ),
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          leading: Icon(
                                            Icons.ac_unit_outlined,
                                          ),
                                          title: Text("Jumlah Hafalan"),
                                          subtitle: Text(data['jumlahhafalan']),
                                        ),
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          leading: Icon(Icons.my_location),
                                          title: Text("Alamat"),
                                          subtitle: Text(data['alamat']),
                                        ),
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          leading: Icon(
                                            Icons.phone_android_outlined,
                                          ),
                                          title: Text("No Hp"),
                                          subtitle: Text(
                                            data['nohp'],
                                          ),
                                        ),
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          leading: Icon(Icons.menu_book_outlined),
                                          title: Text("bersertifikat"),
                                          subtitle: Text(
                                            data['bersertifikat'],
                                          ),
                                        ),
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          leading: Icon(Icons.yard_outlined),
                                          title: Text("No. Sertifikat"),
                                          subtitle: Text(
                                            data['nosertifiat'],
                                          ),
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
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: Text("Terjadi kesalahan, silahkan coba login ulang"),
          );
        }
      },
    );
  }
}

class ClassClipPathTop extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) => false;
}
