// lib/views/kalender_akademik_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/kalender_akademik_controller.dart';
import '../../../models/event_kalender_model.dart'; // Sesuaikan path jika perlu

class KalenderAkademikView extends GetView<KalenderAkademikController> {
  const KalenderAkademikView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Inisialisasi locale untuk format tanggal Indonesia
    Intl.defaultLocale = 'id_ID';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Akademik'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildTableCalendar(theme),
            const Divider(thickness: 1, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80), // Ruang untuk FAB
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDailyEventList(theme),
                    const Divider(indent: 16, endIndent: 16, height: 32),
                    _buildMonthlySummaryList(theme),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(() => controller.userRole.value == 'Kepala Sekolah'
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEventDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("Tambah Agenda"),
            )
          : const SizedBox.shrink()),
    );
  }

  // WIDGET 1: Kalender
  Widget _buildTableCalendar(ThemeData theme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Obx(() => TableCalendar<EventKalenderModel>(
              locale: 'id_ID',
              firstDay: DateTime.utc(2022, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: controller.focusedDay.value,
              selectedDayPredicate: (day) => isSameDay(controller.selectedDay.value, day),
              calendarFormat: controller.calendarFormat.value,
              eventLoader: controller.getEventsForDay,
              onDaySelected: controller.onDaySelected,
              onPageChanged: controller.onPageChanged,
              onFormatChanged: (format) => controller.calendarFormat.value = format,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.3), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(right: 1, bottom: 1, child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: events.first.color)));
                  }
                  return const SizedBox.shrink();
                },
              ),
            )),
      ),
    );
  }

  // WIDGET 2: Daftar Agenda Harian
  Widget _buildDailyEventList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Agenda pada ${DateFormat.yMMMMEEEEd().format(controller.selectedDay.value!)}", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.selectedEvents.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Tidak ada agenda pada tanggal ini.', style: TextStyle(color: Colors.grey))));
            }
            return ListView.builder(
              itemCount: controller.selectedEvents.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final event = controller.selectedEvents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: Icon(event.isLibur ? Icons.celebration : Icons.event, color: theme.primaryColor),
                    title: Text(event.keterangan, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Obx(() {
                      if (controller.userRole.value == 'Kepala Sekolah') {
                        return Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: Icon(Icons.edit, color: Colors.blue.shade700, size: 20), onPressed: () => _showAddEventDialog(context)),
                          IconButton(icon: Icon(Icons.delete, color: Colors.red.shade700, size: 20), onPressed: () => controller.hapusEvent(event.id, DateTime.parse(event.id))),
                        ]);
                      }
                      return const SizedBox.shrink();
                    }),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  // WIDGET 3: Daftar Ringkasan Bulanan
  Widget _buildMonthlySummaryList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text("Ringkasan Bulan ${DateFormat('MMMM yyyy').format(controller.focusedDay.value)}", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.groupedMonthlyEvents.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('Tidak ada agenda pada bulan ini.', style: TextStyle(color: Colors.grey))));
            }
            return ListView.separated(
              itemCount: controller.groupedMonthlyEvents.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final groupedEvent = controller.groupedMonthlyEvents[index];
                final isSingleDay = isSameDay(groupedEvent.startDate, groupedEvent.endDate);

                String dateText;
                if (isSingleDay) {
                  dateText = DateFormat.yMMMMEEEEd().format(groupedEvent.startDate);
                } else {
                  if (groupedEvent.startDate.month != groupedEvent.endDate.month) {
                    dateText = "${DateFormat('d MMM').format(groupedEvent.startDate)} - ${DateFormat('d MMM yyyy').format(groupedEvent.endDate)}";
                  } else {
                    dateText = "${DateFormat('d').format(groupedEvent.startDate)} - ${DateFormat.yMMMMd().format(groupedEvent.endDate)}";
                  }
                }
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Container(width: 8, color: groupedEvent.color),
                      Expanded(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          title: Text(groupedEvent.keterangan, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(dateText)),
                          trailing: groupedEvent.isLibur ? const Icon(Icons.bookmark_added, color: Colors.red) : null,
                        ),
                      ),
                    ]),
                  ),
                );
              },
            );
          })
        ],
      ),
    );
  }

 void _showAddEventDialog(BuildContext context) {
        final theme = Theme.of(context);
        // Reset state sebelum dialog dibuka
        controller.eventController.clear();
        controller.rentangAwal.value = controller.selectedDay.value ?? DateTime.now();
        controller.rentangAkhir.value = controller.selectedDay.value ?? DateTime.now();
        controller.isLiburSwitch.value = false;
        controller.selectedColor.value = Colors.blue;
        Get.defaultDialog(
          title: "Tambah Agenda/Libur",
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          content: SizedBox(
          width: Get.width * 0.8, // Lebar 80% dari layar
          height: Get.height * 0.5, // Tinggi maksimal
          child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          TextField(
          controller: controller.eventController,
          decoration: const InputDecoration(labelText: 'Keterangan Acara'),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        // --- PEMILIH RENTANG TANGGAL ---
                const Text("Rentang Tanggal:", style: TextStyle(fontWeight: FontWeight.w500)),
                Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: controller.rentangAwal.value,
                          firstDate: DateTime(2022),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          await Future.delayed(const Duration(milliseconds: 100));
                          controller.rentangAwal.value = picked;
                            // Jika tanggal awal melewati tanggal akhir, samakan tanggal akhir
                          if (picked.isAfter(controller.rentangAkhir.value)) {
                              controller.rentangAkhir.value = picked;
                          }
                        }
                      },
                      child: Text(DateFormat('dd MMM yyyy').format(controller.rentangAwal.value)),
                    ),
                    const Text("s/d"),
          
                    // Tombol untuk TANGGAL AKHIR
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: controller.rentangAkhir.value,
                          // Tanggal pertama tidak boleh sebelum tanggal awal
                          firstDate: controller.rentangAwal.value, 
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          await Future.delayed(const Duration(milliseconds: 100));
                          controller.rentangAkhir.value = picked;
                        }
                      },
                      child: Text(DateFormat('dd MMM yyyy').format(controller.rentangAkhir.value)),
                    ),
                  ],
                )),
                
                const SizedBox(height: 8),
          
                // --- SWITCH LIBUR ---
                Obx(() => SwitchListTile(
                  title: const Text('Tandai sebagai Hari Libur'),
                  value: controller.isLiburSwitch.value,
                  onChanged: (val) => controller.isLiburSwitch.value = val,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
                
                const SizedBox(height: 8),
                
                // --- PEMILIH WARNA ---
                const Text("Pilih Warna Penanda:", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _buildColorPicker(),
          
              ],
            ),
          ),
        ),
        confirm: ElevatedButton(
          onPressed: controller.simpanEvent,
          child: const Text('Simpan'),
        ),
        cancel: TextButton(
          onPressed: () => Get.back(),
          child: const Text('Batal'),
        ),
        );
       }
        Widget _buildColorPicker() {
        final List<Color> colors = [
        Colors.blue, Colors.green, Colors.red, Colors.orange,
        Colors.purple, Colors.teal, Colors.pink, Colors.amber
        ];
        return SizedBox(
        height: 40,
        child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
        final color = colors[index];
        return Obx(() => GestureDetector(
        onTap: () => controller.selectedColor.value = color,
        child: Container(
        width: 40,
        decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: controller.selectedColor.value == color
        ? Border.all(color: Colors.black, width: 2.5)
        : null,
        ),
        ),
        ));
        },
        ),
        );
       }
       
}