import 'package:get/get.dart';

import '../modules/buat_jadwal_pelajaran/bindings/buat_jadwal_pelajaran_binding.dart';
import '../modules/buat_jadwal_pelajaran/views/buat_jadwal_pelajaran_view.dart';
import '../modules/buat_sarpras/bindings/buat_sarpras_binding.dart';
import '../modules/buat_sarpras/views/buat_sarpras_view.dart';
import '../modules/daftar_halaqoh/bindings/daftar_halaqoh_binding.dart';
import '../modules/daftar_halaqoh/views/daftar_halaqoh_view.dart';
import '../modules/daftar_halaqoh_pengampu/bindings/daftar_halaqoh_pengampu_binding.dart';
import '../modules/daftar_halaqoh_pengampu/views/daftar_halaqoh_pengampu_view.dart';
import '../modules/daftar_halaqoh_perfase/bindings/daftar_halaqoh_perfase_binding.dart';
import '../modules/daftar_halaqoh_perfase/views/daftar_halaqoh_perfase_view.dart';
import '../modules/daftar_halaqohnya/bindings/daftar_halaqohnya_binding.dart';
import '../modules/daftar_halaqohnya/views/daftar_halaqohnya_view.dart';
import '../modules/daftar_kelas/bindings/daftar_kelas_binding.dart';
import '../modules/daftar_kelas/views/daftar_kelas_view.dart';
import '../modules/daftar_nilai/bindings/daftar_nilai_binding.dart';
import '../modules/daftar_nilai/views/daftar_nilai_view.dart';
import '../modules/daftar_siswa_perkelas/bindings/daftar_siswa_perkelas_binding.dart';
import '../modules/daftar_siswa_perkelas/views/daftar_siswa_perkelas_view.dart';
import '../modules/daftar_siswa_permapel/bindings/daftar_siswa_permapel_binding.dart';
import '../modules/daftar_siswa_permapel/views/daftar_siswa_permapel_view.dart';
import '../modules/daftar_siswa_pindah_halaqoh/bindings/daftar_siswa_pindah_halaqoh_binding.dart';
import '../modules/daftar_siswa_pindah_halaqoh/views/daftar_siswa_pindah_halaqoh_view.dart';
import '../modules/data_sarpras/bindings/data_sarpras_binding.dart';
import '../modules/data_sarpras/views/data_sarpras_view.dart';
import '../modules/detail_nilai_halaqoh/bindings/detail_nilai_halaqoh_binding.dart';
import '../modules/detail_nilai_halaqoh/views/detail_nilai_halaqoh_view.dart';
import '../modules/detail_siswa/bindings/detail_siswa_binding.dart';
import '../modules/detail_siswa/views/detail_siswa_view.dart';
import '../modules/forgot_password/bindings/forgot_password_binding.dart';
import '../modules/forgot_password/views/forgot_password_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/input_catatan_khusus_siswa/bindings/input_catatan_khusus_siswa_binding.dart';
import '../modules/input_catatan_khusus_siswa/views/input_catatan_khusus_siswa_view.dart';
import '../modules/input_info_sekolah/bindings/input_info_sekolah_binding.dart';
import '../modules/input_info_sekolah/views/input_info_sekolah_view.dart';
import '../modules/jadwal_pelajaran/bindings/jadwal_pelajaran_binding.dart';
import '../modules/jadwal_pelajaran/views/jadwal_pelajaran_view.dart';
import '../modules/jurnal_ajar_harian/bindings/jurnal_ajar_harian_binding.dart';
import '../modules/jurnal_ajar_harian/views/jurnal_ajar_harian_view.dart';
import '../modules/kelompok_halaqoh/bindings/kelompok_halaqoh_binding.dart';
import '../modules/kelompok_halaqoh/views/kelompok_halaqoh_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/mapel_siswa/bindings/mapel_siswa_binding.dart';
import '../modules/mapel_siswa/views/mapel_siswa_view.dart';
import '../modules/new_password/bindings/new_password_binding.dart';
import '../modules/new_password/views/new_password_view.dart';
import '../modules/pembayaran_spp/bindings/pembayaran_spp_binding.dart';
import '../modules/pembayaran_spp/views/pembayaran_spp_view.dart';
import '../modules/pemberian_guru_mapel/bindings/pemberian_guru_mapel_binding.dart';
import '../modules/pemberian_guru_mapel/views/pemberian_guru_mapel_view.dart';
import '../modules/pemberian_kelas_siswa/bindings/pemberian_kelas_siswa_binding.dart';
import '../modules/pemberian_kelas_siswa/views/pemberian_kelas_siswa_view.dart';
import '../modules/pemberian_nilai_halaqoh/bindings/pemberian_nilai_halaqoh_binding.dart';
import '../modules/pemberian_nilai_halaqoh/views/pemberian_nilai_halaqoh_view.dart';
import '../modules/tambah_kelompok_mengaji/bindings/tambah_kelompok_mengaji_binding.dart';
import '../modules/tambah_kelompok_mengaji/views/tambah_kelompok_mengaji_view.dart';
import '../modules/tambah_pegawai/bindings/tambah_pegawai_binding.dart';
import '../modules/tambah_pegawai/views/tambah_pegawai_view.dart';
import '../modules/tambah_siswa/bindings/tambah_siswa_binding.dart';
import '../modules/tambah_siswa/views/tambah_siswa_view.dart';
import '../modules/tampilkan_info_sekolah/bindings/tampilkan_info_sekolah_binding.dart';
import '../modules/tampilkan_info_sekolah/views/tampilkan_info_sekolah_view.dart';
import '../modules/tanggapan_catatan_khusus_siswa/bindings/tanggapan_catatan_khusus_siswa_binding.dart';
import '../modules/tanggapan_catatan_khusus_siswa/views/tanggapan_catatan_khusus_siswa_view.dart';
import '../modules/tanggapan_catatan_khusus_siswa_walikelas/bindings/tanggapan_catatan_khusus_siswa_walikelas_binding.dart';
import '../modules/tanggapan_catatan_khusus_siswa_walikelas/views/tanggapan_catatan_khusus_siswa_walikelas_view.dart';

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
  ];
}
