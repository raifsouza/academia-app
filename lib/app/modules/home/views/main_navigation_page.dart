import 'package:flutter/material.dart';
import 'package:power_shape_app/app/modules/opcoes/views/opcoes_page.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../avaliacao/views/avaliacao_tab_page.dart';
import '../../financeiro/views/financeiro_tab_page.dart';
import '../../treino/repositories/treino_repository.dart';
import '../../treino/views/lista_alunos_page.dart';
import '../../treino/views/treinos_tab_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isAdmin = authService.isAdmin;
    final isGestor = authService.isGestor; // Admin ou Personal

    final int usuarioIdLogado = int.tryParse(authService.usuarioLogado?['id']?.toString() ?? '0') ?? 0;

    // 1. Telas para o Admin
    final List<Widget> pagesAdmin = [
      const _DashboardHomeTab(),
      const TreinosTabPage(),
      const AvaliacaoTabPage(),
      FinanceiroTabPage(
        isAdmin: true,
        usuarioIdLogado: usuarioIdLogado,
      ),
      const OpcoesPage(),
    ];

    // 2. Telas para o Personal / Professor
    final List<Widget> pagesPersonal = [
      const _DashboardHomeTab(),
      const TreinosTabPage(),
      const AvaliacaoTabPage(),
      const OpcoesPage(),
    ];

    // 3. Telas para o Aluno
    final List<Widget> pagesAluno = [
      const _DashboardHomeTab(),
      const TreinosTabPage(),
      const AvaliacaoTabPage(),
      FinanceiroTabPage(
        isAdmin: false,
        usuarioIdLogado: usuarioIdLogado,
      ),
      const OpcoesPage(),
    ];

    final itemsAdmin = const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Início',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.fitness_center_outlined),
        activeIcon: Icon(Icons.fitness_center),
        label: 'Gestão Treinos',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        activeIcon: Icon(Icons.assignment),
        label: 'Avaliações',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet_outlined),
        activeIcon: Icon(Icons.account_balance_wallet),
        label: 'Financeiro',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Opções',
      ),
    ];

    final itemsPersonal = const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Início',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.fitness_center_outlined),
        activeIcon: Icon(Icons.fitness_center),
        label: 'Gestão Treinos',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        activeIcon: Icon(Icons.assignment),
        label: 'Avaliações',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Opções',
      ),
    ];

    final itemsAluno = const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Início',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.fitness_center_outlined),
        activeIcon: Icon(Icons.fitness_center),
        label: 'Meu Treino',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        activeIcon: Icon(Icons.assignment),
        label: 'Minha Ficha',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet_outlined),
        activeIcon: Icon(Icons.account_balance_wallet),
        label: 'Financeiro',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Opções',
      ),
    ];

    final List<Widget> pages = isAdmin
        ? pagesAdmin
        : (isGestor ? pagesPersonal : pagesAluno);

    final List<BottomNavigationBarItem> items = isAdmin
        ? itemsAdmin
        : (isGestor ? itemsPersonal : itemsAluno);

    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.backgroundSecondary,
          selectedItemColor: AppColors.orangePrimary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: items,
        ),
      ),
    );
  }
}

// Widget Dinâmico do Dashboard Principal
class _DashboardHomeTab extends StatefulWidget {
  const _DashboardHomeTab();

  @override
  State<_DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<_DashboardHomeTab> {
  int _alunosAtivosCount = 0;
  int _avaliacoesPendentesCount = 0;
  bool _isLoadingMetricas = false;

  @override
  void initState() {
    super.initState();
    if (AuthService().isGestor) {
      _carregarMetricas();
    }
  }

  Future<void> _carregarMetricas() async {
    setState(() => _isLoadingMetricas = true);
    try {
      final alunos = await TreinoRepository.getAlunos();
      if (mounted) {
        setState(() {
          // Conta alunos onde statusAluno == 'ATIVO'
          _alunosAtivosCount = alunos.where((a) => a.statusAluno == 'ATIVO').length;
          // Conta alunos sem avaliação realizada
          _avaliacoesPendentesCount = alunos.where((a) => !a.realizouAvaliacao).length;
          _isLoadingMetricas = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMetricas = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isAdmin = authService.isAdmin;
    final isGestor = authService.isGestor;

    final nomeUsuario = authService.nomeExibicao;
    final fotoUrl = authService.fotoUrl;

    String getTituloHeader() {
      if (isAdmin) return 'PAINEL ADMINISTRATIVO';
      if (isGestor) return 'PAINEL DO PROFESSOR';
      return 'BEM-VINDO DE VOLTA,';
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          if (isGestor) await _carregarMetricas();
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
                          isGestor ? 'GESTÃO DE ALUNOS' : 'TREINO DO DIA',
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
                            isGestor ? 'SISTEMA ATIVO' : 'TREINO A',
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
                      isGestor ? 'Acompanhamento Geral' : 'Peitoral e Tríceps',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (isGestor) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ListaAlunosPage(),
                            ),
                          ).then((_) => _carregarMetricas());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangePrimary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        isGestor ? 'VER LISTA DE ALUNOS' : 'INICIAR TREINO',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- MÉTRICAS DO SISTEMA ---
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
                    child: _MetricCard(
                      title: isGestor ? 'ALUNOS ATIVOS' : '% GORDURA',
                      value: isGestor
                          ? (_isLoadingMetricas ? '...' : '$_alunosAtivosCount Ativos')
                          : '14.2%',
                      icon: isGestor ? Icons.people_outline : Icons.pie_chart_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: isGestor ? 'AVALIAÇÕES PENDENTES' : 'MASSA MAGRA',
                      value: isGestor
                          ? (_isLoadingMetricas ? '...' : '$_avaliacoesPendentesCount Pendentes')
                          : '68.5 kg',
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.orangePrimary, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}