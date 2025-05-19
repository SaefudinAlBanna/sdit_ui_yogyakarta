import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class MarketplacePage extends GetView<HomeController> {
  MarketplacePage({super.key});

  final myItem = [
    ImageSlider(image: "assets/pictures/sekolah.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/1.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/2.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/3.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/4.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/5.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/6.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/7.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/8.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/9.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/10.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/11.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/12.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/13.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/14.jpg", ontap: () => Get.snackbar("Informasi", ""),),
    ImageSlider(image: "assets/pictures/15.jpg", ontap: () => Get.snackbar("Informasi", ""),),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 200,
                // viewportFraction: 1.0,
                aspectRatio: 2 / 1,
                // autoPlay: true,
                autoPlayInterval: Duration(seconds: 5),
                // autoPlayAnimationDuration: Duration(milliseconds: 800),
                enlargeCenterPage: true,
              ),
              items: myItem,
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MarketCategory(
                      title: 'Makanan Sehat',
                      icon: Icon(Icons.fastfood_sharp),
                      onTap: () {
                        Get.snackbar("Category", "Makanan Sehat");
                      },
                    ),
                    MarketCategory(
                      title: 'Rumah Property',
                      icon: Icon(Icons.warehouse_outlined),
                      onTap: () {
                        Get.snackbar("Category", "Rumah Property");
                      },
                    ),
                    MarketCategory(
                      title: 'Elektronik Gedget',
                      icon: Icon(Icons.tv),
                      onTap: () {
                        Get.snackbar("Category", "Elektronik Gedget");
                      },
                    ),
                    MarketCategory(
                      title: 'Kendaraan Halal',
                      icon: Icon(Icons.car_repair),
                      onTap: () {
                        Get.snackbar("Category", "Kendaraan Halal");
                      },
                    ),
                  ],
                ),
              ],
            ),
            // SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("DAFTAR PRODUK ANDALAN"),
                  TextButton(
                    onPressed: () {
                      Get.snackbar("produk", "semua produk");
                    },
                    child: Text("semua"),
                  ),
                ],
              ),
            ),
            // Divider(height: 2),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  crossAxisCount: 3),
                  itemCount: 50, 
                  itemBuilder: (context, index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.snackbar("produk", "produk ${index+1}");
                          },
                          child: Container(
                            height: 85,
                            width: 150,
                            decoration: BoxDecoration(
                              // color: Color.fromARGB(255, Random().nextInt(255), Random().nextInt(255), Random().nextInt(255)),
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(image: NetworkImage("https://picsum.photos/id/${index + 256}/500/500"), fit: BoxFit.cover)
                            ),
                          ),
                        ),
                        Text("Produk ke ${index+1}"),
                        Text("Rp. ${Random().nextInt(10000)}")
                      ],
                    );
                  },))
          ],
        ),
      ),
    );
  }
}

class MarketCategory extends StatelessWidget {
  const MarketCategory({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final Icon icon;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  Icon(icon.icon, size: 30),
                ],
              ),
            ),
          ),
          SizedBox(height: 5),
          SizedBox(
            width: 60,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class ImageSlider extends StatelessWidget {
  const ImageSlider({super.key, required this.image, required this.ontap});

  final String image;
  final Function() ontap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        width: Get.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          image: DecorationImage(image: AssetImage(image), fit: BoxFit.fill),
        ),
      ),
    );
  }
}
