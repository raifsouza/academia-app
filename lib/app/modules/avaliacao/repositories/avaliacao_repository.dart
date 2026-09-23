import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../treino/models/aluno_model.dart';

class AvaliacaoRepository {
  // Ajuste a URL base conforme o endereço da sua API Next.js/servidor
  static const String baseUrl = 'http://localhost:3000/api';

  // --- BUSCAR LISTA REAL DE ALUNOS DO BANCO ---
  static Future<List<Aluno>> getAlunos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/alunos'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Aluno.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- BUSCAR AVALIAÇÃO FÍSICA DO ALUNO ---
  static Future<Map<String, dynamic>?> getAvaliacaoPorAluno(String alunoId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/avaliacoes?aluno_id=$alunoId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>; // Retorna a avaliação mais recente
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- BUSCAR A ÚLTIMA AVALIAÇÃO FÍSICA DO ALUNO ---
  static Future<Map<String, dynamic>?> getUltimaAvaliacao(String usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/avaliacoes?aluno_id=$usuarioId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          // Retorna a última avaliação cadastrada (a primeira da lista se estiver em ORDER BY id DESC)
          return data.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Erro ao buscar avaliação física: $e');
      return null;
    }
  }


  // --- SALVAR/ATUALIZAR AVALIAÇÃO FÍSICA NO BANCO ---
  static Future<bool> salvarAvaliacao(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/avaliacoes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}