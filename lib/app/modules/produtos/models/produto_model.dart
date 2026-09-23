class Produto {
  final int? id;
  final String nome;
  final double preco;
  final int estoque;

  Produto({
    this.id,
    required this.nome,
    required this.preco,
    required this.estoque,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      nome: json['nome'] ?? '',
      preco: double.tryParse(json['preco']?.toString() ?? '0') ?? 0.0,
      estoque: int.tryParse(json['estoque']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'preco': preco,
      'estoque': estoque,
    };
  }
}