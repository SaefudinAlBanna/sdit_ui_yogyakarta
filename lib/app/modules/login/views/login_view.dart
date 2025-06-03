import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/login_controller.dart';

// Warna yang digunakan
const Color orangeColors = Color(0xFFE52027);
const Color orangeLightColors = Color(0xFF831217);

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: <Widget>[
            const HeaderContainer(),
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.only(left: 20, right: 20, top: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    _textInput(
                      controller: controller.emailC,
                      hint: "Enter your Email",
                      icon: Icons.email,
                      obsecure: false,
                      suffix: null,
                    ),
                   Obx(
                      () => _textInput(
                        controller: controller.passC,
                        hint: "Password",
                        icon: Icons.vpn_key,
                        obsecure: controller.isLogin.value,
                        suffix: InkWell(
                          child: Icon(controller.isLogin.value ? Icons.visibility_outlined : 
                          Icons.visibility_off_outlined, ),
                          onTap: () {
                            controller.isLogin.value =
                                !controller.isLogin.value;
                          },
                        ),
                      ),
                    ),
                    Obx(
                      () => ElevatedButton(
                        onPressed: () async {
                          if (controller.isLoading.isFalse) {
                            await controller.login();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          controller.isLoading.isFalse ? "Login" : "LOADING..."
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Get.toNamed(Routes.FORGOT_PASSWORD),
                        child: const Text("Forgot Password?"),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obsecure,
    Widget? suffix,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.only(left: 10),
      child: TextFormField(
        autocorrect: false,
        obscureText: obsecure,
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffix: suffix,
        ),
      ),
    );
  }
}

class HeaderContainer extends StatelessWidget {
  const HeaderContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.indigo.shade300],
          end: Alignment.bottomCenter,
          begin: Alignment.topCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(100),
        ),
      ),
      child: const Stack(
        children: <Widget>[
          Positioned(
            bottom: 20,
            right: 20,
            child: Text(
              "Login",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
