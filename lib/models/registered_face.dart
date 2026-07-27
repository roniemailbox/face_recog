/// A face registered in the database with its embedding and metadata.
class RegisteredFace {
  final String id;
  final String name;
  final List<double> embedding;
  final DateTime registeredAt;

  const RegisteredFace({
    required this.id,
    required this.name,
    required this.embedding,
    required this.registeredAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'embedding': embedding,
        'registeredAt': registeredAt.toIso8601String(),
      };

  factory RegisteredFace.fromJson(Map<String, dynamic> json) => RegisteredFace(
        id: json['id'] as String,
        name: json['name'] as String,
        embedding: (json['embedding'] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList(),
        registeredAt: DateTime.parse(json['registeredAt'] as String),
      );
}
