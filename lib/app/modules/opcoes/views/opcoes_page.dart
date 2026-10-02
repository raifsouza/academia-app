import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb; // Importado para suporte a Web
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/views/login_page.dart';
import 'editar_perfil_page.dart';
import 'gerenciar_permissoes_page.dart';
import '../../treino/repositories/treino_repository.dart';
import '../../treino/services/treino_pdf_service.dart';

class OpcoesPage extends StatefulWidget {
  const OpcoesPage({super.key});

  @override
  State<OpcoesPage> createState() => _OpcoesPageState();
}

class _OpcoesPageState extends State<OpcoesPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _notificacoesAtivas = true;
  bool _biometriaAtiva = false;
  bool _carregandoPreferencias = true;

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  // Carrega as configurações salvas no dispositivo
  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificacoesAtivas = prefs.getBool('notificacoes_ativas') ?? true;
        _biometriaAtiva = prefs.getBool('biometria_ativa') ?? false;
        _carregandoPreferencias = false;
      });
    }
  }

  // Alterna e valida o acesso biométrico/padrão antes de ativar
  Future<void> _alternarBiometria(bool valor) async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A autenticação biométrica não está disponível na versão Web.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    if (valor) {
      final bool podeAutenticar = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (!podeAutenticar) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Seu dispositivo não possui biometria ou padrão configurado.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      try {
        final bool autenticado = await _localAuth.authenticate(
          localizedReason: 'Confirme para ativar a autenticação no Power Shape',
          options: const AuthenticationOptions(
            biometricOnly: false, // Permite padrão/PIN/senha no Android se configurado
            stickyAuth: true,
          ),
        );

        if (!autenticado) return;
      } catch (e) {
        debugPrint('Erro ao autenticar: $e');
        return;
      }
    }

    setState(() => _biometriaAtiva = valor);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometria_ativa', valor);
  }

  // Alterna e atualiza o estado das notificações no FCM e SharedPreferences
  Future<void> _alternarNotificacoes(bool valor) async {
    setState(() => _notificacoesAtivas = valor);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificacoes_ativas', valor);

    try {
      if (valor) {
        await FirebaseMessaging.instance.requestPermission();
        await FirebaseMessaging.instance.subscribeToTopic('todos');
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic('todos');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              valor
                  ? 'Notificações ativadas com sucesso!'
                  : 'Notificações desativadas.',
            ),
            backgroundColor:
                valor ? AppColors.orangePrimary : Colors.grey[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao alterar estado das notificações: $e');
    }
  }

  void _confirmarSaida() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text(
            'Sair da Conta',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Deseja realmente sair do Power Shape?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                AuthService().deslogar();
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text(
                'Sair',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService().isAdmin;

    // Checagem segura para Web e Mobile
    final bool isIOS = !kIsWeb && Platform.isIOS;
    final String biometriaTitulo =
        isIOS ? 'Entrar com Face ID' : 'Entrar com Digital ou Padrão';
    final String biometriaSubtitulo = isIOS
        ? 'Usar Face ID / Touch ID para acessar o aplicativo'
        : 'Usar digital, padrão de desenho ou PIN';
    final IconData biometriaIcone = isIOS ? Icons.face : Icons.fingerprint;

    if (_carregandoPreferencias) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.orangePrimary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        title: const Text(
          'Opções',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Segurança & Acesso'),
          _buildSwitchTile(
            title: biometriaTitulo,
            subtitle: biometriaSubtitulo,
            icon: biometriaIcone,
            value: _biometriaAtiva,
            onChanged: _alternarBiometria,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Preferências'),
          _buildSwitchTile(
            title: 'Notificações de Treino',
            subtitle: 'Lembretes diários para seus treinos',
            icon: Icons.notifications_active_outlined,
            value: _notificacoesAtivas,
            onChanged: _alternarNotificacoes,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Conta & Dados'),
          _buildActionTile(
            title: 'Perfil do Usuário',
            subtitle: 'Editar informações pessoais e senha',
            icon: Icons.person_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditarPerfilPage(),
                ),
              );
            },
          ),
          if (isAdmin) ...[
            _buildActionTile(
              title: 'Alterar Nível de Acesso',
              subtitle:
                  'Gerenciar permissões dos usuários (Admin, Personal, Aluno)',
              icon: Icons.admin_panel_settings_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GerenciarPermissoesPage(),
                  ),
                );
              },
            ),
          ],
          _buildActionTile(
            title: 'Exportar Treinos (PDF)',
            subtitle: 'Gerar relatório em formato PDF',
            icon: Icons.picture_as_pdf_outlined,
            onTap: () async {
              final auth = AuthService();

              if (auth.isGestor) {
                _exibirSeletorAlunoParaPdf(context);
              } else {
                final usuarioId =
                    auth.usuarioLogado?['id']?.toString() ?? '';
                final nome = auth.nomeExibicao;
                final matricula =
                    auth.usuarioLogado?['matricula']?.toString() ?? 'N/A';

                final treinos = await TreinoRepository.getTreinosPorUsuario(
                  usuarioId,
                );
                await TreinoPdfService.gerarECompartilharPdf(
                  nomeAluno: nome,
                  matricula: matricula,
                  treinos: treinos,
                );
              }
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Sessão'),
          _buildActionTile(
            title: 'Sair da Conta',
            subtitle: 'Encerrar sessão no dispositivo',
            icon: Icons.logout,
            iconColor: Colors.redAccent,
            titleColor: Colors.redAccent,
            onTap: _confirmarSaida,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Sobre'),
          _buildActionTile(
            title: 'Versão do Aplicativo',
            subtitle: '1.0.0',
            icon: Icons.info_outline,
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.orangePrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SwitchListTile(
        activeColor: AppColors.orangePrimary,
        secondary: Icon(icon, color: AppColors.orangePrimary),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Color iconColor = AppColors.orangePrimary,
    Color titleColor = AppColors.textPrimary,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
            : null,
      ),
    );
  }

  void _exibirSeletorAlunoParaPdf(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.orangePrimary),
      ),
    );

    final alunos = await TreinoRepository.getAlunos();

    if (mounted) {
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.backgroundCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXPORTAR TREINOS EM PDF',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Selecione o aluno para gerar a ficha:',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: alunos.length,
                    itemBuilder: (context, index) {
                      final aluno = alunos[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.orangePrimary,
                          backgroundImage: aluno.fotoUrl.isNotEmpty
                              ? NetworkImage(aluno.fotoUrl)
                              : null,
                          child: aluno.fotoUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.black)
                              : null,
                        ),
                        title: Text(
                          aluno.nome,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Matrícula: ${aluno.matricula}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                        trailing: const Icon(Icons.picture_as_pdf,
                            color: AppColors.orangePrimary),
                        onTap: () async {
                          Navigator.pop(context);

                          final treinos =
                              await TreinoRepository.getTreinosPorUsuario(
                                  aluno.id);
                          await TreinoPdfService.gerarECompartilharPdf(
                            nomeAluno: aluno.nome,
                            matricula: aluno.matricula,
                            treinos: treinos,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}