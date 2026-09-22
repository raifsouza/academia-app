import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';

class GerenciarPermissoesPage extends StatefulWidget {
  const GerenciarPermissoesPage({super.key});

  @override
  State<GerenciarPermissoesPage> createState() => _GerenciarPermissoesPageState();
}

class _GerenciarPermissoesPageState extends State<GerenciarPermissoesPage> {
  List<dynamic> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
  }

  Future<void> _carregarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/usuarios'));
      if (response.statusCode == 200) {
        setState(() {
          _usuarios = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _alterarTipoUsuario(int userId, int novoTipo) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/api/usuarios'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': userId,
          'tipo_usuario': novoTipo,
        }),
      );

      if (response.statusCode == 200) {
        _carregarUsuarios();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão alterada com sucesso!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao alterar permissão: $e');
    }
  }

  String _getTipoNome(int tipo) {
    switch (tipo) {
      case 1:
        return 'Administrador';
      case 2:
        return 'Personal / Professor';
      case 3:
      default:
        return 'Aluno';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        title: const Text('GESTÃO DE NÍVEIS DE ACESSO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orangePrimary))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final user = _usuarios[index];
                final int currentTipo = int.tryParse(user['tipo_usuario'].toString()) ?? 3;

                return Card(
                  color: AppColors.backgroundCard,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.orangePrimary,
                      backgroundImage: user['foto_url'] != null && user['foto_url'].toString().isNotEmpty
                          ? NetworkImage(user['foto_url'])
                          : null,
                      child: user['foto_url'] == null || user['foto_url'].toString().isEmpty
                          ? const Icon(Icons.person, color: Colors.black)
                          : null,
                    ),
                    title: Text(
                      user['nome'] ?? 'Sem nome',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${user['email']} | Matrícula: ${user['matricula'] ?? 'N/A'}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    trailing: DropdownButton<int>(
                      value: currentTipo,
                      dropdownColor: AppColors.backgroundCard,
                      style: const TextStyle(color: AppColors.orangePrimary, fontWeight: FontWeight.bold, fontSize: 12),
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Admin')),
                        DropdownMenuItem(value: 2, child: Text('Personal')),
                        DropdownMenuItem(value: 3, child: Text('Aluno')),
                      ],
                      onChanged: (novoTipo) {
                        if (novoTipo != null && novoTipo != currentTipo) {
                          _alterarTipoUsuario(user['id'], novoTipo);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}