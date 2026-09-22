import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../models/aluno_model.dart';
import '../models/treino_model.dart';
import '../repositories/treino_repository.dart';
import 'editor_treino_aluno_page.dart';
import 'detalhes_treino_page.dart';

class TreinosTabPage extends StatefulWidget {
  const TreinosTabPage({super.key});

  @override
  State<TreinosTabPage> createState() => _TreinosTabPageState();
}

class _TreinosTabPageState extends State<TreinosTabPage> {
  bool _isLoading = true;
  List<Aluno> _alunos = [];
  List<FichaTreino> _meusTreinos = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final auth = AuthService();

    if (auth.isPersonal || auth.isAdmin) {
      _alunos = await TreinoRepository.getAlunos();
    } else {
      final usuarioId = auth.usuarioLogado?['id']?.toString() ?? '1';
      _meusTreinos = await TreinoRepository.getTreinosPorUsuario(usuarioId);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPersonal = AuthService().isPersonal;
    final isAdmin = AuthService().isAdmin;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        title: Text(
          isPersonal || isAdmin ? 'ALUNOS (GESTÃO DE TREINO)' : 'MEUS TREINOS',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orangePrimary))
          : RefreshIndicator(
              onRefresh: _carregarDados,
              color: AppColors.orangePrimary,
              child: isPersonal || isAdmin ? _buildViewPersonal() : _buildViewAluno(),
            ),
    );
  }

  // --- VISÃO ALUNO ---
  Widget _buildViewAluno() {
    if (_meusTreinos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum treino cadastrado ainda.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _meusTreinos.length,
      itemBuilder: (context, index) {
        final treino = _meusTreinos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orangePrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.orangePrimary),
                    ),
                    child: Text(
                      treino.identificador.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.orangePrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                treino.titulo,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                treino.descricao,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalhesTreinoPage(ficha: treino),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VER EXERCÍCIOS',
                        style: TextStyle(
                          color: AppColors.orangePrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.orangePrimary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- VISÃO PERSONAL TRAINER ---
  Widget _buildViewPersonal() {
    if (_alunos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum aluno cadastrado.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alunos.length,
      itemBuilder: (context, index) {
        final aluno = _alunos[index];
        return Card(
          color: AppColors.backgroundCard,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.orangePrimary,
              backgroundImage: aluno.fotoUrl.isNotEmpty ? NetworkImage(aluno.fotoUrl) : null,
              child: aluno.fotoUrl.isEmpty ? const Icon(Icons.person, color: Colors.black) : null,
            ),
            title: Text(
              aluno.nome,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Plano: ${aluno.plano}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.edit_note, color: AppColors.orangePrimary, size: 28),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditorTreinoAlunoPage(aluno: aluno),
                ),
              ).then((_) => _carregarDados());
            },
          ),
        );
      },
    );
  }
}