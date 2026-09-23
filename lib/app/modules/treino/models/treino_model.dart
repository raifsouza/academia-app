class Exercicio {
  final String id;
  final String nome;
  final String grupoMuscular;
  final int series;
  final String repeticoes;
  final double cargaKg;
  final int descansoSegundos;
  bool concluido;

  Exercicio({
    required this.id,
    required this.nome,
    required this.grupoMuscular,
    required this.series,
    required this.repeticoes,
    required this.cargaKg,
    required this.descansoSegundos,
    this.concluido = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'grupo_muscular': grupoMuscular,
      'series': series,
      'repeticoes': repeticoes,
      'carga_kg': cargaKg,
      'descanso_segundos': descansoSegundos,
      'concluido': concluido ? 1 : 0,
    };
  }

  factory Exercicio.fromJson(Map<String, dynamic> json) {
    return Exercicio(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      grupoMuscular: json['grupo_muscular']?.toString() ?? 'Geral',
      series: int.tryParse(json['series']?.toString() ?? '') ?? 3,
      repeticoes: json['repeticoes']?.toString() ?? '12',
      cargaKg: double.tryParse(json['carga_kg']?.toString() ?? '') ?? 0.0,
      descansoSegundos: int.tryParse(json['descanso_segundos']?.toString() ?? '') ?? 60,
      concluido: json['concluido'] == 1 || json['concluido'] == true,
    );
  }
}

class FichaTreino {
  final String id;
  final String identificador;
  final String titulo;
  final String descricao;
  final List<Exercicio> exercicios;

  FichaTreino({
    required this.id,
    required this.identificador,
    required this.titulo,
    required this.descricao,
    required this.exercicios,
  });

  factory FichaTreino.fromJson(Map<String, dynamic> json) {
    // Mapeamento seguro da lista de exercícios
    var listEx = json['exercicios'] as List<dynamic>? ?? [];
    List<Exercicio> listaExercicios = listEx
        .map((e) => Exercicio.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return FichaTreino(
      id: json['id']?.toString() ?? '',
      // Mapeia dia_semana retornado pelo banco de dados para o campo identificador
      identificador: json['dia_semana']?.toString() ?? json['identificador']?.toString() ?? 'Geral',
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      exercicios: listaExercicios,
    );
  }
}