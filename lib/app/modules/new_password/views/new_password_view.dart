import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../controllers/new_password_controller.dart';

class NewPasswordView extends GetView<NewPasswordController> {
  const NewPasswordView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Password'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.offAllNamed(Routes.LOGIN),
          icon: Icon(Icons.backpack_outlined),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          TextField(
            autocorrect: false,
            controller: controller.newpassC,
            decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'New Password',
                hintText: 'Input New Password'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.changePassword();
            },
            child: Text('Change Password'),
          ),
        ],
      ),
    );
  }
}
