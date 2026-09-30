import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/sreens/splash/auth/login_page.dart';
import 'package:flutter_application_3/survey/survey_detail_page.dart';
import 'package:flutter_application_3/survey/survey_form_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  // ============================================================
  // 1. STATE / VARIABEL HALAMAN
  // ============================================================

  List<Map<String, dynamic>> surveys = [];
  bool isLoading = true;
  String? errorMessage;

  final String apiUrl = 'https://sijala.biz.id/api/v1/surveys';

  // Tema Warna Baru: Emerald & Teal (Segar & Elegan, Bukan Ungu)
  static const Color primaryColor = Color(0xFF0D9488); // Teal Modern
  static const Color primaryDarkColor = Color(0xFF0F766E);
  static const Color primaryLightColor = Color(0xFFCCFBF1);
  static const Color accentColor = Color(0xFF14B8A6);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  // ============================================================
  // 2. LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    fetchSurveys();
  }

  // ============================================================
  // 3. REST API: MENGAMBIL DAFTAR SURVEY (GET)
  // ============================================================

  Future<void> fetchSurveys() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == true && data['data'] is List) {
          final List rawList = data['data'];

          setState(() {
            surveys = rawList
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            isLoading = false;
          });
          return;
        }
      }

      throw Exception('Gagal memuat data (Kode: ${response.statusCode})');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi Anda.';
      });
    }
  }

  // ============================================================
  // 4. NAVIGASI
  // ============================================================

  Future<void> openDetail(int surveyId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyDetailPage(surveyId: surveyId),
      ),
    );

    if (result == true && mounted) {
      fetchSurveys();
    }
  }

  Future<void> openAddSurvey() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SurveyFormPage(),
      ),
    );

    if (result == true && mounted) {
      fetchSurveys();
    }
  }

  // ============================================================
  // 5. HELPER FORMAT DATA
  // ============================================================

  String getCategoryName(Map<String, dynamic> survey) {
    if (survey['category_name'] != null &&
        survey['category_name'].toString().isNotEmpty) {
      return survey['category_name'].toString();
    }
    if (survey['category'] is Map && survey['category']['name'] != null) {
      return survey['category']['name'].toString();
    }
    return 'Umum';
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr.replaceFirst(' ', 'T'));
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  // ============================================================
  // 6. BUILD TAMPILAN WIDGET (UI)
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: AppBar(
          title: const Column(
            children: [
              Text(
                'Daftar Survey Lapangan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 0.3),
              ),
              SizedBox(height: 3),
              Text(
                'Kelola, pantau, dan perbarui data survey Anda',
                style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 4,
          shadowColor: Colors.teal.withOpacity(0.3),
          centerTitle: true,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: RefreshIndicator(
            color: primaryColor,
            onRefresh: fetchSurveys,
            child: buildBody(),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton.extended(
          onPressed: openAddSurvey,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          icon: const Icon(Icons.add_task_rounded, size: 22),
          label: const Text(
            'Tambah Survey',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    // 1. Kondisi Loading
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3.5,
            ),
            SizedBox(height: 16),
            Text(
              'Memuat data survey...',
              style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // 2. Kondisi Error
    if (errorMessage != null && surveys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Gagal Memuat Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textMuted, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: fetchSurveys,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Kondisi Data Kosong
    if (surveys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: primaryLightColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum Ada Data Survey',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mulai buat catatan survey lapangan pertama Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: openAddSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Survey Baru', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Kondisi Ada Data: Card Kaya Visual & Tidak Terlihat Kosong
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      itemCount: surveys.length,
      itemBuilder: (context, index) {
        final survey = surveys[index];
        final id = int.tryParse(survey['id']?.toString() ?? '') ?? 0;
        final title = survey['title']?.toString() ?? '-';
        final description = survey['description']?.toString() ?? '-';
        final category = getCategoryName(survey);
        final date = formatDate(survey['created_at']?.toString());
        final lat = survey['latitude']?.toString() ?? '';
        final lng = survey['longitude']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openDetail(id),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Aksen Garis Vertikal di Sisi Kiri Card agar Estetik
                      Container(
                        width: 6,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Baris Atas: Kategori dengan Ikon Mini & Panah
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: primaryLightColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.bookmark_rounded, size: 12, color: primaryDarkColor),
                                        const SizedBox(width: 5),
                                        Text(
                                          category.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: primaryDarkColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Judul Survey
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Deskripsi Survey
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: textMuted,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 16),
                              const Divider(color: Color(0xFFF1F5F9), height: 1),
                              const SizedBox(height: 12),

                              // Baris Bawah: Informasi Koordinat & Tanggal dengan Box Kecil Supaya Tidak Kosong
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, size: 13, color: primaryColor),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              (lat.isNotEmpty && lng.isNotEmpty)
                                                  .toString() == 'true'
                                                  ? '$lat, $lng'
                                                  : 'Lokasi tidak diatur',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: textMuted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 13, color: textMuted),
                                        const SizedBox(width: 6),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}