import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/views/login_page.dart';
import 'editar_perfil_page.dart';
import 'gerenciar_permissoes_page.dart';
import '../../treino/models/aluno_model.dart';
import '../../treino/repositories/treino_repository.dart';
import '../../treino/services/treino_pdf_service.dart';

class OpcoesPage extends StatefulWidget {
  const OpcoesPage({super.key});

  @override
  State<OpcoesPage> createState() => _OpcoesPageState();
}

class _OpcoesPageState extends State<OpcoesPage> {
  bool _notificacoesAtivas = true;
  bool _biometriaAtiva = false; // Estado para a digital

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
                AuthService().deslogar(); // Encerra sessão do AuthService
                Navigator.of(context).pop(); // Fecha o dialog
                // Remove todas as telas anteriores da pilha e navega para o Login
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
            title: 'Entrar com Digital',
            subtitle: 'Usar biometria para acessar o aplicativo',
            icon: Icons.fingerprint,
            value: _biometriaAtiva,
            onChanged: (val) {
              setState(() {
                _biometriaAtiva = val;
              });
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Preferências'),
          _buildSwitchTile(
            title: 'Notificações de Treino',
            subtitle: 'Lembretes diários para seus treinos',
            icon: Icons.notifications_active_outlined,
            value: _notificacoesAtivas,
            onChanged: (val) => setState(() => _notificacoesAtivas = val),
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
          // Exibe apenas para Administradores
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
                // VISÃO DO PROFESSOR / ADMIN: Abre diálogo para escolher o aluno
                _exibirSeletorAlunoParaPdf(context);
              } else {
                // VISÃO DO ALUNO: Exporta diretamente os treinos do aluno logado
                final usuarioId = auth.usuarioLogado?['id']?.toString() ?? '';
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
    Navigator.pop(context); // Fecha o indicador de carregamento

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
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.picture_as_pdf, color: AppColors.orangePrimary),
                      onTap: () async {
                        Navigator.pop(context);
                        
                        // Busca os treinos do aluno selecionado e abre o PDF
                        final treinos = await TreinoRepository.getTreinosPorUsuario(aluno.id);
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
