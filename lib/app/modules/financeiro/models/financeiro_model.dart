enum StatusPagamento { pago, pendente, atrasado }

class Fatura {
  final String id;
  final int usuarioId;
  final String? alunoNome;
  final String descricao;
  final double valor;
  final DateTime dataVencimento;
  final DateTime? dataPagamento;
  final StatusPagamento status;
  final String? formaPagamento;

  Fatura({
    required this.id,
    required this.usuarioId,
    this.alunoNome,
    required this.descricao,
    required this.valor,
    required this.dataVencimento,
    this.dataPagamento,
    required this.status,
    this.formaPagamento,
  });

  factory Fatura.fromJson(Map<String, dynamic> json) {
    StatusPagamento parseStatus(String statusStr) {
      switch (statusStr.toUpperCase()) {
        case 'PAGO':
          return StatusPagamento.pago;
        case 'ATRASADO':
          return StatusPagamento.atrasado;
        default:
          return StatusPagamento.pendente;
      }
    }

    return Fatura(
      id: json['id'].toString(),
      usuarioId: json['usuario_id'] is int ? json['usuario_id'] : int.parse(json['usuario_id'].toString()),
      alunoNome: json['aluno_nome'],
      descricao: json['mes_referencia'] ?? 'Mensalidade',
      valor: double.tryParse(json['valor'].toString()) ?? 0.0,
      dataVencimento: json['data_pagamento'] != null 
          ? DateTime.parse(json['data_pagamento']) 
          : DateTime.now(),
      dataPagamento: json['data_pagamento'] != null 
          ? DateTime.parse(json['data_pagamento']) 
          : null,
      status: parseStatus(json['status'] ?? 'PENDENTE'),
      formaPagamento: 'Pix / Cartão',
    );
  }
}

class PlanoAssinatura {
  final String nome;
  final double valorMensal;
  final String ciclo;
  final DateTime proximaRenovacao;
  final bool ativo;

  PlanoAssinatura({
    required this.nome,
    required this.valorMensal,
    required this.ciclo,
    required this.proximaRenovacao,
    required this.ativo,
  });
}