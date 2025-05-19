import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class ProfilePage extends GetView<HomeController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                title: 'Fitur',
                middleText: 'Fitur dalam pengembangan',
              );
            },
            icon: Icon(Icons.menu_book_outlined, size: 25, color: Colors.white),
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
            // child: FutureBuilder<
            // DocumentSnapshot<Map<String, dynamic>>>(
            // future: controller.getDataDocKelasSiswa(),
            // builder: (context, snapshotKelas) {
            // if (snapshotKelas.connectionState ==
            //   ConnectionState.waiting) {
            //  return Center(child: CircularProgressIndicator());
            // }
            // if (snapshotKelas.hasData) {
            //   Map<String, dynamic>? dataKelas =
            //       snapshotKelas.data!.data();
            //   return Column(
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
                              image: NetworkImage("https://picsum.photos/200"),
                              // "https://photos.google.com/photo/AF1QipO0EuuqmPsza1Ljrdy6roeFI9BbjQ043BrYtxpc"),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Namanya",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Kelasnya",
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
                                    leading: Icon(Icons.key_outlined),
                                    title: Text("NIP"),
                                    subtitle: Text("datasiswa['nisn']"),
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Icon(Icons.local_hospital),
                                    title: Text("Tempat, Tgl Lahir"),
                                    // subtitle: Text("${datasiswa['tempatLahir']}, - $formattedDateTglLahir",
                                    subtitle: Text(
                                      "{datasiswa['tempatLahir']}, - formattedDateTglLahir",
                                    ),
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Icon(Icons.male_outlined),
                                    title: Text("Jenis Kelamin"),
                                    subtitle: Text("datasiswa['jenisKelamin],"),
                                  ),
                                  const ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Icon(Icons.bloodtype_rounded),
                                    title: Text("Gol. Darah"),
                                    subtitle: Text("-"),
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Icon(Icons.my_location),
                                    title: Text("Alamat"),
                                    subtitle: Text("datasiswa['alamat']"),
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Icon(Icons.phone_android_outlined),
                                    title: Text("No Hp Orang tua"),
                                    subtitle: Text("datasiswa['noHpOrangTua']"),
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Icon(Icons.man_3_outlined),
                                    title: Text("Nama Ayah"),
                                    subtitle: Text("datasiswa['namaAyah']"),
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    leading: Icon(Icons.woman_outlined),
                                    title: Text("Nama Ibu"),
                                    subtitle: Text("datasiswa['namaIbu']"),
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