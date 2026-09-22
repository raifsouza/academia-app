import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/treino_model.dart';

class DetalhesTreinoPage extends StatefulWidget {
  final FichaTreino ficha;

  const DetalhesTreinoPage({
    super.key,
    required this.ficha,
  });

  @override
  State<DetalhesTreinoPage> createState() => _DetalhesTreinoPageState();
}

class _DetalhesTreinoPageState extends State<DetalhesTreinoPage> {
  late List<Exercicio> _exercicios;

  @override
  void initState() {
    super.initState();
    // Carrega os exercícios vindos diretamente da ficha cadastrada no banco
    _exercicios = widget.ficha.exercicios;
  }

  double get _progresso {
    if (_exercicios.isEmpty) return 0;
    final concluidos = _exercicios.where((e) => e.concluido).length;
    return concluidos / _exercicios.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.ficha.identificador.toUpperCase(),
          style: const TextStyle(
            color: AppColors.orangePrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header com Progresso do Treino
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.backgroundSecondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ficha.titulo,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PROGRESSO: ${(_progresso * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_exercicios.where((e) => e.concluido).length}/${_exercicios.length} Concluídos',
                      style: const TextStyle(
                        color: AppColors.orangePrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progresso,
                    backgroundColor: AppColors.backgroundInput,
                    color: AppColors.orangePrimary,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // Lista de Exercícios
          Expanded(
            child: _exercicios.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum exercício cadastrado nesta ficha.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _exercicios.length,
                    itemBuilder: (context, index) {
                      final ex = _exercicios[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: ex.concluido
                              ? AppColors.backgroundSecondary.withOpacity(0.5)
                              : AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ex.concluido
                                ? AppColors.border
                                : AppColors.orangeGlow,
                          ),
                        ),
                        child: CheckboxListTile(
                          activeColor: AppColors.orangePrimary,
                          checkColor: Colors.black,
                          value: ex.concluido,
                          onChanged: (bool? val) {
                            setState(() {
                              ex.concluido = val ?? false;
                            });
                          },
                          title: Text(
                            ex.nome,
                            style: TextStyle(
                              color: ex.concluido
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              decoration: ex.concluido
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _TagMetric(label: '${ex.series} Séries'),
                                _TagMetric(label: '${ex.repeticoes} Reps'),
                                _TagMetric(label: '${ex.cargaKg.toInt()} kg'),
                                _TagMetric(
                                    label: '${ex.descansoSegundos}s descanso'),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TagMetric extends StatelessWidget {
  final String label;

  const _TagMetric({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.backgroundInput,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}