class User {
  final int id;
  final int? userId; // ID real en tabla users (cuando viene desde /empleados)
  final String name;
  final String email;

  final String? role;
  final String? phone;
  final String? licenseNumber;
  final String? cargo;
  final String? dependencia;

  User({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    this.role,
    this.phone,
    this.licenseNumber,
    this.cargo,
    this.dependencia,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Soporta tanto respuesta de /users (name) como de /empleados (nombres + apellidos)
    final String nameFromApi = (json['name']?.toString())?.trim() ?? '';
    final String name = nameFromApi.isNotEmpty
        ? nameFromApi
        : '${json['nombres'] ?? ''} ${json['apellidos'] ?? ''}'.trim();

    return User(
      id: parseInt(json['id']) ?? 0,
      userId: parseInt(json['user_id']),
      name: name.isEmpty ? 'Sin nombre' : name,
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString(),
      phone: json['phone']?.toString() ?? json['telefono']?.toString(),
      licenseNumber: json['license_number']?.toString() ?? json['licencia_conduccion']?.toString(),
      cargo: json['cargo']?.toString(),
      dependencia: json['dependencia']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'license_number': licenseNumber,
      'cargo': cargo,
      'dependencia': dependencia,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
