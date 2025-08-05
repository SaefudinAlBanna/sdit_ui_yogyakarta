import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TampilkanInfoSekolahController extends GetxController {
  
  // Gunakan Rx untuk menampung data agar reaktif
  final Rx<Map<String, dynamic>> infoData = Rx<Map<String, dynamic>>({});

  @override
  void onInit() {
    super.onInit();
    // Ambil argumen di onInit, ini praktik GetX yang baik
    if (Get.arguments != null) {
      infoData.value = Get.arguments as Map<String, dynamic>;
    }
  }

  // Getter untuk kemudahan akses di view
  String get judul => infoData.value['judulinformasi'] ?? 'Tanpa Judul';
  String get isi => infoData.value['informasisekolah'] ?? 'Konten tidak tersedia.';
  String get gambarUrl => infoData.value['imageUrl'] ?? '';
  String get penginput => infoData.value['namapenginput'] ?? 'Admin';
  String get tanggal {
    final tglString = infoData.value['tanggalinput'];
    if (tglString is String) {
      try {
        final dt = DateTime.parse(tglString);
        // Format tanggal yang lebih lengkap dan informatif
        return DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(dt);
      } catch (e) { /* fallback */ }
    }
    return 'Tanggal tidak tersedia';
  }
}