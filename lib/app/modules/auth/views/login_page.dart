import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../home/views/main_navigation_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController(); // E-mail ou Matrícula
  final _passwordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;

  // Substitua pelo IP/Host da sua API
  // Android Emulator: http://10.0.2.2:3000/api/login
  static const String _apiUrl = 'http://localhost:3000/api/login';
  //static const String _apiUrl = 'http://10.0.2.2:3000/api/login';

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': _loginController.text.trim(),
          'senha': _passwordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final usuario = responseData['usuario'];
        final int tipoUsuario = usuario['tipo_usuario'] ?? 3;

        // Salva o mapa com os dados no AuthService
        _authService.usuarioLogado = usuario;

        // Mapeamento de tipo_usuario do BD (1: Admin, 2: Professor/Personal, 3: Aluno)
        if (tipoUsuario == 1) {
          _authService.perfilAtual = TipoPerfil.admin;
        } else if (tipoUsuario == 2) {
          _authService.perfilAtual = TipoPerfil.personal;
        } else {
          _authService.perfilAtual = TipoPerfil.aluno;
        }

        if (mounted) {
          setState(() => _isLoading = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bem-vindo(a), ${usuario['nome']}!'),
              backgroundColor: AppColors.orangePrimary,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationPage()),
          );
        }
      } else {
        // Erro retornado pela API (ex: status 400 ou 401)
        final errorMessage =
            responseData['error'] ?? 'Falha ao realizar login.';
        _exibirErro(errorMessage);
      }
    } catch (e) {
      _exibirErro(
        'Não foi possível conectar ao servidor. Verifique a conexão.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _exibirErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- LOGO / TITULO ---
                  const Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: AppColors.orangePrimary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'POWER SHAPE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    'Performance & Resultados',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // --- INPUTS ---
                  CustomTextField(
                    label: 'Matrícula ou E-mail',
                    hint: 'Digite seu acesso',
                    prefixIcon: Icons.person_outline,
                    controller: _loginController,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Informe sua matrícula ou e-mail';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: 'Senha',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordController,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Informe sua senha';
                      }
                      return null;
                    },
                  ),

                  // --- ESQUECEU A SENHA ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Esqueceu a senha?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- BOTÃO DE ENTRAR ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _fazerLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangePrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.orangeGlow,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'ENTRAR',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
