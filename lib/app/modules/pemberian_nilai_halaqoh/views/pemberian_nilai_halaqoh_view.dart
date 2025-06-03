// ========== KODE BARU =====================

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Pastikan 'intl/date_symbol_data_local.dart' juga diimpor jika menggunakan format lokal
import 'package:intl/date_symbol_data_local.dart';


import '../controllers/pemberian_nilai_halaqoh_controller.dart';

class PemberianNilaiHalaqohView extends StatefulWidget { // Ubah ke StatefulWidget
  PemberianNilaiHalaqohView({super.key});

  @override
  State<PemberianNilaiHalaqohView> createState() => _PemberianNilaiHalaqohViewState();
}

class _PemberianNilaiHalaqohViewState extends State<PemberianNilaiHalaqohView> { // Buat State
  // Akses controller melalui Get.find() atau Get.put() di initState jika binding tidak otomatis
  late final PemberianNilaiHalaqohController controller;
  // final Map<String, dynamic> dataxx = Get.arguments as Map<String, dynamic>? ?? {};
  // Akan diambil dari controller._dataArgs
  Map<String, dynamic> dataxx = {};


  @override
  void initState() {
    super.initState();
    // Inisialisasi intl lokal jika perlu
    initializeDateFormatting('id_ID', null);
    // Dapatkan instance controller. Pastikan sudah di-inject oleh GetX
    // Jika menggunakan GetView, controller sudah otomatis tersedia.
    // Namun, karena kita butuh dataArgs dari controller, lebih aman akses setelah onInit controller.
    // Untuk sementara, kita akan asumsikan controller sudah siap.
    controller = Get.find<PemberianNilaiHalaqohController>();
    // Ambil dataxx dari controller setelah onInit-nya selesai
    // Ini bisa jadi race condition jika controller.onInit belum selesai
    // Lebih baik jika _dataArgs di controller adalah RxMap atau di-pass ke view saat konstruksi
    // Untuk saat ini, kita ambil langsung, tapi waspadai potensinya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Pastikan widget masih terpasang
        setState(() {
          dataxx = controller.reactive // Jika _dataArgs adalah RxMap
              ? (controller.getProperty('_dataArgs') as RxMap<String,dynamic>).value // Contoh jika RxMap
              : controller.getProperty('_dataArgs'); // Contoh jika map biasa
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(context, theme),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildHeaderSection(theme),
              const SizedBox(height: 12),
              Divider(thickness: 1, color: theme.dividerColor.withOpacity(0.5)),
              const SizedBox(height: 16),
              _buildStudentAndTeacherInfo(context, theme, controller.getProperty('_dataArgs') ?? {}), // Akses dataArgs dari controller
              const SizedBox(height: 20),
              _buildDateSection(theme),
              const SizedBox(height: 20),
              _buildHafalanSection(context, theme, controller),
              const SizedBox(height: 20),
              _buildUmmiAlquranSection(context, theme, controller),
              const SizedBox(height: 20),
              _buildKeteranganSection(context, theme, controller),
              const SizedBox(height: 30),
              _buildSimpanButton(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      title: const Text('Input Nilai Halaqoh'),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 2,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w600
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "KARTU PRESTASI PEMBELAJARAN ALQUR'AN METODE UMMI",
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          "SD IT UKHUWAH ISLAMIYYAH",
          style: theme.textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

 Widget _buildStudentAndTeacherInfo(BuildContext context, ThemeData theme, Map<String, dynamic> studentData) {
    if (studentData.isEmpty) { // Handle jika data belum siap
      return const Center(child: Text("Memuat data siswa..."));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth > 600;
        final Widget studentInfoCard = _buildInfoCard(
          theme: theme,
          title: "Informasi Siswa",
          icon: Icons.person_pin_circle_outlined,
          children: [
            _buildInfoRow(theme, 'Nama Siswa', studentData['namasiswa'] ?? '-'),
            _buildInfoRow(theme, 'No Induk', studentData['nisn'] ?? '-'),
            _buildInfoRow(theme, 'Kelas', studentData['kelas'] ?? '-'),
          ],
        );

        final Widget teacherInfoCard = _buildInfoCard(
          theme: theme,
          title: "Informasi Halaqoh",
          icon: Icons.school_outlined,
          children: [
             Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('UMI Terakhir:', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: FutureBuilder<String?>(
                      future: controller.ambilDataUmi(),
                      builder: (context, snapumi) {
                        if (snapumi.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.0));
                        }
                        if (snapumi.hasError || !snapumi.hasData || snapumi.data == null || snapumi.data!.isEmpty) {
                          return Text(snapumi.data ?? "Belum diinput", style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: snapumi.hasError ? theme.colorScheme.error : null));
                        }
                        return Text(snapumi.data!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600));
                      },
                    ),
                  ),
                ],
              ),
            _buildInfoRow(theme, 'Pengampu', studentData['namapengampu'] ?? '-'),
            _buildInfoRow(theme, 'Tempat', studentData['tempatmengaji'] ?? '-'),
          ],
        );

        if (isWideScreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: studentInfoCard),
              const SizedBox(width: 16),
              Expanded(child: teacherInfoCard),
            ],
          );
        } else {
          return Column(
            children: [
              studentInfoCard,
              const SizedBox(height: 16),
              teacherInfoCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildInfoCard({required ThemeData theme, required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceContainerLowest, // Warna Card yang lebih lembut
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),
            ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: child,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4, // Label lebih banyak ruang jika perlu
          child: Text('$label:', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }


  Widget _buildDateSection(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          'Tanggal Input: ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
          Container(
            margin: const EdgeInsets.only(top: 5),
            height: 2.5,
            width: 70,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(2)
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _commonInputDecorator(ThemeData theme, String labelText, {String? hintText, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: theme.colorScheme.outline)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.7))
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5), // Warna fill lebih subtle
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }


  Widget _buildHafalanSection(BuildContext context, ThemeData theme, PemberianNilaiHalaqohController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('INFORMASI HAFALAN', theme),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownSearch<String>(
            key: UniqueKey(), // Tambahkan key untuk rebuild jika items berubah atau selectedItem direset
            decoratorProps: DropDownDecoratorProps(
              decoration: _commonInputDecorator(theme, 'Surat Hafalan', prefixIcon: const Icon(Icons.book_outlined)),
            ),
            selectedItem: ctrl.suratC.text.isEmpty ? null : ctrl.suratC.text,
            items: (f, cs) => const [ // Daftar surat bisa diperluas atau diambil dari sumber dinamis
              "An-Naba'", "An-Nazi'at", "Abasa", "At-Takwir", "Al-Infitar", "Al-Mutaffifin",
              "Al-Insyiqaq", "Al-Buruj", "At-Tariq", "Al-A'la", "Al-Ghasyiyah", "Al-Fajr",
              "Al-Balad", "Asy-Syams", "Al-Lail", "Ad-Duha", "Asy-Syarh",
              "At-Tin", "Al-'Alaq", "Al-Qadr", "Al-Bayyinah", "Az-Zalzalah", "Al-'Adiyat",
              "Al-Qari'ah", "At-Takasur", "Al-'Asr", "Al-Humazah", "Al-Fil", "Quraisy",
              "Al-Ma'un", "Al-Kausar", "Al-Kafirun", "An-Nasr", "Al-Masad",
              "Al-Ikhlas", "Al-Falaq", "An-Nas", "Lainnya..."
            ],
            onChanged: (String? value) {
              if (value != null) {
                ctrl.suratC.text = value;
              }
            },
            popupProps: PopupProps.menu(
              showSearchBox: true,
              fit: FlexFit.loose,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4), // Batasi tinggi popup
              searchFieldProps: TextFieldProps(
                decoration: _commonInputDecorator(theme, 'Cari Surat').copyWith(
                  hintText: 'Ketik nama surat...',
                  prefixIcon: const Icon(Icons.search)
                ),
              ),
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                backgroundColor: theme.colorScheme.surfaceContainer,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: ctrl.ayatHafalC,
            decoration: _commonInputDecorator(theme, 'Ayat yang Dihafal', hintText: 'Contoh: 1-5 atau 1, 3, 5', prefixIcon: const Icon(Icons.format_list_numbered_rtl_outlined)),
          ),
        ),
      ],
    );
  }

  Widget _buildUmmiAlquranSection(BuildContext context, ThemeData theme, PemberianNilaiHalaqohController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PROGRESS UMMI / AL-QUR\'AN', theme),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: ctrl.halAyatC,
            decoration: _commonInputDecorator(theme, 'Halaman / Ayat UMMI/Al-Qur\'an', hintText: 'Contoh: Jilid 3 Hal. 10 / QS. Al-Baqarah: 25', prefixIcon: const Icon(Icons.menu_book_outlined)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: ctrl.materiC,
            decoration: _commonInputDecorator(theme, 'Materi yang Dipelajari', hintText: 'Contoh: Mad Thabi\'i, Idgham Bighunnah', prefixIcon: const Icon(Icons.lightbulb_outline)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: ctrl.nilaiC,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: _commonInputDecorator(theme, 'Nilai (0-100)', prefixIcon: const Icon(Icons.star_border_outlined)),
            onChanged: (value) {
              if (value.isNotEmpty) {
                int nilai = int.tryParse(value) ?? 0;
                if (nilai > 100) {
                  ctrl.nilaiC.text = '100';
                  ctrl.nilaiC.selection = TextSelection.fromPosition(
                    TextPosition(offset: ctrl.nilaiC.text.length),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeteranganSection(BuildContext context, ThemeData theme, PemberianNilaiHalaqohController ctrl) {
    final List<Map<String, String>> keteranganOptions = [
      {
        "title": "Sangat Baik & Lanjut",
        "value": "Alhamdulillah, Ananda hari ini menunjukkan pemahaman yang sangat baik dan lancar. InsyaAllah, besok bisa melanjutkan ke materi berikutnya. Barokallohu fiik."
      },
      {
        "title": "Baik & Lancar",
        "value": "Alhamdulillah, Ananda hari ini sudah baik dan lancar. Tetap semangat belajar ya, Nak. Barokallohu fiik."
      },
      {
        "title": "Perlu Pengulangan",
        "value": "Alhamdulillah, Ananda hari ini sudah ada peningkatan. Mohon untuk dipelajari kembali di rumah, materi hari ini akan kita ulangi pada pertemuan berikutnya. Semangat!"
      },
      {
        "title": "Butuh Perhatian Khusus", // Tambahan opsi
        "value": "Ananda hari ini membutuhkan perhatian lebih pada materi [...]. Mohon bantuan Ayah/Bunda untuk mendampingi belajar di rumah."
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CATATAN PENGAMPU', theme),
        Obx(() => Column( // Bungkus dengan Obx untuk merebuild saat keteranganHalaqoh berubah
          children: keteranganOptions.map((option) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: RadioListTile<String>(
                title: Text(option['title']!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(option['value']!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 3, overflow: TextOverflow.ellipsis,),
                value: option['value']!,
                groupValue: ctrl.keteranganHalaqoh.value,
                onChanged: ctrl.onChangeKeterangan,
                activeColor: theme.colorScheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                tileColor: ctrl.keteranganHalaqoh.value == option['value']
                    ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                    : null, // Highlight pilihan aktif
                dense: true,
              ),
            );
          }).toList(),
        )),
        // SizedBox(height: 10),
        // TextField( // Jika ingin ada field keterangan custom
        //   controller: ctrl.keteranganGuruC,
        //   decoration: _commonInputDecorator(theme, 'Catatan Tambahan (Opsional)').copyWith(
        //     hintText: 'Isi jika opsi di atas tidak sesuai...',
        //     prefixIcon: Icon(Icons.edit_note_outlined)
        //   ),
        //   maxLines: 3,
        //   textCapitalization: TextCapitalization.sentences,
        //   onChanged: (text) {
        //     if (text.isNotEmpty && ctrl.keteranganHalaqoh.value.isNotEmpty) {
        //       ctrl.keteranganHalaqoh.value = ""; // Kosongkan pilihan radio jika custom diisi
        //     }
        //   },
        // ),
      ],
    );
  }

  Widget _buildSimpanButton(BuildContext context, PemberianNilaiHalaqohController ctrl) {
    return Obx(() => SizedBox( // Obx untuk merebuild tombol berdasarkan isLoading
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: ctrl.isLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white, // Atau theme.colorScheme.onPrimary
                ),
              )
            : const Icon(Icons.save_alt_outlined),
        label: Text(ctrl.isLoading.value ? 'Menyimpan...' : 'Simpan Nilai'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: ctrl.isLoading.value ? null : ctrl.simpanNilai,
      ),
    ));
  }
}

// Helper extension untuk mengakses properti private di controller (HINDARI JIKA BISA, ini hanya untuk demo cepat)
// Lebih baik _dataArgs dibuat public atau ada getter public di controller.
extension _ControllerPropertyAccessor on PemberianNilaiHalaqohController {
  dynamic getProperty(String name) {
    // Ini adalah hack dan tidak direkomendasikan untuk produksi.
    // Sebaiknya expose properti yang dibutuhkan melalui getter public.
    if (name == '_dataArgs') return this.dataArgs;
    return null;
  }
  bool get reactive => false; // Sesuaikan jika _dataArgs adalah Rx
}



// ========== KODE LAMA ======================

// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';

// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/services.dart';

// import '../controllers/pemberian_nilai_halaqoh_controller.dart';

// class PemberianNilaiHalaqohView
//     extends GetView<PemberianNilaiHalaqohController> {
//   PemberianNilaiHalaqohView({super.key});

//   final dataxx = Get.arguments;

//   @override
//   Widget build(BuildContext context) {
//     // print("dataxx = $dataxx");
//     return Scaffold(
//       appBar: _buildAppBar(),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(15),
//           children: [
//             Column(children: [_buildHeaderSection()]),
//             Divider(height: 3, color: Colors.black),
//             SizedBox(height: 20),
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     children: [
//                       Card(
//                         child: Column(
//                           spacing: 5,
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text('Nama Siswa : ${dataxx['namasiswa']}'),
//                             Text('No Induk : ${dataxx['nisn']}'),
//                             Text('Kelas :  ${dataxx['kelas']}'),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(width: 20),
//                   Column(
//                     children: [
//                       Card(
//                         child: Column(
//                           spacing: 5,
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             FutureBuilder<Object>(
//                               future: controller.ambilDataUmi(),
//                               builder: (context, snapumi) {
//                                 if (snapumi.connectionState ==
//                                     ConnectionState.waiting) {
//                                   return Center(
//                                     child: CircularProgressIndicator(),
//                                   );
//                                 }
//                                 if (snapumi.data == null ||
//                                     snapumi.data == "0") {
//                                   return Text("Belum di input");
//                                 }
//                                 if (snapumi.hasData) {
//                                   String dataUmi = snapumi.data as String;
//                                   return Text("UMI : $dataUmi");
//                                 } else {
//                                   return Text("Belum di input");
//                                 }
//                               },
//                             ),
//                             Text("Ustadz/ah : ${dataxx['namapengampu']}"),
//                             Text("Tempat : ${dataxx['tempatmengaji']}"),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),
//             Column(
//               spacing: 5,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Text('Tatap muka ke :'),
//                 Text(
//                   'Tanggal :   ${DateFormat.yMd().format(DateTime.now()).replaceAll("/", "-")}',
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   'HAFALAN',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 Divider(height: 2, color: Colors.black),
//                 DropdownSearch<String>(
//                   decoratorProps: DropDownDecoratorProps(
//                     decoration: InputDecoration(
//                       border: UnderlineInputBorder(),
//                       filled: true,
//                       prefixText: 'surat: ',
//                     ),
//                   ),
//                   selectedItem: controller.suratC.text,
//                   items:
//                       (f, cs) => [
//                         "Annas",
//                         'Al-Falaq',
//                         'Al Ikhlas',
//                         'Al Lahab',
//                         'An Nasr',
//                         'dll',
//                       ],
//                   onChanged: (String? value) {
//                     if (value != null) {
//                       controller.suratC.text = value;
//                     }
//                   },
//                   popupProps: PopupProps.menu(
//                     // disabledItemFn: (item) => item == '1A',
//                     fit: FlexFit.tight,
//                   ),
//                 ),
//                 TextField(
//                   controller: controller.ayatHafalC,
//                   decoration: InputDecoration(
//                     border: OutlineInputBorder(),
//                     hintText: 'Ayat yang dihafal',
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   'UMMI/ALQURAN',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 Divider(height: 2, color: Colors.black),
//                 TextField(
//                   controller: controller.halAyatC,
//                   decoration: InputDecoration(
//                     border: OutlineInputBorder(),
//                     hintText: 'Hal / Ayat',
//                   ),
//                 ),
//                 TextField(
//                   controller: controller.materiC,
//                   decoration: InputDecoration(
//                     border: OutlineInputBorder(),
//                     hintText: 'Materi',
//                   ),
//                 ),
//                 TextField(
//                   keyboardType: TextInputType.number,
//                   inputFormatters: <TextInputFormatter>[
//                     FilteringTextInputFormatter.digitsOnly,
//                   ],
//                   controller: controller.nilaiC,
//                   decoration: InputDecoration(
//                     border: OutlineInputBorder(),
//                     hintText: 'Nilai (Hanya angka)',
//                   ),
//                   onChanged: (value) {
//                     if (value.isNotEmpty) {
//                       int nilai = int.parse(value);
//                       if (nilai > 100) {
//                         controller.nilaiC.text = '100';
//                         //Batasi nilai menjadi 100
//                         controller
//                             .nilaiC
//                             .selection = TextSelection.fromPosition(
//                           TextPosition(offset: controller.nilaiC.text.length),
//                         );
//                         // Pindahkan kursor ke akhir
//                       } else if (nilai.toString().length > 3) {
//                         controller.nilaiC.text = '100';
//                         //Batasi nilai menjadi 100
//                         controller
//                             .nilaiC
//                             .selection = TextSelection.fromPosition(
//                           TextPosition(offset: controller.nilaiC.text.length),
//                         );
//                         // Pindahkan kursor ke akhir
//                       }
//                     }
//                   },
//                 ),
//                 SizedBox(height: 10),

//                 Text(
//                   'KETERANGAN / CATATAN PENGAMPU',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 Divider(height: 2, color: Colors.black),
//                 SizedBox(height: 3),
//                 // TextField(
//                 //   controller: controller.keteranganGuruC,
//                 //   decoration: InputDecoration(
//                 //     border: OutlineInputBorder(),
//                 //     hintText: 'Keterangan / Catatan Pengampu',
//                 //   ),
//                 // ),
//                 Row(
//                   children: [
//                     Obx(
//                       () => Radio(
//                         value:
//                             "Alhamdulillah, ananda hari sangat bagus dan lancar, dalam memahami materi hari ini, InsyaAlloh, besok lanjut ke materi selanjutnta.. Barokallohu fiik.",
//                         groupValue: controller.keteranganHalaqoh.value,
//                         activeColor: Colors.black,
//                         fillColor: WidgetStateProperty.all(Colors.grey[700]),
//                         onChanged: (value) {
//                           // Handle the change here
//                           controller.keteranganHalaqoh.value = value.toString();
//                           // print(value);
//                         },
//                       ),
//                     ),
//                     Text("Lanjut"),
//                     SizedBox(width: 20),
//                     Obx(
//                       () => Radio(
//                         value:
//                             "Alhamdulillah, ananda hari sangat bagus dan lancar, tetap semangat ya sholih.. Barokallohu fiik..",
//                         groupValue: controller.keteranganHalaqoh.value,
//                         activeColor: Colors.black,
//                         fillColor: WidgetStateProperty.all(Colors.grey[700]),
//                         onChanged: (value) {
//                           // Handle the change here
//                           controller.keteranganHalaqoh.value = value.toString();
//                           // print(value);
//                         },
//                       ),
//                     ),
//                     Text("Lancar"),
//                     SizedBox(width: 20),
//                     Obx(
//                       () => Radio(
//                         value:
//                             "Alhamdulillah Ananda hari ini sudah ada peningkatan, akan tetapi mohon nanti dirumah dipelajari lagi, dan nanti akan kita ulangi lagi untuk materi ini",
//                         groupValue: controller.keteranganHalaqoh.value,
//                         activeColor: Colors.black,
//                         fillColor: WidgetStateProperty.all(Colors.grey[700]),
//                         onChanged: (value) {
//                           // Handle the change here
//                           controller.keteranganHalaqoh.value = value.toString();
//                           // print(value);
//                         },
//                       ),
//                     ),
//                     Text("Ulang"),
//                   ],
//                 ),
//                 Center(
//                   child: FloatingActionButton(
//                     onPressed: () {
//                       if (controller.suratC.text.isEmpty) {
//                         Get.snackbar(
//                           'Peringatan',
//                           'Hafalan surat masih kosong',
//                         );
//                       } else if (controller.ayatHafalC.text.isEmpty) {
//                         Get.snackbar(
//                           'Peringatan',
//                           'Ayat hafalan surat masih kosong',
//                         );
//                       }
//                       // else if (controller.jldSuratC.text.isEmpty) {
//                       //   Get.snackbar(
//                       //     'Peringatan',
//                       //     'Jilid / AlQuran ummi masih kosong',
//                       //   );
//                       // }
//                       else if (controller.halAyatC.text.isEmpty) {
//                         Get.snackbar(
//                           'Peringatan',
//                           'Halaman atau Ayat masih kosong',
//                         );
//                       } else if (controller.materiC.text.isEmpty) {
//                         Get.snackbar('Peringatan', 'Materi masih kosong');
//                       } else if (controller.nilaiC.text.isEmpty) {
//                         Get.snackbar('Peringatan', 'Nilai masih kosong');
//                       } else if (controller.keteranganHalaqoh.value.isEmpty) {
//                         Get.snackbar('Peringatan', 'Keterangan masih kosong');
//                       } else {
//                         controller.simpanNilai();
//                         Navigator.of(context).pop();
//                       }
//                     },
//                     child: Text('Simpan'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: const Text('Kartu Prestasi'),
//       backgroundColor: Colors.indigo[400],
//       elevation: 0,
//     );
//   }

//   Widget _buildHeaderSection() {
//     return Column(children: [_buildHeader(), const SizedBox(height: 5)]);
//   }

//   Widget _buildHeader() {
//     return Column(
//       children: const [
//         Text(
//           "KARTU PRESTASI PEMBELAJARAN ALQUR'AN METODE UMMI",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           textAlign: TextAlign.center,
//         ),
//         SizedBox(height: 5),
//         Text(
//           "SD IT UKHUWAH ISLAMIYYAH",
//           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }
// }
