class Aluno {
  final String id;
  final String nome;
  final String fotoUrl;
  final String plano;
  final String matricula;
  final bool realizouAvaliacao;
  final bool aulaExperimentalRealizada;
  final String statusAluno; // 'ATIVO' ou 'INATIVO'

  Aluno({
    required this.id,
    required this.nome,
    required this.fotoUrl,
    required this.plano,
    required this.matricula,
    required this.realizouAvaliacao,
    required this.aulaExperimentalRealizada,
    required this.statusAluno,
  });

  factory Aluno.fromJson(Map<String, dynamic> json) {
    return Aluno(
      id: json['id'].toString(),
      nome: json['nome'] ?? '',
      fotoUrl: json['foto_url'] ?? '',
      plano: json['plano'] ?? 'Power Member',
      matricula: json['matricula'] ?? '',
      realizouAvaliacao: json['realizou_avaliacao'] == 1,
      aulaExperimentalRealizada: json['status_aula_experimental'] == 1,
      statusAluno: json['status_aluno'] ?? 'ATIVO',
    );
  }
}