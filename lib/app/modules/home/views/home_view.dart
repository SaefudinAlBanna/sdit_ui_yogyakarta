// lib/app/modules/home/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

// --- TAMBAHAN PENTING: IMPORT SEMUA HALAMAN YANG AKAN DIGUNAKAN ---
import '../pages/home.dart';
import '../pages/marketplace.dart';
import '../pages/profile.dart';
// -----------------------------------------------------------------

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  // --- FUNGSI BARU UNTUK MEMBUAT DAFTAR LAYAR (WIDGETS) ---
  // Ini adalah praktik terbaik: UI didefinisikan di dalam kelas View.
  List<Widget> _buildScreens() {
    return [
      HomePage(),
      MarketplacePage(),
      ProfilePage(),
    ];
  }
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: PersistentTabView(
        context,
        controller: controller.tabController,
        // --- PERUBAHAN UTAMA DI SINI ---
        // Kita tidak lagi memanggil controller.navBarScreens,
        // tetapi memanggil fungsi _buildScreens() yang ada di kelas ini.
        screens: _buildScreens(),
        // ---------------------------------
        items: _navBarItems(),
        navBarStyle: NavBarStyle.style6,
        backgroundColor: Colors.white,
        decoration: NavBarDecoration(
          borderRadius: BorderRadius.circular(10.0),
          colorBehindNavBar: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        handleAndroidBackButtonPress: true,
        resizeToAvoidBottomInset: true,
        stateManagement: true,
        hideNavigationBarWhenKeyboardAppears: true,
        popBehaviorOnSelectedNavBarItemPress: PopBehavior.once,
        animationSettings: const NavBarAnimationSettings(
          navBarItemAnimation: ItemAnimationSettings(
            duration: Duration(milliseconds: 400),
            curve: Curves.ease,
          ),
          screenTransitionAnimation: ScreenTransitionAnimationSettings(
            animateTabTransition: true,
            duration: Duration(milliseconds: 300),
            screenTransitionAnimationType: ScreenTransitionAnimationType.fadeIn,
          ),
          onNavBarHideAnimation: OnHideAnimationSettings(
            duration: Duration(milliseconds: 100),
            curve: Curves.bounceInOut,
          ),
        ),
      ),
    );
  }

  List<PersistentBottomNavBarItem> _navBarItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_rounded), // Sedikit penyesuaian ikon
        title: "Home",
        activeColorPrimary: Colors.green.shade700,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.shopping_cart_outlined),
        title: "R.Belajar",
        activeColorPrimary: Colors.green.shade700,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_outline_rounded),
        title: "Profile",
        activeColorPrimary: Colors.green.shade700,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  void _showExitDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Keluar Aplikasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Tidak')),
          TextButton(
            onPressed: () => SystemNavigator.pop(), // Aksi yang lebih langsung
            child: Text('Ya', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}