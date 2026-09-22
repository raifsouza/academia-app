class Exercicio {
  final String id;
  final String nome;
  final String grupoMuscular; // Ex: Peitoral, Tríceps, Dorsal
  final int series;
  final String repeticoes;    // Ex: "10-12" ou "12"
  final double cargaKg;
  final int descansoSegundos;
  final String? observacoes;
  bool concluido;

  Exercicio({
    required this.id,
    required this.nome,
    required this.grupoMuscular,
    required this.series,
    required this.repeticoes,
    required this.cargaKg,
    required this.descansoSegundos,
    this.observacoes,
    this.concluido = false,
  });
}

class FichaTreino {
  final String id;
  final String identificador; // Ex: "TREINO A", "TREINO B"
  final String titulo;        // Ex: "Peitoral & Tríceps"
  final String descricao;
  final List<Exercicio> exercicios;

  FichaTreino({
    required this.id,
    required this.identificador,
    required this.titulo,
    required this.descricao,
    required this.exercicios,
  });
}