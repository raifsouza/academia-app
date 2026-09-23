import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produto_model.dart';

class ProdutoRepository {
  static const String baseUrl = 'http://localhost:3000/api';

  /// Busca a lista de produtos cadastrados na lanchonete/loja
  static Future<List<Produto>> getProdutos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/produtos'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Produto.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao carregar produtos: $e');
      return [];
    }
  }

  /// Cadastra um novo produto (apenas Admin)
  static Future<bool> criarProduto(Produto produto) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/produtos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(produto.toJson()),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Erro ao criar produto: $e');
      return false;
    }
  }

  /// Registra a venda de um produto e abate no estoque
  static Future<bool> registrarVenda({
    required int produtoId,
    required int quantidade,
    required int usuarioIdVendedor,
    required String metodoPagamento, // Ex: 'DINHEIRO', 'DEBITO', 'PIX', 'CREDITO'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'produto_id': produtoId,
          'quantidade': quantidade,
          'vendedor_id': usuarioIdVendedor,
          'metodo_pagamento': metodoPagamento,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Erro ao registrar venda: $e');
      return false;
    }
  }

  /// Busca o histórico completo de vendas realizadas (apenas Admin)
  static Future<List<Map<String, dynamic>>> getHistoricoVendas() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/vendas'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Erro ao carregar histórico de vendas: $e');
      return [];
    }
  }
}