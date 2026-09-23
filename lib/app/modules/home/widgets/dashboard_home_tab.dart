import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../avaliacao/repositories/avaliacao_repository.dart';
import '../../treino/repositories/treino_repository.dart';
import '../../treino/views/lista_alunos_page.dart';
import '../../treino/views/treinos_tab_page.dart';
import 'metric_card.dart';

class DashboardHomeTab extends StatefulWidget {
  final VoidCallback? onNavegarParaTreinos;

  const DashboardHomeTab({super.key, this.onNavegarParaTreinos});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  // Métricas do Gestor
  int _alunosAtivosCount = 0;
  int _avaliacoesPendentesCount = 0;
  bool _isLoadingMetricas = false;

  // Avaliação Física (Aluno)
  String _percentualGordura = '--';
  String _massaMagra = '--';
  bool _isLoadingAvaliacao = false;

  // Treino do Dia (Aluno)
  dynamic _treinoDoDia;
  bool _isLoadingTreino = false;

  @override
  void initState() {
    super.initState();
    if (AuthService().isGestor) {
      _carregarMetricas();
    } else {
      _carregarTreinoDoDia();
      _carregarAvaliacaoFisica();
    }
  }

  Future<void> _carregarMetricas() async {
    setState(() => _isLoadingMetricas = true);
    try {
      final alunos = await TreinoRepository.getAlunos();
      if (mounted) {
        setState(() {
          _alunosAtivosCount = alunos.where((a) => a.statusAluno == 'ATIVO').length;
          _avaliacoesPendentesCount = alunos.where((a) => !a.realizouAvaliacao).length;
          _isLoadingMetricas = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMetricas = false);
    }
  }

  Future<void> _carregarAvaliacaoFisica() async {
    setState(() => _isLoadingAvaliacao = true);
    try {
      final auth = AuthService();
      final usuarioId = auth.usuarioLogado?['id']?.toString() ?? '6';

      final avaliacao = await AvaliacaoRepository.getUltimaAvaliacao(usuarioId);

      if (mounted) {
        setState(() {
          if (avaliacao != null && avaliacao['composicao'] != null) {
            final composicao = Map<String, dynamic>.from(avaliacao['composicao']);

            final dynamic rawGordura = composicao['percentual_gordura'] ??
                composicao['gordura_percentual'] ??
                composicao['pct_gordura'] ??
                composicao['gordura'] ??
                avaliacao['percentual_gordura'];

            final double gordura = double.tryParse(rawGordura?.toString() ?? '0') ?? 0.0;
            final double peso = double.tryParse(composicao['peso']?.toString() ?? '0') ?? 0.0;

            final dynamic rawMassaMagra = composicao['massa_magra_kg'] ??
                composicao['massa_magra'] ??
                composicao['massa_isenta_gordura'];

            double massaMagra = double.tryParse(rawMassaMagra?.toString() ?? '0') ?? 0.0;

            if (massaMagra == 0.0 && peso > 0 && gordura > 0) {
              massaMagra = peso * (1 - (gordura / 100));
            }

            _percentualGordura = gordura > 0 ? '${gordura.toStringAsFixed(1)}%' : 'N/A';
            _massaMagra = (massaMagra > 0 && gordura > 0)
                ? '${massaMagra.toStringAsFixed(1)} kg'
                : 'N/A';
          } else {
            _percentualGordura = 'N/A';
            _massaMagra = 'N/A';
          }
          _isLoadingAvaliacao = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _percentualGordura = 'N/A';
          _massaMagra = 'N/A';
          _isLoadingAvaliacao = false;
        });
      }
    }
  }

  Future<void> _carregarTreinoDoDia() async {
    setState(() => _isLoadingTreino = true);
    try {
      final auth = AuthService();
      final usuarioId = auth.usuarioLogado?['id']?.toString() ?? '6';

      final treinoHoje = await TreinoRepository.getTreinoDoDia(usuarioId);

      if (mounted) {
        setState(() {
          _treinoDoDia = treinoHoje;
          _isLoadingTreino = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTreino = false);
    }
  }

  String _getDiaSemanaNome(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'SEGUNDA-FEIRA';
      case DateTime.tuesday:
        return 'TERÇA-FEIRA';
      case DateTime.wednesday:
        return 'QUARTA-FEIRA';
      case DateTime.thursday:
        return 'QUINTA-FEIRA';
      case DateTime.friday:
        return 'SEXTA-FEIRA';
      case DateTime.saturday:
        return 'SÁBADO';
      case DateTime.sunday:
        return 'DOMINGO';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isAdmin = authService.isAdmin;
    final isGestor = authService.isGestor;

    final nomeUsuario = authService.nomeExibicao;
    final fotoUrl = authService.fotoUrl;

    final hoje = DateTime.now();
    final String nomeDia = _getDiaSemanaNome(hoje.weekday);

    String tituloTreino = 'SEM TREINO HOJE';
    if (_treinoDoDia != null) {
      tituloTreino = _treinoDoDia.titulo ?? _treinoDoDia['titulo'] ?? 'TREINO DO DIA';
    } else if (!_isLoadingTreino) {
      tituloTreino = 'DIA DE DESCANSO';
    }

    String getTituloHeader() {
      if (isAdmin) return 'PAINEL ADMINISTRATIVO';
      if (isGestor) return 'PAINEL DO PROFESSOR';
      return 'BEM-VINDO DE VOLTA,';
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (isGestor) {
            await _carregarMetricas();
          } else {
            await _carregarTreinoDoDia();
            await _carregarAvaliacaoFisica();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTituloHeader(),
                          style: const TextStyle(
                            color: AppColors.orangePrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nomeUsuario,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: AppColors.backgroundCard,
                    radius: 24,
                    backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                    child: fotoUrl.isEmpty
                        ? const Icon(Icons.person, color: AppColors.orangePrimary)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- CARD PRINCIPAL ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.orangeGlow),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isGestor ? 'GESTÃO DE ALUNOS' : 'TREINO DO DIA ($nomeDia)',
                          style: const TextStyle(
                            color: AppColors.orangePrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundInput,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isGestor
                                ? 'SISTEMA ATIVO'
                                : (_isLoadingTreino
                                    ? 'CARREGANDO...'
                                    : (_treinoDoDia != null ? 'DISPONÍVEL' : 'DESCANSO')),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isGestor
                          ? 'Acompanhamento Geral'
                          : (_isLoadingTreino ? 'Buscando treino...' : tituloTreino),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (_isLoadingTreino && !isGestor)
                          ? null
                          : () {
                              if (isGestor) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ListaAlunosPage(),
                                  ),
                                ).then((_) => _carregarMetricas());
                              } else {
                                if (_treinoDoDia != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TreinosTabPage(),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Nenhum treino agendado para o dia de hoje.'),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangePrimary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        isGestor
                            ? 'VER LISTA DE ALUNOS'
                            : (_treinoDoDia != null ? 'INICIAR TREINO' : 'VER FICHA DE TREINOS'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- MÉTRICAS / RESUMO CORPORAL ---
              Text(
                isGestor ? 'MÉTRICAS DO SISTEMA' : 'RESUMO CORPORAL',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: isGestor ? 'ALUNOS ATIVOS' : '% GORDURA',
                      value: isGestor
                          ? (_isLoadingMetricas ? '...' : '$_alunosAtivosCount Ativos')
                          : (_isLoadingAvaliacao ? '...' : _percentualGordura),
                      icon: isGestor ? Icons.people_outline : Icons.pie_chart_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: isGestor ? 'AVALIAÇÕES PENDENTES' : 'MASSA MAGRA',
                      value: isGestor
                          ? (_isLoadingMetricas ? '...' : '$_avaliacoesPendentesCount Pendentes')
                          : (_isLoadingAvaliacao ? '...' : _massaMagra),
                      icon: isGestor ? Icons.assignment_outlined : Icons.fitness_center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}