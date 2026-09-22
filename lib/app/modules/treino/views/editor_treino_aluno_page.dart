import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/aluno_model.dart';
import '../models/treino_model.dart';
import '../repositories/treino_repository.dart';

class EditorTreinoAlunoPage extends StatefulWidget {
  final Aluno aluno;

  const EditorTreinoAlunoPage({super.key, required this.aluno});

  @override
  State<EditorTreinoAlunoPage> createState() => _EditorTreinoAlunoPageState();
}

class _EditorTreinoAlunoPageState extends State<EditorTreinoAlunoPage> {
  String _diaSelecionado = 'Segunda-Feira';
  final List<String> _diasDaSemana = [
    'Segunda-Feira',
    'Terça-Feira',
    'Quarta-Feira',
    'Quinta-Feira',
    'Sexta-Feira',
    'Sábado',
    'Domingo'
  ];

  // Controladores do Treino Principal (Ficha)
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  // Controladores do Exercício Individual Detalhado
  final _nomeExercicioController = TextEditingController();
  final _seriesController = TextEditingController(text: '4');
  final _repeticoesController = TextEditingController(text: '8-10');
  final _cargaController = TextEditingController(text: '80');
  final _descansoController = TextEditingController(text: '90');

  bool _isLoading = false;
  List<FichaTreino> _treinosAluno = [];
  
  // Lista temporária de exercícios estruturados para o treino que está sendo montado
  final List<Exercicio> _exerciciosTemporarios = [];

  @override
  void initState() {
    super.initState();
    _carregarTreinos();
  }

  Future<void> _carregarTreinos() async {
    setState(() => _isLoading = true);
    _treinosAluno = await TreinoRepository.getTreinosPorUsuario(widget.aluno.id);
    if (mounted) setState(() => _isLoading = false);
  }

  void _adicionarExercicioNaLista() {
    if (_nomeExercicioController.text.trim().isEmpty) return;

    setState(() {
      _exerciciosTemporarios.add(
        Exercicio(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nome: _nomeExercicioController.text.trim(),
          grupoMuscular: 'Geral',
          series: int.tryParse(_seriesController.text) ?? 3,
          repeticoes: _repeticoesController.text.trim(),
          cargaKg: double.tryParse(_cargaController.text) ?? 0.0,
          descansoSegundos: int.tryParse(_descansoController.text) ?? 60,
        ),
      );
      // Limpa apenas os campos do exercício para o próximo
      _nomeExercicioController.clear();
    });
  }

  Future<void> _salvarFichaTreino() async {
    if (_tituloController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    // Aqui você pode enviar a ficha junto com os exercícios para o backend
    final sucesso = await TreinoRepository.criarTreino(
      usuarioId: widget.aluno.id,
      titulo: _tituloController.text,
      descricao: _descricaoController.text,
      diaSemana: _diaSelecionado,
    );

    if (sucesso) {
      _tituloController.clear();
      _descricaoController.clear();
      _exerciciosTemporarios.clear();
      await _carregarTreinos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino salvo com sucesso!'), backgroundColor: AppColors.orangePrimary),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deletarTreino(String id) async {
    final sucesso = await TreinoRepository.deletarTreino(id);
    if (sucesso) _carregarTreinos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        title: Text(
          'TREINO: ${widget.aluno.nome.toUpperCase()}',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SELEÇÃO DO DIA DA SEMANA
            const Text('DIA DA SEMANA:', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _diaSelecionado,
              dropdownColor: AppColors.backgroundCard,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: _diasDaSemana.map((dia) {
                return DropdownMenuItem(value: dia, child: Text(dia));
              }).toList(),
              onChanged: (val) => setState(() => _diaSelecionado = val!),
            ),
            const SizedBox(height: 16),

            // DADOS PRINCIPAIS DO TREINO
            TextFormField(
              controller: _tituloController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Título do Treino (ex: Peitoral & Tríceps)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricaoController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Descrição (ex: Foco em hipertrofia)'),
            ),
            const SizedBox(height: 24),

            // FORMULÁRIO DE ADIÇÃO DE EXERCÍCIO DETALHADO
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.orangeGlow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ADICIONAR EXERCÍCIO DETALHADO',
                    style: TextStyle(color: AppColors.orangePrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nomeExercicioController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Nome do Exercício (ex: Supino Reto com Barra)'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _seriesController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(labelText: 'Séries (ex: 4)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _repeticoesController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(labelText: 'Reps (ex: 8-10)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cargaController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(labelText: 'Carga (kg)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _descansoController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(labelText: 'Descanso (seg)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _adicionarExercicioNaLista,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('ADICIONAR EXERCÍCIO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangePrimary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // LISTA DE EXERCÍCIOS ADICIONADOS NESTA SESSÃO
            if (_exerciciosTemporarios.isNotEmpty) ...[
              const Text('EXERCÍCIOS NA FICHA ATUAL:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exerciciosTemporarios.length,
                itemBuilder: (context, index) {
                  final ex = _exerciciosTemporarios[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.nome, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: [
                                  _buildBadge('${ex.series} Séries'),
                                  _buildBadge('${ex.repeticoes} Reps'),
                                  _buildBadge('${ex.cargaKg.toInt()} kg'),
                                  _buildBadge('${ex.descansoSegundos}s descanso'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => setState(() => _exerciciosTemporarios.remove(ex)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // BOTÃO FINAL DE SALVAR TREINO COMPLETO
            ElevatedButton(
              onPressed: _isLoading ? null : _salvarFichaTreino,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangePrimary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('SALVAR TREINO COMPLETO NO BANCO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),

            // LISTA DE TREINOS JÁ CADASTRADOS NO BANCO
            const Text('TREINOS JÁ CADASTRADOS', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _treinosAluno.length,
              itemBuilder: (context, index) {
                final treino = _treinosAluno[index];
                return Card(
                  color: AppColors.backgroundCard,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(treino.titulo, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text('${treino.identificador} • ${treino.descricao}', style: const TextStyle(color: AppColors.textMuted)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deletarTreino(treino.id),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.backgroundInput,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}