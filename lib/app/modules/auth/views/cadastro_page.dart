import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  int _diaVencimento = DateTime.now().day > 28 ? 28 : DateTime.now().day;
  DateTime? _dataAulaExperimental;
  bool _isLoading = false;

  // Variáveis da Foto
  XFile? _fotoSelecionada;
  String? _fotoBase64;

  final List<int> _diasVencimento = List.generate(28, (index) => index + 1);

  // Função para selecionar a foto de perfil
  Future<void> _selecionarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _fotoSelecionada = image;
        // Prepara foto em formato base64 se a API receber Data URL
        _fotoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    }
  }

  String? _formatarDataParaBanco(String dataPtBr) {
    if (dataPtBr.length != 10) return null;
    final partes = dataPtBr.split('-');
    if (partes.length != 3) return null;
    return "${partes[2]}-${partes[1]}-${partes[0]}";
  }

  String _calcularDataVencimentoCompleta(int dia) {
    final hoje = DateTime.now();
    int ano = hoje.year;
    int mes = hoje.month;

    if (dia < hoje.day) {
      mes += 1;
      if (mes > 12) {
        mes = 1;
        ano += 1;
      }
    }
    return "$ano-${mes.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}";
  }

  Future<void> _selecionarDataAulaExperimental() async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.orangePrimary,
              onPrimary: Colors.black,
              surface: AppColors.backgroundPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dataSelecionada != null && mounted) {
      final TimeOfDay? horaSelecionada = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.orangePrimary,
                onPrimary: Colors.black,
                surface: AppColors.backgroundPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (horaSelecionada != null) {
        setState(() {
          _dataAulaExperimental = DateTime(
            dataSelecionada.year,
            dataSelecionada.month,
            dataSelecionada.day,
            horaSelecionada.hour,
            horaSelecionada.minute,
          );
        });
      }
    }
  }

  Future<void> _efetuarCadastro() async {
    if (!_formKey.currentState!.validate()) return;

    final dataNascimentoConvertida = _formatarDataParaBanco(_dataNascimentoController.text.trim());
    if (dataNascimentoConvertida == null) {
      _exibirErro('Data de nascimento inválida. Use o formato DD-MM-AAAA');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'senha': _senhaController.text,
        'telefone': _telefoneController.text.trim(),
        'data_nascimento': dataNascimentoConvertida,
        'foto_url': _fotoBase64, // Envia a string em base64 da foto
        'data_vencimento': _calcularDataVencimentoCompleta(_diaVencimento),
        'agendar_aula_experimental': _dataAulaExperimental?.toIso8601String(),
        'realizou_avaliacao': false,
        'tipo_usuario': 3,
      };

      final response = await http.post(
        Uri.parse(ApiConstants.alunosUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String matricula = responseData['matricula'] ?? 'N/A';
        if (mounted) {
          _exibirModalSucesso(matricula);
        }
      } else {
        _exibirErro(responseData['error'] ?? 'Erro ao realizar cadastro.');
      }
    } catch (e) {
      _exibirErro('Não foi possível conectar ao servidor.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _exibirErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
    );
  }

  void _exibirModalSucesso(String matricula) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Text('🎉', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text(
              'CADASTRO REALIZADO!',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Você foi cadastrado com sucesso na Power Shape.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orangePrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.orangePrimary),
              ),
              child: Column(
                children: [
                  const Text('NÚMERO DE MATRÍCULA', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    matricula,
                    style: const TextStyle(color: AppColors.orangePrimary, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangePrimary,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 45),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('IR PARA O LOGIN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('CADASTRO DE ALUNO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- SELETOR DE FOTO DE PERFIL ---
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.orangePrimary.withOpacity(0.2),
                        backgroundImage: _fotoSelecionada != null
                            ? (kIsWeb
                                ? NetworkImage(_fotoSelecionada!.path)
                                : FileImage(File(_fotoSelecionada!.path)) as ImageProvider)
                            : null,
                        child: _fotoSelecionada == null
                            ? const Icon(Icons.person, size: 50, color: AppColors.orangePrimary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _selecionarFoto,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.orangePrimary,
                            child: Icon(
                              _fotoSelecionada == null ? Icons.camera_alt : Icons.edit,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Foto de Perfil (Opcional)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  label: 'NOME DO ALUNO *',
                  hint: 'Digite seu nome completo',
                  prefixIcon: Icons.person_outline,
                  controller: _nomeController,
                  validator: (val) => (val == null || val.trim().length < 3) ? 'Mínimo de 3 caracteres' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'E-MAIL *',
                  hint: 'aluno@email.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  validator: (val) => (val == null || !val.contains('@')) ? 'Insira um e-mail válido' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'TELEFONE / WHATSAPP *',
                  hint: '(00) 00000-0000',
                  prefixIcon: Icons.phone_outlined,
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_MascaraTelefoneFormatter()],
                  validator: (val) => (val == null || val.length < 14) ? 'Informe um telefone válido' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'SENHA *',
                  hint: 'Mínimo 6 caracteres',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  controller: _senhaController,
                  validator: (val) => (val == null || val.length < 6) ? 'Mínimo de 6 caracteres' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'CONFIRMAR SENHA *',
                  hint: 'Repita a senha',
                  prefixIcon: Icons.lock_clock_outlined,
                  isPassword: true,
                  controller: _confirmarSenhaController,
                  validator: (val) {
                    if (val != _senhaController.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'DATA DE NASCIMENTO *',
                  hint: 'DD-MM-AAAA',
                  prefixIcon: Icons.calendar_today_outlined,
                  controller: _dataNascimentoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_MascaraDataFormatter()],
                  validator: (val) {
                    if (val == null || val.length < 10) return 'Informe no formato DD-MM-AAAA';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Agendar Aula Experimental
                InkWell(
                  onTap: _selecionarDataAulaExperimental,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'AGENDAR AULA EXPERIMENTAL (OPCIONAL)',
                      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.event_available, color: AppColors.orangePrimary),
                      suffixIcon: _dataAulaExperimental != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.redAccent),
                              onPressed: () => setState(() => _dataAulaExperimental = null),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    child: Text(
                      _dataAulaExperimental != null
                          ? "${_dataAulaExperimental!.day.toString().padLeft(2, '0')}-${_dataAulaExperimental!.month.toString().padLeft(2, '0')}-${_dataAulaExperimental!.year} às ${_dataAulaExperimental!.hour.toString().padLeft(2, '0')}:${_dataAulaExperimental!.minute.toString().padLeft(2, '0')}"
                          : "Toque para agendar uma data",
                      style: TextStyle(
                        color: _dataAulaExperimental != null ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dia de Vencimento
                DropdownButtonFormField<int>(
                  value: _diaVencimento,
                  dropdownColor: AppColors.backgroundPrimary,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'DIA DE VENCIMENTO *',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.payment, color: AppColors.orangePrimary),
                  ),
                  items: _diasVencimento.map((dia) {
                    return DropdownMenuItem<int>(
                      value: dia,
                      child: Text('Dia $dia'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _diaVencimento = val);
                  },
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _efetuarCadastro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangePrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('EFETUAR CADASTRO', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MascaraTelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final StringBuffer buffer = StringBuffer();

    if (digits.length > 11) {
      return oldValue;
    }

    for (int i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (digits.length == 11 && i == 7) {
        buffer.write('-');
      } else if (digits.length != 11 && i == 6) {
        buffer.write('-');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _MascaraDataFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final StringBuffer buffer = StringBuffer();

    if (digits.length > 8) {
      return oldValue;
    }

    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}