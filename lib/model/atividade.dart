class Atividade {
  final int passos;
  final DateTime data;

  Atividade({
    required this.passos,
    required this.data,
  });

  // Converte Map para Atividade
  factory Atividade.fromMap(Map<String, dynamic> map) {
    return Atividade(
      passos: map['passos'] as int,
      data: DateTime.parse(map['data'] as String),
    );
  }

  // Converte Atividade para Map
  Map<String, dynamic> toMap() {
    return {
      'passos': passos,
      'data': data.toIso8601String(),
    };
  }
}