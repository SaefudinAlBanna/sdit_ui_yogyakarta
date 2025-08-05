import 'package:get/get.dart';

import '../modules/absensi/bindings/absensi_binding.dart';
import '../modules/absensi/views/absensi_view.dart';
import '../modules/analisis_akademik/bindings/analisis_akademik_binding.dart';
import '../modules/analisis_akademik/views/analisis_akademik_view.dart';
import '../modules/atp_form/bindings/atp_form_binding.dart';
import '../modules/atp_form/views/atp_form_view.dart';
import '../modules/atur_pengganti/bindings/atur_pengganti_binding.dart';
import '../modules/atur_pengganti/views/atur_pengganti_view.dart';
import '../modules/buat_jadwal_pelajaran/bindings/buat_jadwal_pelajaran_binding.dart';
import '../modules/buat_jadwal_pelajaran/views/buat_jadwal_pelajaran_view.dart';
import '../modules/buat_sarpras/bindings/buat_sarpras_binding.dart';
import '../modules/buat_sarpras/views/buat_sarpras_view.dart';
import '../modules/catatan_siswa/bindings/catatan_siswa_binding.dart';
import '../modules/catatan_siswa/views/catatan_siswa_view.dart';
import '../modules/daftar_ekskul/bindings/daftar_ekskul_binding.dart';
import '../modules/daftar_ekskul/views/daftar_ekskul_view.dart';
import '../modules/daftar_halaqoh/bindings/daftar_halaqoh_binding.dart';
import '../modules/daftar_halaqoh/views/daftar_halaqoh_view.dart';
import '../modules/daftar_halaqoh_pengampu/bindings/daftar_halaqoh_pengampu_binding.dart';
import '../modules/daftar_halaqoh_pengampu/views/daftar_halaqoh_pengampu_view.dart';
import '../modules/daftar_halaqoh_perfase/bindings/daftar_halaqoh_perfase_binding.dart';
import '../modules/daftar_halaqoh_perfase/views/daftar_halaqoh_perfase_view.dart';
import '../modules/daftar_halaqohnya/bindings/daftar_halaqohnya_binding.dart';
import '../modules/daftar_halaqohnya/views/daftar_halaqohnya_view.dart';
import '../modules/daftar_informasi/bindings/daftar_informasi_binding.dart';
import '../modules/daftar_informasi/views/daftar_informasi_view.dart';
import '../modules/daftar_jurnal_ajar/bindings/daftar_jurnal_ajar_binding.dart';
import '../modules/daftar_jurnal_ajar/views/daftar_jurnal_ajar_view.dart';
import '../modules/daftar_kelas/bindings/daftar_kelas_binding.dart';
import '../modules/daftar_kelas/views/daftar_kelas_view.dart';
import '../modules/daftar_nilai/bindings/daftar_nilai_binding.dart';
import '../modules/daftar_nilai/views/daftar_nilai_view.dart';
import '../modules/daftar_pegawai/bindings/daftar_pegawai_binding.dart';
import '../modules/daftar_pegawai/views/daftar_pegawai_view.dart';
import '../modules/daftar_siswa_perkelas/bindings/daftar_siswa_perkelas_binding.dart';
import '../modules/daftar_siswa_perkelas/views/daftar_siswa_perkelas_view.dart';
import '../modules/daftar_siswa_permapel/bindings/daftar_siswa_permapel_binding.dart';
import '../modules/daftar_siswa_permapel/views/daftar_siswa_permapel_view.dart';
import '../modules/daftar_siswa_pindah_halaqoh/bindings/daftar_siswa_pindah_halaqoh_binding.dart';
import '../modules/daftar_siswa_pindah_halaqoh/views/daftar_siswa_pindah_halaqoh_view.dart';
import '../modules/dasbor_pembina/bindings/dasbor_pembina_binding.dart';
import '../modules/dasbor_pembina/bindings/log_ekskul_siswa_binding.dart';
import '../modules/dasbor_pembina/bindings/pembina_ekskul_binding.dart';
import '../modules/dasbor_pembina/views/dasbor_pembina_view.dart';
import '../modules/dasbor_pembina/views/log_ekskul_siswa_view.dart';
import '../modules/data_sarpras/bindings/data_sarpras_binding.dart';
import '../modules/data_sarpras/views/data_sarpras_view.dart';
import '../modules/detail_nilai_halaqoh/bindings/detail_nilai_halaqoh_binding.dart';
import '../modules/detail_nilai_halaqoh/views/detail_nilai_halaqoh_view.dart';
import '../modules/detail_siswa/bindings/detail_siswa_binding.dart';
import '../modules/detail_siswa/views/detail_siswa_view.dart';
import '../modules/forgot_password/bindings/forgot_password_binding.dart';
import '../modules/forgot_password/views/forgot_password_view.dart';
import '../modules/guru_pengganti/bindings/guru_pengganti_binding.dart';
import '../modules/guru_pengganti/views/guru_pengganti_view.dart';
import '../modules/halaman_pengganti/bindings/halaman_pengganti_binding.dart';
import '../modules/halaman_pengganti/views/halaman_pengganti_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/import_pegawai/bindings/import_pegawai_binding.dart';
import '../modules/import_pegawai/views/import_pegawai_view.dart';
import '../modules/import_siswa_excel/bindings/import_siswa_excel_binding.dart';
import '../modules/import_siswa_excel/views/import_siswa_excel_view.dart';
import '../modules/input_catatan_khusus_siswa/bindings/input_catatan_khusus_siswa_binding.dart';
import '../modules/input_catatan_khusus_siswa/views/input_catatan_khusus_siswa_view.dart';
import '../modules/input_ekskul/bindings/input_ekskul_binding.dart';
import '../modules/input_ekskul/views/input_ekskul_view.dart';
import '../modules/input_info_sekolah/bindings/input_info_sekolah_binding.dart';
import '../modules/input_info_sekolah/views/input_info_sekolah_view.dart';
import '../modules/input_nilai_siswa/bindings/input_nilai_siswa_binding.dart';
import '../modules/input_nilai_siswa/views/input_nilai_siswa_view.dart';
import '../modules/instance_ekskul/bindings/instance_ekskul_binding.dart';
import '../modules/instance_ekskul/views/instance_ekskul_view.dart';
import '../modules/jadwal_pelajaran/bindings/jadwal_pelajaran_binding.dart';
import '../modules/jadwal_pelajaran/views/jadwal_pelajaran_view.dart';
import '../modules/jurnal_ajar_harian/bindings/jurnal_ajar_harian_binding.dart';
import '../modules/jurnal_ajar_harian/views/jurnal_ajar_harian_view.dart';
import '../modules/kalender_akademik/bindings/kalender_akademik_binding.dart';
import '../modules/kalender_akademik/views/kalender_akademik_view.dart';
import '../modules/kelas_tahfidz/bindings/kelas_tahfidz_binding.dart';
import '../modules/kelas_tahfidz/views/kelas_tahfidz_view.dart';
import '../modules/kelola_catatan_rapor/bindings/kelola_catatan_rapor_binding.dart';
import '../modules/kelola_catatan_rapor/views/kelola_catatan_rapor_view.dart';
import '../modules/kelompok_halaqoh/bindings/kelompok_halaqoh_binding.dart';
import '../modules/kelompok_halaqoh/views/kelompok_halaqoh_view.dart';
import '../modules/kurikulum_master/bindings/kurikulum_master_binding.dart';
import '../modules/kurikulum_master/views/kurikulum_master_view.dart';
import '../modules/laksanakan_ujian/bindings/laksanakan_ujian_binding.dart';
import '../modules/laksanakan_ujian/views/laksanakan_ujian_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/manajemen_ekskul/bindings/manajemen_ekskul_binding.dart';
import '../modules/manajemen_ekskul/views/manajemen_ekskul_view.dart';
import '../modules/manajemen_jabatan/bindings/manajemen_jabatan_binding.dart';
import '../modules/manajemen_jabatan/views/manajemen_jabatan_view.dart';
import '../modules/manajemen_jam/bindings/manajemen_jam_binding.dart';
import '../modules/manajemen_jam/views/manajemen_jam_view.dart';
import '../modules/manajemen_tahun_ajaran_ekskul/bindings/manajemen_tahun_ajaran_ekskul_binding.dart';
import '../modules/manajemen_tahun_ajaran_ekskul/views/manajemen_tahun_ajaran_ekskul_view.dart';
import '../modules/manajemen_tugas/bindings/manajemen_tugas_binding.dart';
import '../modules/manajemen_tugas/views/manajemen_tugas_view.dart';
import '../modules/mapel_siswa/bindings/mapel_siswa_binding.dart';
import '../modules/mapel_siswa/views/mapel_siswa_view.dart';
import '../modules/master_ekskul/bindings/master_ekskul_binding.dart';
import '../modules/master_ekskul/views/master_ekskul_view.dart';
import '../modules/modul_ajar_form/bindings/modul_ajar_form_binding.dart';
import '../modules/modul_ajar_form/views/modul_ajar_form_view.dart';
import '../modules/new_password/bindings/new_password_binding.dart';
import '../modules/new_password/views/new_password_view.dart';
import '../modules/pantau_tahfidz/bindings/pantau_tahfidz_binding.dart';
import '../modules/pantau_tahfidz/views/pantau_tahfidz_view.dart';
import '../modules/pembayaran_spp/bindings/pembayaran_spp_binding.dart';
import '../modules/pembayaran_spp/views/pembayaran_spp_view.dart';
import '../modules/pemberian_guru_mapel/bindings/pemberian_guru_mapel_binding.dart';
import '../modules/pemberian_guru_mapel/views/pemberian_guru_mapel_view.dart';
import '../modules/pemberian_kelas_siswa/bindings/pemberian_kelas_siswa_binding.dart';
import '../modules/pemberian_kelas_siswa/views/pemberian_kelas_siswa_view.dart';
import '../modules/pemberian_nilai_halaqoh/bindings/pemberian_nilai_halaqoh_binding.dart';
import '../modules/pemberian_nilai_halaqoh/views/pemberian_nilai_halaqoh_view.dart';
import '../modules/pembina_eksternal/bindings/pembina_eksternal_binding.dart';
import '../modules/pembina_eksternal/views/pembina_eksternal_view.dart';
import '../modules/penilaian_rapor_ekskul/bindings/penilaian_rapor_ekskul_binding.dart';
import '../modules/penilaian_rapor_ekskul/views/penilaian_rapor_ekskul_view.dart';
import '../modules/penilaian_rapor_halaqoh/bindings/penilaian_rapor_halaqoh_binding.dart';
import '../modules/penilaian_rapor_halaqoh/views/penilaian_rapor_halaqoh_view.dart';
import '../modules/perangkat_ajar/bindings/perangkat_ajar_binding.dart';
import '../modules/perangkat_ajar/views/perangkat_ajar_view.dart';
import '../modules/prota_prosem/bindings/prota_prosem_binding.dart';
import '../modules/prota_prosem/views/prota_prosem_view.dart';
import '../modules/rapor_ekskul_siswa/bindings/rapor_ekskul_siswa_binding.dart';
import '../modules/rapor_ekskul_siswa/views/rapor_ekskul_siswa_view.dart';
import '../modules/rapor_siswa/bindings/rapor_siswa_binding.dart';
import '../modules/rapor_siswa/views/rapor_siswa_view.dart';
import '../modules/rapor_terpadu/bindings/rapor_terpadu_binding.dart';
import '../modules/rapor_terpadu/views/rapor_terpadu_view.dart';
import '../modules/rekap_absensi/bindings/rekap_absensi_binding.dart';
import '../modules/rekap_absensi/views/rekap_absensi_view.dart';
import '../modules/rekap_jurnal_admin/bindings/rekap_jurnal_admin_binding.dart';
import '../modules/rekap_jurnal_admin/views/rekap_jurnal_admin_view.dart';
import '../modules/rekap_jurnal_guru/bindings/rekap_jurnal_guru_binding.dart';
import '../modules/rekap_jurnal_guru/views/rekap_jurnal_guru_view.dart';
import '../modules/rekapitulasi_pembayaran/bindings/rekapitulasi_pembayaran_binding.dart';
import '../modules/rekapitulasi_pembayaran/views/rekapitulasi_pembayaran_view.dart';
import '../modules/rekapitulasi_pembayaran_rinci/bindings/rekapitulasi_pembayaran_rinci_binding.dart';
import '../modules/rekapitulasi_pembayaran_rinci/views/rekapitulasi_pembayaran_rinci_view.dart';
import '../modules/spesialisasi/bindings/spesialisasi_binding.dart';
import '../modules/spesialisasi/views/spesialisasi_view.dart';
import '../modules/tambah_kelompok_mengaji/bindings/tambah_kelompok_mengaji_binding.dart';
import '../modules/tambah_kelompok_mengaji/views/tambah_kelompok_mengaji_view.dart';
import '../modules/tambah_pegawai/bindings/tambah_pegawai_binding.dart';
import '../modules/tambah_pegawai/views/tambah_pegawai_view.dart';
import '../modules/tambah_siswa/bindings/tambah_siswa_binding.dart';
import '../modules/tambah_siswa/views/tambah_siswa_view.dart';
import '../modules/tampilkan_info_sekolah/bindings/tampilkan_info_sekolah_binding.dart';
import '../modules/tampilkan_info_sekolah/views/tampilkan_info_sekolah_view.dart';
import '../modules/tanggapan_catatan/bindings/tanggapan_catatan_binding.dart';
import '../modules/tanggapan_catatan/views/tanggapan_catatan_view.dart';
import '../modules/tanggapan_catatan_khusus_siswa/bindings/tanggapan_catatan_khusus_siswa_binding.dart';
import '../modules/tanggapan_catatan_khusus_siswa/views/tanggapan_catatan_khusus_siswa_view.dart';
import '../modules/tanggapan_catatan_khusus_siswa_walikelas/bindings/tanggapan_catatan_khusus_siswa_walikelas_binding.dart';
import '../modules/tanggapan_catatan_khusus_siswa_walikelas/views/tanggapan_catatan_khusus_siswa_walikelas_view.dart';
// import '../modules/dasbor_pembina/bindings/PembinaEkskulBinding.dart';
// import '../modules/pembina_area/bindings/pembina_ekskul_detail_binding.dart';
import '../modules/dasbor_pembina/views/pembina_ekskul_detail_view.dart';
import '../modules/laporan_ekskul/bindings/laporan_ekskul_binding.dart';
import '../modules/laporan_ekskul/views/laporan_ekskul_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: _Paths.NEW_PASSWORD,
      page: () => const NewPasswordView(),
      binding: NewPasswordBinding(),
    ),
    GetPage(
      name: _Paths.TAMBAH_PEGAWAI,
      page: () => const TambahPegawaiView(),
      binding: TambahPegawaiBinding(),
    ),
    GetPage(
      name: _Paths.TAMBAH_KELOMPOK_MENGAJI,
      page: () => const TambahKelompokMengajiView(),
      binding: TambahKelompokMengajiBinding(),
    ),
    GetPage(
      name: _Paths.TAMBAH_SISWA,
      page: () => const TambahSiswaView(),
      binding: TambahSiswaBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_KELAS,
      page: () => DaftarKelasView(),
      binding: DaftarKelasBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_HALAQOH_PENGAMPU,
      page: () => DaftarHalaqohPengampuView(),
      binding: DaftarHalaqohPengampuBinding(),
    ),
    GetPage(
      name: _Paths.PEMBERIAN_KELAS_SISWA,
      page: () => PemberianKelasSiswaView(),
      binding: PemberianKelasSiswaBinding(),
    ),
    GetPage(
      name: _Paths.KELOMPOK_HALAQOH,
      page: () => KelompokHalaqohView(),
      binding: KelompokHalaqohBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_HALAQOH_PERFASE,
      page: () => DaftarHalaqohPerfaseView(),
      binding: DaftarHalaqohPerfaseBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA_PINDAH_HALAQOH,
      page: () => const DaftarSiswaPindahHalaqohView(),
      binding: DaftarSiswaPindahHalaqohBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_HALAQOH,
      page: () => DaftarHalaqohView(),
      binding: DaftarHalaqohBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_NILAI,
      page: () => DaftarNilaiView(),
      binding: DaftarNilaiBinding(),
    ),
    GetPage(
      name: _Paths.PEMBERIAN_NILAI_HALAQOH,
      page: () => PemberianNilaiHalaqohView(),
      binding: PemberianNilaiHalaqohBinding(),
    ),
    GetPage(
      name: _Paths.DETAIL_SISWA,
      page: () => DetailSiswaView(),
      binding: DetailSiswaBinding(),
    ),
    GetPage(
      name: _Paths.DETAIL_NILAI_HALAQOH,
      page: () => DetailNilaiHalaqohView(),
      binding: DetailNilaiHalaqohBinding(),
    ),
    GetPage(
      name: _Paths.PEMBERIAN_GURU_MAPEL,
      page: () => PemberianGuruMapelView(),
      binding: PemberianGuruMapelBinding(),
    ),
    GetPage(
      name: _Paths.MAPEL_SISWA,
      page: () => MapelSiswaView(),
      binding: MapelSiswaBinding(),
    ),
    GetPage(
      name: _Paths.JURNAL_AJAR_HARIAN,
      page: () => JurnalAjarHarianView(),
      binding: JurnalAjarHarianBinding(),
    ),
    GetPage(
      name: _Paths.INPUT_INFO_SEKOLAH,
      page: () => const InputInfoSekolahView(),
      binding: InputInfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.TAMPILKAN_INFO_SEKOLAH,
      page: () => TampilkanInfoSekolahView(),
      binding: TampilkanInfoSekolahBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA_PERKELAS,
      page: () => DaftarSiswaPerkelasView(),
      binding: DaftarSiswaPerkelasBinding(),
    ),
    GetPage(
      name: _Paths.INPUT_CATATAN_KHUSUS_SISWA,
      page: () => InputCatatanKhususSiswaView(),
      binding: InputCatatanKhususSiswaBinding(),
    ),
    GetPage(
      name: _Paths.TANGGAPAN_CATATAN_KHUSUS_SISWA,
      page: () => TanggapanCatatanKhususSiswaView(),
      binding: TanggapanCatatanKhususSiswaBinding(),
    ),
    GetPage(
      name: _Paths.TANGGAPAN_CATATAN_KHUSUS_SISWA_WALIKELAS,
      page: () => TanggapanCatatanKhususSiswaWalikelasView(),
      binding: TanggapanCatatanKhususSiswaWalikelasBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA_PERMAPEL,
      page: () => DaftarSiswaPermapelView(),
      binding: DaftarSiswaPermapelBinding(),
    ),
    GetPage(
      name: _Paths.PEMBAYARAN_SPP,
      page: () => PembayaranSppView(),
      binding: PembayaranSppBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_HALAQOHNYA,
      page: () => DaftarHalaqohnyaView(),
      binding: DaftarHalaqohnyaBinding(),
    ),
    GetPage(
      name: _Paths.JADWAL_PELAJARAN,
      page: () => const JadwalPelajaranView(),
      binding: JadwalPelajaranBinding(),
    ),
    GetPage(
      name: _Paths.BUAT_JADWAL_PELAJARAN,
      page: () => const BuatJadwalPelajaranView(),
      binding: BuatJadwalPelajaranBinding(),
    ),
    GetPage(
      name: _Paths.BUAT_SARPRAS,
      page: () => const BuatSarprasView(),
      binding: BuatSarprasBinding(),
    ),
    GetPage(
      name: _Paths.DATA_SARPRAS,
      page: () => const DataSarprasView(),
      binding: DataSarprasBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_EKSKUL,
      page: () => const DaftarEkskulView(),
      binding: DaftarEkskulBinding(),
    ),
    GetPage(
      name: _Paths.TANGGAPAN_CATATAN,
      page: () => const TanggapanCatatanView(),
      binding: TanggapanCatatanBinding(),
    ),
    GetPage(
      name: _Paths.REKAPITULASI_PEMBAYARAN,
      page: () => const RekapitulasiPembayaranView(),
      binding: RekapitulasiPembayaranBinding(),
    ),
    GetPage(
      name: _Paths.REKAPITULASI_PEMBAYARAN_RINCI,
      page: () => const RekapitulasiPembayaranRinciView(),
      binding: RekapitulasiPembayaranRinciBinding(),
    ),
    GetPage(
      name: _Paths.IMPORT_SISWA_EXCEL,
      page: () => const ImportSiswaExcelView(),
      binding: ImportSiswaExcelBinding(),
    ),
    GetPage(
      name: _Paths.CATATAN_SISWA,
      page: () => const CatatanSiswaView(),
      binding: CatatanSiswaBinding(),
    ),
    GetPage(
      name: _Paths.KALENDER_AKADEMIK,
      page: () => const KalenderAkademikView(),
      binding: KalenderAkademikBinding(),
    ),
    GetPage(
      name: _Paths.INPUT_EKSKUL,
      page: () => const InputEkskulView(),
      binding: InputEkskulBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_JURNAL_AJAR,
      page: () => const DaftarJurnalAjarView(),
      binding: DaftarJurnalAjarBinding(),
    ),
    GetPage(
      name: _Paths.ABSENSI,
      page: () => const AbsensiPage(),
      binding: AbsensiBinding(),
    ),
    GetPage(
      name: _Paths.PERANGKAT_AJAR,
      page: () => const PerangkatAjarView(),
      binding: PerangkatAjarBinding(),
    ),
    GetPage(
      name: _Paths.ATP_FORM,
      page: () => const AtpFormView(),
      binding: AtpFormBinding(),
    ),
    GetPage(
      name: _Paths.MODUL_AJAR_FORM,
      page: () => const ModulAjarFormView(),
      binding: ModulAjarFormBinding(),
    ),
    GetPage(
      name: _Paths.PROTA_PROSEM,
      page: () => const ProtaProsemView(),
      binding: ProtaProsemBinding(),
    ),
    GetPage(
      name: _Paths.IMPORT_PEGAWAI,
      page: () => const ImportPegawaiView(),
      binding: ImportPegawaiBinding(),
    ),
    GetPage(
      name: _Paths.INPUT_NILAI_SISWA,
      page: () => const InputNilaiSiswaView(),
      binding: InputNilaiSiswaBinding(),
    ),
    GetPage(
      name: _Paths.RAPOR_SISWA,
      page: () => const RaporSiswaView(),
      binding: RaporSiswaBinding(),
    ),
    GetPage(
      name: _Paths.KELAS_TAHFIDZ,
      page: () => const KelasTahfidzView(),
      binding: KelasTahfidzBinding(),
    ),
    GetPage(
      name: _Paths.REKAP_JURNAL_GURU,
      page: () => const RekapJurnalGuruView(),
      binding: RekapJurnalGuruBinding(),
    ),
    GetPage(
      name: _Paths.REKAP_JURNAL_ADMIN,
      page: () => const RekapJurnalAdminView(),
      binding: RekapJurnalAdminBinding(),
    ),
    GetPage(
      name: _Paths.LAKSANAKAN_UJIAN,
      page: () => const LaksanakanUjianView(),
      binding: LaksanakanUjianBinding(),
    ),
    GetPage(
      name: _Paths.REKAP_ABSENSI,
      page: () => const RekapAbsensiView(),
      binding: RekapAbsensiBinding(),
    ),
    // GetPage(
    //   name: _Paths.ANALISIS_AKADEMIK,
    //   page: () => const AnalisisAkademikPage(),
    //   binding: AnalisisAkademikBinding(),
    // ),
    GetPage(
      name: _Paths.MANAJEMEN_JABATAN,
      page: () => const ManajemenJabatanView(),
      binding: ManajemenJabatanBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_TUGAS,
      page: () => const ManajemenTugasView(),
      binding: ManajemenTugasBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_PEGAWAI,
      page: () => const DaftarPegawaiView(),
      binding: DaftarPegawaiBinding(),
    ),
    GetPage(
      name: _Paths.PANTAU_TAHFIDZ,
      page: () => const PantauTahfidzView(),
      binding: PantauTahfidzBinding(),
    ),
    GetPage(
      name: _Paths.ATUR_PENGGANTI,
      page: () => const AturPenggantiView(),
      binding: AturPenggantiBinding(),
    ),
    GetPage(
      name: _Paths.HALAMAN_PENGGANTI,
      page: () => const HalamanPenggantiView(),
      binding: HalamanPenggantiBinding(),
    ),
    GetPage(
      name: _Paths.KURIKULUM_MASTER,
      page: () => const KurikulumMasterView(),
      binding: KurikulumMasterBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_INFORMASI,
      page: () => const DaftarInformasiView(),
      binding: DaftarInformasiBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_JAM,
      page: () => const ManajemenJamView(),
      binding: ManajemenJamBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_EKSKUL,
      page: () => const ManajemenEkskulView(),
      binding: ManajemenEkskulBinding(),
    ),
    GetPage(
      name: _Paths.GURU_PENGGANTI,
      page: () => const GuruPenggantiView(),
      binding: GuruPenggantiBinding(),
    ),
    GetPage(
      name: _Paths.SPESIALISASI,
      page: () => const SpesialisasiView(),
      binding: SpesialisasiBinding(),
    ),
    GetPage(
      name: _Paths.PEMBINA_EKSTERNAL,
      page: () => const PembinaEksternalView(),
      binding: PembinaEksternalBinding(),
    ),
    GetPage(
      name: _Paths.MASTER_EKSKUL,
      page: () => const MasterEkskulView(),
      binding: MasterEkskulBinding(),
    ),
    GetPage(
      name: _Paths.INSTANCE_EKSKUL,
      page: () => const InstanceEkskulView(),
      binding: InstanceEkskulBinding(),
    ),
    GetPage(
      name: _Paths.DASBOR_PEMBINA,
      page: () => const DasborPembinaView(),
      binding: DasborPembinaBinding(),
    ),
    GetPage(
      name: _Paths.PEMBINA_EKSKUL_DETAIL,
      page: () {
        // Ambil nama ekskul dari argumen untuk ditampilkan di AppBar
        final String namaEkskul = Get.arguments['namaEkskul'];
        return PembinaEkskulDetailView(namaEkskul: namaEkskul);
      },
      binding: PembinaEkskulDetailBinding(),
    ),
    GetPage(
      name: _Paths.LAPORAN_EKSKUL, // <-- Rute yang baru
      page: () => const LaporanEkskulView(),
      binding: LaporanEkskulBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_TAHUN_AJARAN_EKSKUL, // <-- Rute yang baru
      page: () => const ManajemenTahunAjaranEkskulView(),
      binding: ManajemenTahunAjaranEkskulBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_TAHUN_AJARAN_EKSKUL, // <-- Rute yang baru
      page: () => const ManajemenTahunAjaranEkskulView(),
      binding: ManajemenTahunAjaranEkskulBinding(),
    ),
    GetPage(
      name: _Paths.PENILAIAN_RAPOR_EKSKUL, // <-- Rute yang baru
      page: () => const PenilaianRaporEkskulView(),
      binding: PenilaianRaporEkskulBinding(),
    ),
    GetPage(
      name: _Paths.RAPOR_EKSKUL_SISWA,
      page: () => const RaporEkskulView(),
      binding: RaporEkskulSiswaBinding(), // Gunakan binding yang sudah dikoreksi
    ),
    GetPage(
      name: _Paths.RAPOR_TERPADU,
      page: () => const RaporTerpaduView(),
      binding: RaporTerpaduBinding(), // Gunakan binding yang sudah dikoreksi
    ),
    GetPage(
      // name: _Paths.LOG_EKSKUL_SISWA, // Buat path baru ini
      name: _Paths.LOG_EKSKUL_SISWA, // <-- Rute yang baru
      page: () => const LogEkskulSiswaView(),
      binding: LogEkskulSiswaBinding(),
    ),
    GetPage(
      name: _Paths.KELOLA_CATATAN_RAPOR,
      page: () => const KelolaCatatanRaporView(),
      binding: KelolaCatatanRaporBinding(),
    ),
    GetPage(
      name: _Paths.PENILAIAN_RAPOR_HALAQOH,
      page: () => const PenilaianRaporHalaqohView(),
      binding: PenilaianRaporHalaqohBinding(),
    ),
  ];
}
