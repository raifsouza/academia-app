import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/aluno_model.dart';
import '../models/treino_model.dart';

class TreinoRepository {
  static const String baseUrl = 'http://localhost:3000/api';

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

  // --- BUSCAR TREINOS COM EXERCÍCIOS ---
 static Future<List<FichaTreino>> getTreinosPorUsuario(String usuarioId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/treinos?usuario_id=$usuarioId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => FichaTreino.fromJson(item)).toList();
    }
    return [];
  } catch (e, stackTrace) {
    print('Erro no Parse do Treino: $e');
    print(stackTrace);
    return [];
  }
}

  // --- BUSCAR APENAS O TREINO DO DIA ATUAL DO ALUNO ---
  static Future<FichaTreino?> getTreinoDoDia(String usuarioId) async {
    final treinos = await getTreinosPorUsuario(usuarioId);
    if (treinos.isEmpty) return null;

    final int diaAtualNum = DateTime.now().weekday; // 1 = Segunda, 7 = Domingo

    // Mapeamento numérico do Flutter para a string salva no MySQL
    final Map<int, String> diasMap = {
      1: 'Segunda-Feira',
      2: 'Terça-Feira',
      3: 'Quarta-Feira',
      4: 'Quinta-Feira',
      5: 'Sexta-Feira',
      6: 'Sábado',
      7: 'Domingo',
    };

    final String nomeDiaHoje = diasMap[diaAtualNum] ?? 'Segunda-Feira';

    try {
      // Tenta encontrar o treino onde o dia_semana (mapeado como identificador) corresponda ao dia atual
      return treinos.firstWhere(
        (t) => t.identificador.trim().toLowerCase() == nomeDiaHoje.trim().toLowerCase(),
      );
    } catch (_) {
      // Se não houver treino cadastrado exatamente para o dia de hoje
      return null;
    }
  }

  // --- SALVAR NOVO TREINO COM A LISTA DE EXERCÍCIOS ---
  static Future<bool> criarTreino({
    required String usuarioId,
    required String titulo,
    required String descricao,
    required String diaSemana,
    required List<Exercicio> exercicios,
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
          'exercicios': exercicios.map((e) => e.toJson()).toList(),
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deletarTreino(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/treinos?id=$id'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}