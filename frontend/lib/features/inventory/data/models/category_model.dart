class Categoria {
  final int id;
  final String nombre;
  final String? tipo;
  final String? descripcion;

  Categoria({
    required this.id,
    required this.nombre,
    this.tipo,
    this.descripcion,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Categoria(
      id: parseInt(json['categoria_id']) ?? 0,
      nombre: json['categoria_nombre'],
      tipo: json['categoria_tipo'],
      descripcion: json['categoria_descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoria_id': id,
      'categoria_nombre': nombre,
      'categoria_tipo': tipo,
      'categoria_descripcion': descripcion,
    };
  }
}
