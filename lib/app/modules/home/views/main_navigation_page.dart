import 'package:flutter/material.dart';
import 'package:power_shape_app/app/modules/opcoes/views/opcoes_page.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../avaliacao/views/avaliacao_tab_page.dart';
import '../../financeiro/views/financeiro_tab_page.dart';
import '../../treino/views/treinos_tab_page.dart';
import '../widgets/dashboard_home_tab.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  void _mudarAba(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isAdmin = authService.isAdmin;
    final isGestor = authService.isGestor;

    final int usuarioIdLogado =
        int.tryParse(authService.usuarioLogado?['id']?.toString() ?? '0') ?? 0;

    final List<Widget> pagesAdmin = [
      DashboardHomeTab(onNavegarParaTreinos: () => _mudarAba(1)),
      const TreinosTabPage(),
      const AvaliacaoTabPage(),
      FinanceiroTabPage(
        isAdmin: true,
        usuarioIdLogado: usuarioIdLogado,
      ),
      const OpcoesPage(),
    ];

    final List<Widget> pagesPersonal = [
      DashboardHomeTab(onNavegarParaTreinos: () => _mudarAba(1)),
      const TreinosTabPage(),
      const AvaliacaoTabPage(),
      const OpcoesPage(),
    ];

    final List<Widget> pagesAluno = [
      DashboardHomeTab(onNavegarParaTreinos: () => _mudarAba(1)),
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
          onTap: _mudarAba,
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