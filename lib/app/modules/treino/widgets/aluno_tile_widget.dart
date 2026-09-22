import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../models/aluno_model.dart';

class AlunoTileWidget extends StatelessWidget {
  final Aluno aluno;
  final VoidCallback onUpdate;
  final VoidCallback? onTap;

  const AlunoTileWidget({
    super.key,
    required this.aluno,
    required this.onUpdate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAtivo = aluno.statusAluno == 'ATIVO';

    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.orangePrimary,
                    backgroundImage: aluno.fotoUrl.isNotEmpty ? NetworkImage(aluno.fotoUrl) : null,
                    child: aluno.fotoUrl.isEmpty ? const Icon(Icons.person, color: Colors.black) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aluno.nome,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Matrícula: ${aluno.matricula} | Plano: ${aluno.plano}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Badge de Status (Ativo / Inativo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isAtivo ? Colors.green : Colors.red).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: (isAtivo ? Colors.green : Colors.red).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      aluno.statusAluno,
                      style: TextStyle(
                        color: isAtivo ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status da Avaliação Física
                  Row(
                    children: [
                      Icon(
                        aluno.realizouAvaliacao ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: aluno.realizouAvaliacao ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        aluno.realizouAvaliacao ? 'Avaliação OK' : 'Sem Avaliação',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),

                  // Chip Interativo da Aula Experimental
                  FilterChip(
                    label: Text(
                      aluno.aulaExperimentalRealizada ? 'Aula Exp. Realizada' : 'Aula Exp. Pendente',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    selected: aluno.aulaExperimentalRealizada,
                    selectedColor: AppColors.orangePrimary.withOpacity(0.2),
                    checkmarkColor: AppColors.orangePrimary,
                    onSelected: (bool selected) async {
                      // Altera o status manualmente no backend
                      try {
                        await http.put(
                          Uri.parse('http://localhost:3000/api/alunos'), // Ajuste para seu IP se necessário
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'aluno_id': aluno.id,
                            'aula_experimental_realizada': selected,
                          }),
                        );
                        onUpdate(); // Recarrega a lista pai
                      } catch (e) {
                        debugPrint('Erro ao atualizar aula experimental: $e');
                      }
                    },
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