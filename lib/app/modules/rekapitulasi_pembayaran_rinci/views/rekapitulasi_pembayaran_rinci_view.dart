import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/rekapitulasi_pembayaran_rinci_controller.dart';

class RekapitulasiPembayaranRinciView extends GetView<RekapitulasiPembayaranRinciController> {
  const RekapitulasiPembayaranRinciView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: controller.jenisPembayaranList.length,
      child: Scaffold(
        appBar: AppBar(
          title: _buildSearchField(),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            tabs: controller.jenisPembayaranList
                .map((jenis) => Tab(text: jenis.replaceAll('_', ' ')))
                .toList(),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Mengambil data pembayaran..."),
                ],
              ),
            );
          }
          return Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: TabBarView(
                  children: controller.jenisPembayaranList
                      .map((jenis) => _buildSummaryListView(jenis))
                      .toList(),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: 'Cari nama siswa...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => controller.searchController.clear(),
          ),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Obx(
        () => DropdownButtonFormField<String>(
          value: controller.selectedKelas.value,
          decoration: InputDecoration(
            labelText: 'Filter Berdasarkan Kelas',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: controller.daftarKelas.map((String kelas) {
            return DropdownMenuItem<String>(
              value: kelas,
              child: Text(kelas),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              controller.selectedKelas.value = newValue;
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryListView(String jenisPembayaran) {
    return Obx(() {
      // Dibungkus Obx agar list update saat filter/search berubah
      final summaries = controller.getFilteredSummaries(jenisPembayaran);
      if (summaries.isEmpty) {
        return Center(child: Text("Tidak ada data untuk ditampilkan."));
      }
      return ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: summaries.length,
        itemBuilder: (context, index) {
          final summary = summaries[index];
          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(summary.namaSiswa, style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text("Kelas: ${summary.kelas}"),
              trailing: Chip(
                label: Text(
                  summary.keteranganStatus,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                backgroundColor: summary.warnaStatus,
                padding: EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              onTap: () => _showDetailBottomSheet(context, summary),
            ),
          );
        },
      );
    });
  }

  void _showDetailBottomSheet(BuildContext context, PembayaranSiswaSummary summary) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(summary.namaSiswa, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text("Kelas: ${summary.kelas} | ${summary.jenisPembayaran.replaceAll('_', ' ')}", style: Theme.of(context).textTheme.bodyLarge),
            if (summary.jenisPembayaran != 'SPP')
              Text("Tagihan: ${controller.formatRupiah(summary.totalHarusBayar)}", style: Theme.of(context).textTheme.bodyMedium),
            Divider(height: 24, thickness: 1),

            // Konten
            Expanded(
              child: ListView(
                children: [
                  // Bagian Tunggakan
                  if (summary.sisaKekurangan > 0) ...[
                    Text("Detail Kekurangan", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red.shade700)),
                    if (summary.jenisPembayaran == 'SPP')
                      ...summary.daftarTunggakanBulan.map((bulan) => ListTile(
                            dense: true,
                            title: Text("Tunggakan bulan $bulan"),
                            trailing: ElevatedButton(
                              child: Text("Bayar"),
                              onPressed: () {
                                  Get.back();
                                  controller.bayarTunggakan(
                                    summary.idSiswa,
                                    'SPP',
                                    summary.idKelas, // <-- Gunakan idKelas
                                    summary.sisaKekurangan,
                                    bulan: bulan,
                                  );
                                },
                            ),
                          ))
                    else
                      ListTile(
                        title: Text("Sisa: ${controller.formatRupiah(summary.sisaKekurangan)}"),
                        trailing: ElevatedButton(
                          child: Text("Bayar"),
                          onPressed: () {
                            Get.back();
                            controller.bayarTunggakan(
                              summary.idSiswa,
                              summary.jenisPembayaran,
                              summary.idKelas, // <-- Gunakan idKelas
                              summary.sisaKekurangan,
                            );
                          },
                        ),
                      ),
                    Divider(height: 24),
                  ],

                  // Riwayat Transaksi
                  Text("Riwayat Pembayaran", style: Theme.of(context).textTheme.titleLarge),
                  if (summary.riwayatTransaksi.isEmpty)
                    Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("Belum ada transaksi."))
                  else
                    ...summary.riwayatTransaksi.map((trx) => ListTile(
                          title: Text(summary.jenisPembayaran == 'SPP'
                              ? "Pembayaran bulan ${trx.bulan}"
                              : controller.formatRupiah(trx.nominal)),
                          subtitle: Text("Tgl: ${controller.formatTanggal(trx.tglBayar)} oleh ${trx.petugas}"),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
    );
  }
}
