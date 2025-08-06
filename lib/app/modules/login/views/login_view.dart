import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui'; // Diperlukan untuk ImageFilter
import '../../../routes/app_pages.dart';
import '../controllers/login_controller.dart';

// --- PALET WARNA BARU YANG SEGAR & FUTURISTIK ---
const Color kPrimaryColor = Color(0xFF6A1B9A); // Ungu Tua
const Color kPrimaryLightColor = Color(0xFFC158DC); // Ungu Muda
const Color kBackgroundColor = Color(0xFFF5F5F5); // Abu-abu sangat terang
const Color kTextColor = Color(0xFF212121); // Hitam lembut
const Color kAccentColor = Color(0xFF00E676); // Hijau Neon untuk aksen

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Get.width dan Get.height untuk responsivitas
    final screenHeight = Get.height;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // --- HEADER DENGAN GRADASI DAN BLOB ---
            SleekHeader(),
            
            // --- FORM CONTAINER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // --- WELCOME TEXT ---
                  const Text(
                    "Assalamu'alaykum,",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  Text(
                    "V. 1.0.0",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),

                  // --- INPUT FIELDS ---
                  _buildTextField(
                    controller: controller.emailC,
                    hint: "Email Address",
                    icon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => _buildTextField(
                      controller: controller.passC,
                      hint: "Password",
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: controller.isLogin.value,
                      onToggleVisibility: () {
                        controller.isLogin.value = !controller.isLogin.value;
                      },
                    ),
                  ),

                  // --- FORGOT PASSWORD ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.toNamed(Routes.FORGOT_PASSWORD),
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  // --- LOGIN BUTTON ---
                  Obx(
                    () => ElevatedButton(
                      onPressed: controller.isLoading.isFalse ? controller.login : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        shadowColor: kPrimaryColor.withOpacity(0.4),
                      ),
                      child: controller.isLoading.isFalse
                          ? const Text(
                              "LOGIN",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            )
                          : const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                    ),
                  ),
                  
                  // --- SIGN UP OPTION (OPSIONAL) ---
                  SizedBox(height: screenHeight * 0.03),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade700)),
                  //     GestureDetector(
                  //       onTap: () {
                  //         // Arahkan ke halaman registrasi jika ada
                  //         // Get.toNamed(Routes.REGISTER); 
                  //       },
                  //       child: const Text(
                  //         "Sign Up",
                  //         style: TextStyle(
                  //           color: kPrimaryColor,
                  //           fontWeight: FontWeight.bold,
                  //           decoration: TextDecoration.underline,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BARU UNTUK TEXTFIELD YANG LEBIH MODERN ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: kPrimaryColor.withOpacity(0.7)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
      ),
    );
  }
}

// --- HEADER BARU YANG LEBIH DINAMIS ---
class SleekHeader extends StatelessWidget {
  const SleekHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.35,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryLightColor, kPrimaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(80),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Efek 'blob' di background untuk nuansa organik
          Positioned(
            top: -50,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Logo dan Teks
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pastikan path logo benar
                SizedBox(
                  height: 80,
                  width: 80,
                  child: Image.asset("assets/png/logo.png",
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.school, color: Colors.white, size: 80),
                  )
                ),
                const SizedBox(height: 10),
                const Text(
                  // "SI-HALAQOH",
                  "SDIT Ukhuwah Islamiyyah",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
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



// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'dart:ui'; // Diperlukan untuk ImageFilter.blur
// import '../../../routes/app_pages.dart';
// import '../controllers/login_controller.dart';

// class LoginView extends GetView<LoginController> {
//   const LoginView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Seluruh body dibungkus dengan Stack untuk menumpuk background dan konten
//       body: Stack(
//         children: [
//           // --- 1. BACKGROUND IMAGE ---
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 // GANTI DENGAN PATH GAMBAR ANDA
//                 image: AssetImage("assets/images/login_bg.jpg"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),

//           // --- 2. KONTEN UTAMA DENGAN EFEK GLASSMORPHISM ---
//           Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Logo
//                   SizedBox(
//                     height: 90,
//                     width: 90,
//                     child: Image.asset("assets/png/logo.png",
//                       errorBuilder: (context, error, stackTrace) =>
//                           const Icon(Icons.school, color: Colors.white, size: 90),
//                     )
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     "Sign In",
//                     style: TextStyle(
//                       fontSize: 36,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       shadows: [Shadow(blurRadius: 10, color: Colors.black38)],
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // --- CONTAINER KACA ---
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(20),
//                     child: BackdropFilter(
//                       filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                       child: Container(
//                         padding: const EdgeInsets.all(24),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.15),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(
//                             color: Colors.white.withOpacity(0.2),
//                             width: 1.5,
//                           ),
//                         ),
//                         child: Column(
//                           children: [
//                             _buildGlassTextField(
//                               controller: controller.emailC,
//                               hint: "Email",
//                               icon: Icons.person_outline,
//                             ),
//                             const SizedBox(height: 20),
//                             Obx(
//                               () => _buildGlassTextField(
//                                 controller: controller.passC,
//                                 hint: "Password",
//                                 icon: Icons.lock_outline,
//                                 isPassword: true,
//                                 obscureText: controller.isLogin.value,
//                                 onToggleVisibility: () {
//                                   controller.isLogin.value = !controller.isLogin.value;
//                                 },
//                               ),
//                             ),
//                             const SizedBox(height: 30),
//                              Obx(
//                                () => SizedBox(
//                                 width: double.infinity,
//                                 child: ElevatedButton(
//                                   onPressed: controller.isLoading.isFalse ? controller.login : null,
//                                   style: ElevatedButton.styleFrom(
//                                     padding: const EdgeInsets.symmetric(vertical: 16),
//                                     backgroundColor: Colors.white.withOpacity(0.9),
//                                     foregroundColor: Colors.black87,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                   child: controller.isLoading.isFalse
//                                     ? const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
//                                     : const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87)),
//                                 ),
//                                ),
//                              ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   // Lupa Password
//                   TextButton(
//                     onPressed: () => Get.toNamed(Routes.FORGOT_PASSWORD),
//                     child: const Text(
//                       "Forgot Password?",
//                       style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- WIDGET BARU UNTUK TEXTFIELD KACA ---
//   Widget _buildGlassTextField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     bool isPassword = false,
//     bool obscureText = false,
//     VoidCallback? onToggleVisibility,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscureText,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
//         prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
//         suffixIcon: isPassword
//             ? IconButton(
//                 icon: Icon(
//                   obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
//                   color: Colors.white.withOpacity(0.7),
//                 ),
//                 onPressed: onToggleVisibility,
//               )
//             : null,
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
//         ),
//       ),
//     );
//   }
// }


// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import '../../../routes/app_pages.dart';
// // import '../controllers/login_controller.dart';

// // // Warna yang digunakan
// // const Color orangeColors = Color(0xFFE52027);
// // const Color orangeLightColors = Color(0xFF831217);

// // class LoginView extends GetView<LoginController> {
// //   const LoginView({super.key});

// //   @override
// // Widget build(BuildContext context) {
// //   return Scaffold(
// //     body: Container(
// //       // Padding di sini tidak lagi diperlukan karena SingleChildScrollView akan menangani ruang
// //       // padding: const EdgeInsets.only(bottom: 30), 
// //       child: Column(
// //         children: <Widget>[
// //           const HeaderContainer(),
// //           Expanded(
// //             flex: 1,
// //             child: Container(
// //               margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
// //               // --- [PERBAIKAN] Bungkus Column dengan SingleChildScrollView ---
// //               child: SingleChildScrollView(
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.max,
// //                   children: <Widget>[
// //                     _textInput(
// //                       controller: controller.emailC,
// //                       hint: "Enter your Email",
// //                       icon: Icons.email,
// //                       obsecure: false,
// //                       suffix: null,
// //                     ),
// //                     Obx(
// //                       () => _textInput(
// //                         controller: controller.passC,
// //                         hint: "Password",
// //                         icon: Icons.vpn_key,
// //                         obsecure: controller.isLogin.value,
// //                         suffix: InkWell(
// //                           child: Icon(controller.isLogin.value ? Icons.visibility_outlined : 
// //                           Icons.visibility_off_outlined, ),
// //                           onTap: () {
// //                             controller.isLogin.value = !controller.isLogin.value;
// //                           },
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 20), // Sedikit tambah spasi
// //                     Obx(
// //                       () => SizedBox(
// //                         width: 150,
// //                         height: 45,
// //                         child: ElevatedButton(
// //                           onPressed: () async {
// //                             if (controller.isLoading.isFalse) {
// //                               await controller.login();
// //                             }
// //                           },
// //                           style: ElevatedButton.styleFrom(
// //                             backgroundColor: Colors.indigo[300],
// //                             foregroundColor: Colors.white,
// //                           ),
// //                           child: Text(
// //                             controller.isLoading.isFalse ? "Login" : "LOADING...", style: const TextStyle(fontSize: 17),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     Container(
// //                       margin: const EdgeInsets.only(top: 10),
// //                       alignment: Alignment.centerRight,
// //                       child: TextButton(
// //                         onPressed: () => Get.toNamed(Routes.FORGOT_PASSWORD),
// //                         child: const Text("Forgot Password?"),
// //                       ),
// //                     ),
// //                     // Spacer tidak lagi diperlukan karena SingleChildScrollView
// //                     // tidak memiliki tinggi tak terbatas. Kita bisa ganti dengan SizedBox
// //                     // jika butuh spasi di bawah.
// //                     const SizedBox(height: 20),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     ),
// //   );
// //  }

// //   Widget _textInput({
// //     required TextEditingController controller,
// //     required String hint,
// //     required IconData icon,
// //     required bool obsecure,
// //     Widget? suffix,
// //   }) {
// //     return Container(
// //       margin: const EdgeInsets.only(top: 10),
// //       decoration: const BoxDecoration(
// //         borderRadius: BorderRadius.all(Radius.circular(20)),
// //         color: Colors.white,
// //       ),
// //       padding: const EdgeInsets.only(left: 10),
// //       child: TextFormField(
// //         autocorrect: false,
// //         obscureText: obsecure,
// //         controller: controller,
// //         decoration: InputDecoration(
// //           border: InputBorder.none,
// //           hintText: hint,
// //           prefixIcon: Icon(icon),
// //           suffixIcon: suffix,
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class HeaderContainer extends StatelessWidget {
// //   const HeaderContainer({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       height: MediaQuery.of(context).size.height * 0.4,
// //       decoration: BoxDecoration(
// //         // image: DecorationImage(image: AssetImage("assets/images/profile.png")),
// //         gradient: LinearGradient(
// //           colors: [Colors.green.shade700, Colors.indigo.shade400, Colors.blue.shade400],
// //           end: Alignment.bottomCenter,
// //           begin: Alignment.topCenter,
// //         ),
// //         borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(100)),
// //       ),
// //       child: const Stack(
// //         children: <Widget>[
// //           Positioned(
// //             top: 45,
// //             left: 20,
// //             child: SizedBox(
// //               height: 65,
// //               width: 65,
// //               child: Image(image: AssetImage("assets/png/logo.png"))),
// //           ),
// //           Positioned(
// //             bottom: 20,
// //             right: 20,
// //             child: Text(
// //               "Login",
// //               style: TextStyle(color: Colors.white, fontSize: 20),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
