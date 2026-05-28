class Location {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Location({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
    };
  }
}
