import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../treino/models/aluno_model.dart';
import '../models/financeiro_model.dart';

class FinanceiroRepository {
  static const String _baseUrl = 'http://localhost:3000/api';

  // Busca a lista de alunos cadastrados para o Admin
  static Future<List<Aluno>> getAlunos() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/alunos'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Aluno.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Busca o histórico financeiro individual de um aluno pelo ID
  static Future<List<Fatura>> getHistoricoFaturasAluno(int usuarioId) async {
    final response = await http.get(Uri.parse('$_baseUrl/pagamentos?usuario_id=$usuarioId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Fatura.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar histórico financeiro.');
    }
  }

  // Dar baixa/Confirmar pagamento
  static Future<bool> confirmarPagamentoFatura(String faturaId) async {
    final dataHoje = DateTime.now().toIso8601String().split('T')[0];
    final response = await http.post(
      Uri.parse('$_baseUrl/pagamentos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': faturaId,
        'status': 'PAGO',
        'data_pagamento': dataHoje,
      }),
    );

    return response.statusCode == 200;
  }

  // Registrar pagamento manual
  static Future<bool> registrarPagamento({
    required int usuarioId,
    required double valor,
    required String dataPagamento,
    required String mesReferencia,
    String status = 'PAGO',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pagamentos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuario_id': usuarioId,
        'valor': valor,
        'data_pagamento': dataPagamento,
        'mes_referencia': mesReferencia,
        'status': status,
      }),
    );

    return response.statusCode == 201;
  }

  static PlanoAssinatura getPlanoPadrao() {
    return PlanoAssinatura(
      nome: 'Plano Power',
      valorMensal: 80.00,
      ciclo: 'Mensal',
      proximaRenovacao: DateTime.now().add(const Duration(days: 10)),
      ativo: true,
    );
  }
}