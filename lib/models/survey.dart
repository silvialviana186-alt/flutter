class Survey {
  final int id;
  final String title;
  final String description;
  final String categoryName;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryName,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryName: json['category_name'] ??
          json['categoryName'] ??
          '',
      latitude: json['latitude'] != null
          ? double.tryParse(
              json['latitude'].toString(),
            )
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(
              json['longitude'].toString(),
            )
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(
              json['created_at'].toString(),
            )
          : null,
    );
  }

  /// Menampilkan koordinat lokasi
  String get formattedCoordinates {
    if (latitude == null || longitude == null) {
      return 'Lokasi tidak tersedia';
    }

    return '${latitude!.toStringAsFixed(6)}, '
        '${longitude!.toStringAsFixed(6)}';
  }

  /// Menampilkan tanggal survey
  String get formattedDate {
    if (createdAt == null) {
      return 'Tanggal tidak tersedia';
    }

    final day = createdAt!.day
        .toString()
        .padLeft(2, '0');

    final month = createdAt!.month
        .toString()
        .padLeft(2, '0');

    final year = createdAt!.year.toString();

    return '$day/$month/$year';
  }

  get photo => null;
}