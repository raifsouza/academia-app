import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/aluno_model.dart';
import '../repositories/treino_repository.dart';
import '../widgets/aluno_tile_widget.dart';

class ListaAlunosPage extends StatefulWidget {
  const ListaAlunosPage({super.key});

  @override
  State<ListaAlunosPage> createState() => _ListaAlunosPageState();
}

class _ListaAlunosPageState extends State<ListaAlunosPage> {
  late Future<List<Aluno>> _alunosFuture;

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  void _carregarAlunos() {
    setState(() {
      _alunosFuture = TreinoRepository.getAlunos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        title: const Text(
          'GESTÃO DE ALUNOS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      body: FutureBuilder<List<Aluno>>(
        future: _alunosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orangePrimary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar alunos: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final alunos = snapshot.data ?? [];

          if (alunos.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum aluno cadastrado.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _carregarAlunos(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alunos.length,
              itemBuilder: (context, index) {
                return AlunoTileWidget(
                  aluno: alunos[index],
                  onUpdate: _carregarAlunos,
                );
              },
            ),
          );
        },
      ),
    );
  }
}