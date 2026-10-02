import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
  final _novaSenhaCtrl = TextEditingController();
  
  String? _fotoBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosPerfil();
  }

  void _carregarDadosPerfil() {
    final auth = AuthService();
    _nomeCtrl.text = auth.nomeExibicao;
    _telefoneCtrl.text = auth.usuarioLogado?['telefone'] ?? '';
    _fotoBase64 = auth.fotoUrl; // Pega o Base64 atual salvo no usuário
  }

  /// Seleciona uma imagem da galeria/câmara e converte para Base64
  Future<void> _selecionarFoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75, // Reduz o tamanho/qualidade para economizar banco de dados
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
          // Prepara a string no formato Data URL para o Base64
          _fotoBase64 = 'data:image/jpeg;base64,$base64String';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao selecionar imagem.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Modal para escolher entre Câmara e Galeria
  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.orangePrimary),
              title: const Text('Galeria', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _selecionarFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.orangePrimary),
              title: const Text('Câmara', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _selecionarFoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Helper para renderizar o Avatar do Usuário (Seja Base64 puro ou Data URL)
  ImageProvider? _obterImagemProvider(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;

    try {
      String cleanBase64 = base64Str;
      if (base64Str.contains(',')) {
        cleanBase64 = base64Str.split(',').last;
      }
      final bytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));
      return MemoryImage(bytes);
    } catch (e) {
      return null;
    }
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
          'foto_url': _fotoBase64, // Envia a imagem codificada em Base64
          if (_novaSenhaCtrl.text.isNotEmpty) 'senha': _novaSenhaCtrl.text,
        }),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (response.statusCode == 200) {
          // Atualiza a sessão do usuário localmente
          AuthService().usuarioLogado?['nome'] = _nomeCtrl.text;
          AuthService().usuarioLogado?['foto_url'] = _fotoBase64;
          AuthService().usuarioLogado?['telefone'] = _telefoneCtrl.text;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao atualizar perfil.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _obterImagemProvider(_fotoBase64);

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
              // Avatar com Botão de Edição de Imagem
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.backgroundCard,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person, size: 50, color: AppColors.orangePrimary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _mostrarOpcoesFoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.orangePrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                controller: _novaSenhaCtrl,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nova Senha (deixe em branco para manter)',
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isLoading ? null : _salvarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangePrimary,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'SALVAR ALTERAÇÕES',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}