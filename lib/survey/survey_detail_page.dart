import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_3/sreens/splash/auth/login_page.dart';
import 'package:flutter_application_3/survey/survey_form_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SurveyDetailPage extends StatefulWidget {
  final int surveyId;

  const SurveyDetailPage({super.key, required this.surveyId});

  @override
  State<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends State<SurveyDetailPage> {
  // ============================================================
  // 1. STATE VARIABEL HALAMAN
  // ============================================================
  Map<String, dynamic>? survey;
  bool isLoading = true;
  String? errorMessage;
  Uint8List? imageBytes;
  bool isLoadingImage = false;

  // Palet Warna Baru: Teal & Emerald (Senada dengan halaman daftar survey)
  static const Color primaryColor = Color(0xFF0D9488); // Teal Modern
  static const Color primaryDarkColor = Color(0xFF0F766E);
  static const Color primaryLightColor = Color(0xFFCCFBF1);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color dangerColor = Color(0xFFEF4444);

  // ============================================================
  // 2. LIFECYCLE
  // ============================================================
  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  // Helper: Navigasi ke halaman Login jika token habis/invalid
  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // ============================================================
  // 3. REST API: MENGAMBIL DETAIL SURVEY
  // ============================================================
  Future<void> fetchDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      imageBytes = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        _redirectToLogin();
        return;
      }

      final url = Uri.parse('https://sijala.biz.id/api/v1/surveys/${widget.surveyId}');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');
        _redirectToLogin();
        return;
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == true && result['data'] != null) {
          final data = Map<String, dynamic>.from(result['data']);
          setState(() {
            survey = data;
            isLoading = false;
          });

          final photoName = data['photo']?.toString();
          if (photoName != null && photoName.isNotEmpty && photoName != 'placeholder.jpg') {
            fetchImage(photoName, token);
          }
          return;
        }
      }

      throw Exception('Survey tidak ditemukan (Kode: ${response.statusCode})');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat detail survey. Periksa koneksi Anda.';
      });
    }
  }

  // ============================================================
  // 4. REST API: MENGAMBIL FOTO SURVEY
  // ============================================================
  Future<void> fetchImage(String photoName, String token) async {
    setState(() => isLoadingImage = true);

    try {
      final fileName = photoName.contains('/') ? photoName.split('/').last : photoName;
      final url = Uri.parse('https://sijala.biz.id/api/image/$fileName');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          imageBytes = response.bodyBytes;
          isLoadingImage = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => isLoadingImage = false);
    }
  }

  // ============================================================
  // 5. REST API: MENGHAPUS SURVEY (DELETE)
  // ============================================================
  Future<void> deleteSurvey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Survey', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        content: const Text('Apakah Anda yakin ingin menghapus survey ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('https://sijala.biz.id/api/v1/surveys/${widget.surveyId}/delete'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnackBar('Survey berhasil dihapus', const Color(0xFF10B981));
        Navigator.pop(context, true);
      } else {
        _showSnackBar('Gagal menghapus survey (Kode: ${response.statusCode})', dangerColor);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Terjadi kesalahan saat menghapus survey.', dangerColor);
    }
  }

  // ============================================================
  // 6. NAVIGASI KE FORM EDIT SURVEY
  // ============================================================
  Future<void> editSurvey() async {
    if (survey == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyFormPage(survey: survey),
      ),
    );

    if (result == true && mounted) {
      fetchDetail();
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============================================================
  // 7. HELPER: BUKA MAPS & SALIN KOORDINAT & ZOOM GAMBAR
  // ============================================================
  Future<void> openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      _showSnackBar('Tidak dapat membuka Google Maps', dangerColor);
    }
  }

  void copyCoordinates(double lat, double lng) {
    Clipboard.setData(ClipboardData(text: '$lat, $lng'));
    _showSnackBar('Koordinat berhasil disalin!', primaryColor);
  }

  void showFullImageDialog(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 8. BUILD TAMPILAN WIDGET (UI)
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: AppBar(
          title: const Text(
            'Detail Survey',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
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
          centerTitle: true,
          actions: [
            if (survey != null) ...[
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                tooltip: 'Edit Survey',
                onPressed: editSurvey,
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.white70),
                tooltip: 'Hapus Survey',
                onPressed: deleteSurvey,
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
      // MEMBATASI LEBAR DI WEB AGAR RAPI DI TENGAH
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: buildBody(),
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor, strokeWidth: 3.5),
            SizedBox(height: 16),
            Text('Memuat detail survey...', style: TextStyle(color: textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    if (errorMessage != null || survey == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, size: 48, color: dangerColor),
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Survey tidak ditemukan',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: textDark, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: fetchDetail,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final title = survey!['title']?.toString() ?? '-';
    final description = survey!['description']?.toString() ?? 'Tidak ada deskripsi.';
    final category = survey!['category_name']?.toString() ??
        survey!['category']?['name']?.toString() ??
        'Tanpa Kategori';
    final date = survey!['created_at']?.toString() ?? '-';
    final lat = double.tryParse(survey!['latitude']?.toString() ?? '');
    final lng = double.tryParse(survey!['longitude']?.toString() ?? '');
    final hasValidCoords = lat != null && lng != null;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: fetchDetail,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoCard(category, title, date),
          const SizedBox(height: 16),
          _buildPhotoCard(),
          const SizedBox(height: 16),
          _buildDescriptionCard(description),
          const SizedBox(height: 16),
          _buildMapCard(hasValidCoords, lat, lng),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- KOMPONEN KARTU TAMPILAN (MODULAR) ---

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }

  Widget _buildInfoCard(String category, String title, String date) {
    return _buildCardContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: textMuted),
                const SizedBox(width: 6),
                Text(
                  'Waktu: $date',
                  style: const TextStyle(
                    fontSize: 13,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    return _buildCardContainer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Text(
                'Foto Survey',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ),
            if (isLoadingImage)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: primaryColor)),
              )
            else if (imageBytes != null)
              GestureDetector(
                onTap: () => showFullImageDialog(imageBytes!),
                child: Container(
                  color: Colors.black.withOpacity(0.03),
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 200,
                    maxHeight: 380, // Membatasi tinggi maksimum agar proporsional
                  ),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Center(
                        child: Image.memory(
                          imageBytes!,
                          fit: BoxFit.contain, // DIPERBAIKI: Foto tampil utuh tanpa terpotong/gepeng
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Ketuk untuk memperbesar', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 140,
                width: double.infinity,
                color: const Color(0xFFF8FAFC),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined, color: Color(0xFFCBD5E1), size: 32),
                    SizedBox(height: 8),
                    Text('Tidak ada foto survey', style: TextStyle(color: textMuted, fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return _buildCardContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deskripsi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard(bool hasValidCoords, double? lat, double? lng) {
    return _buildCardContainer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryLightColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: primaryColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lokasi Survey',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasValidCoords ? '$lat, $lng' : 'Koordinat tidak tersedia',
                          style: const TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hasValidCoords && lat != null && lng != null) ...[
              SizedBox(
                height: 220,
                width: double.infinity,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flutter_application_3',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat, lng),
                          width: 48,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: dangerColor,
                            size: 38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => copyCoordinates(lat, lng),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Salin Koordinat', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => openGoogleMaps(lat, lng),
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: const Text('Buka Maps', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Container(
                height: 140,
                width: double.infinity,
                color: const Color(0xFFF8FAFC),
                child: const Center(
                  child: Text(
                    'Peta tidak tersedia (koordinat kosong)',
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}