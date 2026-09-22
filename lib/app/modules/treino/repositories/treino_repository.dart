import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/aluno_model.dart';
import '../models/treino_model.dart';

class TreinoRepository {
  static const String baseUrl = 'http://localhost:3000/api';

  // --- BUSCAR ALUNOS (PARA O PERSONAL TRAINER) ---
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

  // --- BUSCAR TREINOS DE UM USUÁRIO ---
  static Future<List<FichaTreino>> getTreinosPorUsuario(String usuarioId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/treinos?usuario_id=$usuarioId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => FichaTreino(
          id: item['id'].toString(),
          identificador: item['dia_semana'] ?? 'TREINO',
          titulo: item['titulo'] ?? '',
          descricao: item['descricao'] ?? '',
          exercicios: [],
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- SALVAR NOVO TREINO ---
  static Future<bool> criarTreino({
    required String usuarioId,
    required String titulo,
    required String descricao,
    required String diaSemana,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/treinos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': usuarioId,
          'titulo': titulo,
          'descricao': descricao,
          'dia_semana': diaSemana,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- EXCLUIR TREINO ---
  static Future<bool> deletarTreino(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/treinos?id=$id'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}