import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/home_controller.dart';

// import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';


const NavBarStyle _navBarStyle = NavBarStyle.style6; // You can choose any available NavBarStyle

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // body: Obx(() => controller.myWidgets.elementAt(controller.indexWidget.value),
      // ),
      // bottomNavigationBar: ConvexAppBar(
      //   style: TabStyle.react,
      //   curveSize: 90,
      //   initialActiveIndex: 0,
      //   backgroundColor: Colors.indigo[400],
      //   onTap: (index) => controller.changeIndex(index),
      //   items:[
      //     TabItem(icon: Icons.home, title: "Home"),
      //     TabItem(icon: Icons.shopping_cart_outlined, title: "Marketplace"),
      //     TabItem(icon: Icons.person_2_rounded, title: "Profile"),
      //   ] ),
      
      body: PersistentTabView(
        context,
        // controller: _controller,
        screens: controller.myWidgets,
        items: [
          PersistentBottomNavBarItem(icon: Icon(Icons.home, color: Colors.black), title: "Home",),
          PersistentBottomNavBarItem(icon: Icon(Icons.shopping_cart_outlined, color: Colors.black,), title: "Marketplace"),
          PersistentBottomNavBarItem(icon: Icon(Icons.person_2_rounded, color: Colors.black), title: "Profile"),
        ],
        handleAndroidBackButtonPress: true, // Default is true.
        resizeToAvoidBottomInset: true, // This needs to be true if you want to move up the screen on a non-scrollable screen when keyboard appears. Default is true.
        stateManagement: true, // Default is true.
        hideNavigationBarWhenKeyboardAppears: true,
        popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,
        padding: const EdgeInsets.only(top: 8),
        backgroundColor: Colors.grey.shade200,
        isVisible: true,
        animationSettings: const NavBarAnimationSettings(
            navBarItemAnimation: ItemAnimationSettings( // Navigation Bar's items animation properties.
                duration: Duration(milliseconds: 400),
                curve: Curves.ease,
            ),
            screenTransitionAnimation: ScreenTransitionAnimationSettings( // Screen transition animation on change of selected tab.
                animateTabTransition: true,
                duration: Duration(milliseconds: 200),
                screenTransitionAnimationType: ScreenTransitionAnimationType.fadeIn,
            ),
        ),
        confineToSafeArea: true,
        navBarHeight: kBottomNavigationBarHeight,
        navBarStyle: _navBarStyle, // Choose the nav bar style with this property
      ),
    );
  }
}
