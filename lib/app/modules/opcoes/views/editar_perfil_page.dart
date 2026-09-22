import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';

class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _fotoUrlCtrl = TextEditingController();
  final _novaSenhaCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosPerfil();
  }

  void _carregarDadosPerfil() {
    final auth = AuthService();
    _nomeCtrl.text = auth.nomeExibicao;
    _fotoUrlCtrl.text = auth.fotoUrl;
    _telefoneCtrl.text = auth.usuarioLogado?['telefone'] ?? '';
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final userId = AuthService().usuarioLogado?['id'];

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/api/usuarios'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': userId,
          'nome': _nomeCtrl.text,
          'telefone': _telefoneCtrl.text,
          'foto_url': _fotoUrlCtrl.text,
          if (_novaSenhaCtrl.text.isNotEmpty) 'senha': _novaSenhaCtrl.text,
        }),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (response.statusCode == 200) {
          // Atualiza os dados locais na sessão
          AuthService().usuarioLogado?['nome'] = _nomeCtrl.text;
          AuthService().usuarioLogado?['foto_url'] = _fotoUrlCtrl.text;
          AuthService().usuarioLogado?['telefone'] = _telefoneCtrl.text;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao atualizar perfil.'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        title: const Text('EDITAR PERFIL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: AppColors.backgroundCard,
                  backgroundImage: _fotoUrlCtrl.text.isNotEmpty ? NetworkImage(_fotoUrlCtrl.text) : null,
                  child: _fotoUrlCtrl.text.isEmpty
                      ? const Icon(Icons.person, size: 40, color: AppColors.orangePrimary)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Nome Completo'),
                validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fotoUrlCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'URL da Foto de Perfil'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _novaSenhaCtrl,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nova Senha (deixe em branco para manter)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _salvarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangePrimary,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('SALVAR ALTERAÇÕES', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}