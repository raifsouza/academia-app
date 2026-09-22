import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../treino/models/aluno_model.dart';
import '../repositories/avaliacao_repository.dart';
import '../services/avaliacao_calculator.dart';

class AvaliacaoTabPage extends StatefulWidget {
  const AvaliacaoTabPage({super.key});

  @override
  State<AvaliacaoTabPage> createState() => _AvaliacaoTabPageState();
}

class _AvaliacaoTabPageState extends State<AvaliacaoTabPage> {
  // Sub-abas (0: Composição, 1: Anamnese, 2: Perímetros, 3: Risco, 4: Cardio, 5: Neuromotores)
  int _subAbaAtiva = 0;

  List<Aluno> _alunos = [];
  Aluno? _alunoSelecionado;
  bool _isLoading = true;
  bool _isSaving = false;
  int? _avaliacaoId;

  // 1. ANAMNESE
  final _objetivosCtrl = TextEditingController();
  final _cirurgiaCtrl = TextEditingController();
  final _doencasFamiliaCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  bool _praticaAtividade = false;
  bool _tomaMedicamento = false;

  // 2. RISCO CORONARIANO
  final _idadeCtrl = TextEditingController();
  String _sexoRisco = 'M';
  final _exercicioRiscoCtrl = TextEditingController();
  final _historicoFamiliarCtrl = TextEditingController();
  final _tabagismoCtrl = TextEditingController();
  final _pontuacaoRiscoCtrl = TextEditingController();
  final _classificacaoRiscoCtrl = TextEditingController();

  // 3. PERÍMETROS
  final _ombroCtrl = TextEditingController();
  final _bracoRelDirCtrl = TextEditingController();
  final _bracoRelEsqCtrl = TextEditingController();
  final _bracoContDirCtrl = TextEditingController();
  final _bracoContEsqCtrl = TextEditingController();
  final _antebracoDirCtrl = TextEditingController();
  final _antebracoEsqCtrl = TextEditingController();
  final _toraxRelCtrl = TextEditingController();
  final _toraxInspCtrl = TextEditingController();
  final _cinturaCtrl = TextEditingController();
  final _abdomeCtrl = TextEditingController();
  final _quadrilCtrl = TextEditingController();
  final _coxaDirCtrl = TextEditingController();
  final _coxaEsqCtrl = TextEditingController();
  final _panturrilhaDirCtrl = TextEditingController();
  final _panturrilhaEsqCtrl = TextEditingController();

  // 4. COMPOSIÇÃO CORPORAL
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _tmbCtrl = TextEditingController();
  String _protocoloComposicao = 'JACKSON_POLLOCK_3';

  final Map<String, TextEditingController> _dobraControllers = {
    'subescapular': TextEditingController(),
    'tricipital': TextEditingController(),
    'axilarMedia': TextEditingController(),
    'suprailiaca': TextEditingController(),
    'peitoral': TextEditingController(),
    'abdominal': TextEditingController(),
    'coxa': TextEditingController(),
  };

  // 5. CARDIORRESPIRATÓRIA
  String _condicaoFisicaCardio = 'SEDENTARIO';
  String _protocoloCardio = '1_MILHA';
  final _fcRepousoCtrl = TextEditingController();
  final _vo2ObtidoCtrl = TextEditingController();
  final _vo2PrevistoCtrl = TextEditingController();
  final _deficitAerobicoCtrl = TextEditingController();

  // 6. NEUROMOTORES
  final _flexaoBracosCtrl = TextEditingController();
  final _abdominalRepsCtrl = TextEditingController();
  final _bancoWellsCtrl = TextEditingController();

  AvaliacaoResult _resultado = AvaliacaoResult(
    percentualGordura: 0,
    massaMagraKg: 0,
    massaGordaKg: 0,
  );

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    setState(() => _isLoading = true);
    final isGestor = AuthService().isGestor; // Admin ou Personal

    if (isGestor) {
      _alunos = await AvaliacaoRepository.getAlunos();
    } else {
      final usuarioId = AuthService().usuarioLogado?['id']?.toString() ?? '';
      if (usuarioId.isNotEmpty) {
        final dados = await AvaliacaoRepository.getAvaliacaoPorAluno(usuarioId);
        if (dados != null) _preencherCamposComDadosDoBanco(dados);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _recalcularComposicao();
    }
  }

  Future<void> _selecionarAluno(Aluno aluno) async {
    setState(() {
      _alunoSelecionado = aluno;
      _isLoading = true;
    });

    final dados = await AvaliacaoRepository.getAvaliacaoPorAluno(aluno.id);
    if (dados != null) {
      _preencherCamposComDadosDoBanco(dados);
    } else {
      _limparFormulario();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _recalcularComposicao();
    }
  }

  void _preencherCamposComDadosDoBanco(Map<String, dynamic> data) {
    _avaliacaoId = data['id'];

    // 1. Anamnese
    final anamnese = data['anamnese'] ?? {};
    _objetivosCtrl.text = anamnese['objetivos'] ?? '';
    _praticaAtividade = anamnese['pratica_atividade'] == 'Sim' || anamnese['pratica_atividade'] == '1';
    _tomaMedicamento = anamnese['medicamentos'] != null && anamnese['medicamentos'].toString().isNotEmpty;
    _cirurgiaCtrl.text = anamnese['cirurgia'] ?? '';
    _doencasFamiliaCtrl.text = anamnese['doencas_familia'] ?? '';
    _observacoesCtrl.text = anamnese['observacoes'] ?? '';

    // 2. Risco Coronariano
    final risco = data['risco_coronariano'] ?? {};
    _idadeCtrl.text = risco['idade'] != null ? risco['idade'].toString() : '';
    _sexoRisco = risco['sexo'] ?? 'M';
    _exercicioRiscoCtrl.text = risco['exercicio_fisico'] ?? '';
    _historicoFamiliarCtrl.text = risco['historico_familiar'] ?? '';
    _tabagismoCtrl.text = risco['tabagismo'] ?? '';
    _pontuacaoRiscoCtrl.text = risco['pontuacao_total'] != null ? risco['pontuacao_total'].toString() : '';
    _classificacaoRiscoCtrl.text = risco['classificacao_risco'] ?? '';

    // 3. Perímetros
    final per = data['perimetros'] ?? {};
    _ombroCtrl.text = per['ombro']?.toString() ?? '';
    _bracoRelDirCtrl.text = per['braco_relaxado_dir']?.toString() ?? '';
    _bracoRelEsqCtrl.text = per['braco_relaxado_esq']?.toString() ?? '';
    _bracoContDirCtrl.text = per['braco_contraido_dir']?.toString() ?? '';
    _bracoContEsqCtrl.text = per['braco_contraido_esq']?.toString() ?? '';
    _antebracoDirCtrl.text = per['antebraco_dir']?.toString() ?? '';
    _antebracoEsqCtrl.text = per['antebraco_esq']?.toString() ?? '';
    _toraxRelCtrl.text = per['torax_relaxado']?.toString() ?? '';
    _toraxInspCtrl.text = per['torax_inspirado']?.toString() ?? '';
    _cinturaCtrl.text = per['cintura']?.toString() ?? '';
    _abdomeCtrl.text = per['abdome']?.toString() ?? '';
    _quadrilCtrl.text = per['quadril']?.toString() ?? '';
    _coxaDirCtrl.text = per['coxa_dir']?.toString() ?? '';
    _coxaEsqCtrl.text = per['coxa_esq']?.toString() ?? '';
    _panturrilhaDirCtrl.text = per['panturrilha_dir']?.toString() ?? '';
    _panturrilhaEsqCtrl.text = per['panturrilha_esq']?.toString() ?? '';

    // 4. Composição Corporal
    final comp = data['composicao'] ?? {};
    _pesoCtrl.text = comp['peso']?.toString() ?? '';
    _alturaCtrl.text = comp['altura']?.toString() ?? '';
    _tmbCtrl.text = comp['tmb']?.toString() ?? '';
    _protocoloComposicao = comp['protocolo'] ?? 'JACKSON_POLLOCK_3';
    _dobraControllers['tricipital']?.text = comp['dobra_tricipital']?.toString() ?? '';
    _dobraControllers['subescapular']?.text = comp['dobra_subescapular']?.toString() ?? '';
    _dobraControllers['suprailiaca']?.text = comp['dobra_suprailiaca']?.toString() ?? '';
    _dobraControllers['coxa']?.text = comp['dobra_coxa']?.toString() ?? '';
    _dobraControllers['abdominal']?.text = comp['dobra_abdominal']?.toString() ?? '';
    _dobraControllers['peitoral']?.text = comp['dobra_peitoral']?.toString() ?? '';
    _dobraControllers['axilarMedia']?.text = comp['dobra_axilar_media']?.toString() ?? '';

    // 5. Cardiorrespiratória
    final cardio = data['cardiorrespiratoria'] ?? {};
    _condicaoFisicaCardio = cardio['condicao_fisica'] ?? 'SEDENTARIO';
    _protocoloCardio = cardio['protocolo_utilizado'] ?? '1_MILHA';
    _fcRepousoCtrl.text = cardio['frequencia_cardiaca_repouso']?.toString() ?? '';
    _vo2ObtidoCtrl.text = cardio['vo2_max_obtido']?.toString() ?? '';
    _vo2PrevistoCtrl.text = cardio['vo2_max_previsto']?.toString() ?? '';
    _deficitAerobicoCtrl.text = cardio['deficit_aerobico_percentual']?.toString() ?? '';

    // 6. Neuromotores
    final neuro = data['neuromotores'] ?? {};
    _flexaoBracosCtrl.text = neuro['flexao_bracos_reps']?.toString() ?? '';
    _abdominalRepsCtrl.text = neuro['abdominal_reps']?.toString() ?? '';
    _bancoWellsCtrl.text = neuro['banco_wells_cm']?.toString() ?? '';
  }

  void _limparFormulario() {
    _avaliacaoId = null;
    _objetivosCtrl.clear();
    _cirurgiaCtrl.clear();
    _doencasFamiliaCtrl.clear();
    _observacoesCtrl.clear();
    _praticaAtividade = false;
    _tomaMedicamento = false;

    _idadeCtrl.clear();
    _exercicioRiscoCtrl.clear();
    _historicoFamiliarCtrl.clear();
    _tabagismoCtrl.clear();
    _pontuacaoRiscoCtrl.clear();
    _classificacaoRiscoCtrl.clear();

    _ombroCtrl.clear();
    _bracoRelDirCtrl.clear();
    _bracoRelEsqCtrl.clear();
    _bracoContDirCtrl.clear();
    _bracoContEsqCtrl.clear();
    _antebracoDirCtrl.clear();
    _antebracoEsqCtrl.clear();
    _toraxRelCtrl.clear();
    _toraxInspCtrl.clear();
    _cinturaCtrl.clear();
    _abdomeCtrl.clear();
    _quadrilCtrl.clear();
    _coxaDirCtrl.clear();
    _coxaEsqCtrl.clear();
    _panturrilhaDirCtrl.clear();
    _panturrilhaEsqCtrl.clear();

    _pesoCtrl.clear();
    _alturaCtrl.clear();
    _tmbCtrl.clear();
    _dobraControllers.forEach((_, c) => c.clear());

    _fcRepousoCtrl.clear();
    _vo2ObtidoCtrl.clear();
    _vo2PrevistoCtrl.clear();
    _deficitAerobicoCtrl.clear();

    _flexaoBracosCtrl.clear();
    _abdominalRepsCtrl.clear();
    _bancoWellsCtrl.clear();

    setState(() {
      _resultado = AvaliacaoResult(percentualGordura: 0, massaMagraKg: 0, massaGordaKg: 0);
    });
  }

  void _recalcularComposicao() {
    final dobrasNum = <String, double>{};
    _dobraControllers.forEach((key, c) {
      dobrasNum[key] = double.tryParse(c.text) ?? 0.0;
    });

    final peso = double.tryParse(_pesoCtrl.text) ?? 0.0;
    final idade = int.tryParse(_idadeCtrl.text) ?? 0;

    if (peso > 0) {
      final res = AvaliacaoCalculator.calcularComposicao(
        sexo: _sexoRisco,
        idade: idade,
        pesoKg: peso,
        protocolo: _protocoloComposicao,
        dobras: dobrasNum,
      );

      setState(() => _resultado = res);
    }
  }

  Future<void> _salvarNoBanco() async {
    final professorId = AuthService().usuarioLogado?['id'] ?? 1;
    final alunoId = _alunoSelecionado?.id ?? AuthService().usuarioLogado?['id']?.toString() ?? '1';

    setState(() => _isSaving = true);

    final payload = {
      if (_avaliacaoId != null) 'id': _avaliacaoId,
      'aluno_id': int.parse(alunoId),
      'professor_id': professorId,
      'numero_avaliacao': 1,
      'data_avaliacao': DateTime.now().toIso8601String(),
      'anamnese': {
        'objetivos': _objetivosCtrl.text,
        'pratica_atividade': _praticaAtividade ? 'Sim' : 'Não',
        'medicamentos': _tomaMedicamento ? 'Sim' : null,
        'cirurgia': _cirurgiaCtrl.text.isNotEmpty ? _cirurgiaCtrl.text : null,
        'doencas_familia': _doencasFamiliaCtrl.text.isNotEmpty ? _doencasFamiliaCtrl.text : null,
        'observacoes': _observacoesCtrl.text,
      },
      'risco_coronariano': {
        'idade': int.tryParse(_idadeCtrl.text) ?? 0,
        'sexo': _sexoRisco,
        'exercicio_fisico': _exercicioRiscoCtrl.text,
        'historico_familiar': _historicoFamiliarCtrl.text,
        'tabagismo': _tabagismoCtrl.text,
        'pontuacao_total': int.tryParse(_pontuacaoRiscoCtrl.text) ?? 0,
        'classificacao_risco': _classificacaoRiscoCtrl.text,
      },
      'perimetros': {
        'ombro': double.tryParse(_ombroCtrl.text),
        'braco_relaxado_dir': double.tryParse(_bracoRelDirCtrl.text),
        'braco_relaxado_esq': double.tryParse(_bracoRelEsqCtrl.text),
        'braco_contraido_dir': double.tryParse(_bracoContDirCtrl.text),
        'braco_contraido_esq': double.tryParse(_bracoContEsqCtrl.text),
        'antebraco_dir': double.tryParse(_antebracoDirCtrl.text),
        'antebraco_esq': double.tryParse(_antebracoEsqCtrl.text),
        'torax_relaxado': double.tryParse(_toraxRelCtrl.text),
        'torax_inspirado': double.tryParse(_toraxInspCtrl.text),
        'cintura': double.tryParse(_cinturaCtrl.text),
        'abdome': double.tryParse(_abdomeCtrl.text),
        'quadril': double.tryParse(_quadrilCtrl.text),
        'coxa_dir': double.tryParse(_coxaDirCtrl.text),
        'coxa_esq': double.tryParse(_coxaEsqCtrl.text),
        'panturrilha_dir': double.tryParse(_panturrilhaDirCtrl.text),
        'panturrilha_esq': double.tryParse(_panturrilhaEsqCtrl.text),
      },
      'composicao': {
        'peso': double.tryParse(_pesoCtrl.text) ?? 0,
        'altura': double.tryParse(_alturaCtrl.text) ?? 0,
        'tmb': double.tryParse(_tmbCtrl.text),
        'protocolo': _protocoloComposicao,
        'dobra_tricipital': double.tryParse(_dobraControllers['tricipital']!.text),
        'dobra_subescapular': double.tryParse(_dobraControllers['subescapular']!.text),
        'dobra_suprailiaca': double.tryParse(_dobraControllers['suprailiaca']!.text),
        'dobra_coxa': double.tryParse(_dobraControllers['coxa']!.text),
        'dobra_abdominal': double.tryParse(_dobraControllers['abdominal']!.text),
        'dobra_peitoral': double.tryParse(_dobraControllers['peitoral']!.text),
        'dobra_axilar_media': double.tryParse(_dobraControllers['axilarMedia']!.text),
        'percentual_gordura': _resultado.percentualGordura,
        'massa_magra_kg': _resultado.massaMagraKg,
        'massa_gorda_kg': _resultado.massaGordaKg,
      },
      'cardiorrespiratoria': {
        'condicao_fisica': _condicaoFisicaCardio,
        'protocolo_utilizado': _protocoloCardio,
        'frequencia_cardiaca_repouso': int.tryParse(_fcRepousoCtrl.text),
        'vo2_max_obtido': double.tryParse(_vo2ObtidoCtrl.text) ?? 0,
        'vo2_max_previsto': double.tryParse(_vo2PrevistoCtrl.text) ?? 0,
        'deficit_aerobico_percentual': double.tryParse(_deficitAerobicoCtrl.text) ?? 0,
      },
      'neuromotores': {
        'flexao_bracos_reps': int.tryParse(_flexaoBracosCtrl.text) ?? 0,
        'abdominal_reps': int.tryParse(_abdominalRepsCtrl.text) ?? 0,
        'banco_wells_cm': double.tryParse(_bancoWellsCtrl.text) ?? 0,
      }
    };

    final ok = await AvaliacaoRepository.salvarAvaliacao(payload);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Avaliação salva com sucesso!' : 'Erro ao salvar avaliação.'),
          backgroundColor: ok ? AppColors.orangePrimary : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGestor = AuthService().isGestor; // True para Admin e Personal

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        title: Text(
          isGestor && _alunoSelecionado != null
              ? 'AVALIAÇÃO: ${_alunoSelecionado!.nome.toUpperCase()}'
              : (isGestor ? 'GESTÃO DE AVALIAÇÕES' : 'MINHA AVALIAÇÃO FÍSICA'),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: isGestor && _alunoSelecionado != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => setState(() => _alunoSelecionado = null),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orangePrimary))
          : isGestor && _alunoSelecionado == null
              ? _buildListaAlunos()
              : _buildFormularioSubAbas(isGestor),
    );
  }

  Widget _buildListaAlunos() {
    if (_alunos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum aluno encontrado no banco de dados.',
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
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.orangePrimary,
              backgroundImage: aluno.fotoUrl.isNotEmpty ? NetworkImage(aluno.fotoUrl) : null,
              child: aluno.fotoUrl.isEmpty ? const Icon(Icons.person, color: Colors.black) : null,
            ),
            title: Text(aluno.nome, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            subtitle: Text('Plano: ${aluno.plano}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            trailing: const Icon(Icons.assignment, color: AppColors.orangePrimary),
            onTap: () => _selecionarAluno(aluno),
          ),
        );
      },
    );
  }

  Widget _buildFormularioSubAbas(bool canEdit) {
    final subAbas = ['COMPOSIÇÃO', 'ANAMNESE', 'PERÍMETROS', 'RISCO', 'CARDIO', 'NEUROMOTORES'];

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(subAbas.length, (index) {
              final selected = _subAbaAtiva == index;
              return GestureDetector(
                onTap: () => setState(() => _subAbaAtiva = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected ? AppColors.orangePrimary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    subAbas[index],
                    style: TextStyle(
                      color: selected ? AppColors.orangePrimary : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_subAbaAtiva == 0) _buildComposicao(canEdit),
                if (_subAbaAtiva == 1) _buildAnamnese(canEdit),
                if (_subAbaAtiva == 2) _buildPerimetros(canEdit),
                if (_subAbaAtiva == 3) _buildRiscoCoronariano(canEdit),
                if (_subAbaAtiva == 4) _buildCardio(canEdit),
                if (_subAbaAtiva == 5) _buildNeuromotores(canEdit),
                if (canEdit) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _salvarNoBanco,
                    icon: const Icon(Icons.save, size: 18),
                    label: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text('SALVAR AVALIAÇÃO NO BANCO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangePrimary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 1. ABA COMPOSIÇÃO
  Widget _buildComposicao(bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _field('Peso (kg)', _pesoCtrl, enabled, isNumber: true, onChanged: (_) => _recalcularComposicao())),
            const SizedBox(width: 12),
            Expanded(child: _field('Altura (m)', _alturaCtrl, enabled, isNumber: true)),
          ],
        ),
        const SizedBox(height: 12),
        _field('TMB (Kcal)', _tmbCtrl, enabled, isNumber: true),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _dobraControllers.entries.map((e) {
                return SizedBox(
                  width: itemWidth,
                  child: _field(e.key.toUpperCase(), e.value, enabled, isNumber: true, onChanged: (_) => _recalcularComposicao()),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // 2. ABA ANAMNESE
  Widget _buildAnamnese(bool enabled) {
    return Column(
      children: [
        _field('Objetivos', _objetivosCtrl, enabled),
        const SizedBox(height: 12),
        _field('Cirurgias Realizadas', _cirurgiaCtrl, enabled),
        const SizedBox(height: 12),
        _field('Doenças na Família', _doencasFamiliaCtrl, enabled),
        const SizedBox(height: 12),
        _field('Observações / Dores', _observacoesCtrl, enabled, maxLines: 3),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Pratica Atividade Física?', style: TextStyle(color: AppColors.textPrimary)),
          value: _praticaAtividade,
          activeColor: AppColors.orangePrimary,
          onChanged: enabled ? (v) => setState(() => _praticaAtividade = v) : null,
        ),
      ],
    );
  }

  // 3. ABA PERÍMETROS
  Widget _buildPerimetros(bool enabled) {
    return Column(
      children: [
        Row(children: [Expanded(child: _field('Ombro', _ombroCtrl, enabled, isNumber: true)), const SizedBox(width: 12), Expanded(child: _field('Tórax Rel.', _toraxRelCtrl, enabled, isNumber: true))]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _field('Braço Rel. Dir.', _bracoRelDirCtrl, enabled, isNumber: true)), const SizedBox(width: 12), Expanded(child: _field('Braço Rel. Esq.', _bracoRelEsqCtrl, enabled, isNumber: true))]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _field('Braço Cont. Dir.', _bracoContDirCtrl, enabled, isNumber: true)), const SizedBox(width: 12), Expanded(child: _field('Braço Cont. Esq.', _bracoContEsqCtrl, enabled, isNumber: true))]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _field('Cintura', _cinturaCtrl, enabled, isNumber: true)), const SizedBox(width: 12), Expanded(child: _field('Quadril', _quadrilCtrl, enabled, isNumber: true))]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _field('Abdome', _abdomeCtrl, enabled, isNumber: true)), const SizedBox(width: 12), Expanded(child: _field('Coxa Dir.', _coxaDirCtrl, enabled, isNumber: true))]),
      ],
    );
  }

  // 4. ABA RISCO CORONARIANO
  Widget _buildRiscoCoronariano(bool enabled) {
    return Column(
      children: [
        Row(children: [Expanded(child: _field('Idade', _idadeCtrl, enabled, isNumber: true)), const SizedBox(width: 12), Expanded(child: _field('Sexo', TextEditingController(text: _sexoRisco), enabled))]),
        const SizedBox(height: 12),
        _field('Histórico Familiar', _historicoFamiliarCtrl, enabled),
        const SizedBox(height: 12),
        _field('Tabagismo', _tabagismoCtrl, enabled),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _field('Pontuação Total', _pontuacaoRiscoCtrl, enabled, isNumber: true)), const SizedBox(width: 12), Expanded(child: _field('Classificação Risco', _classificacaoRiscoCtrl, enabled))]),
      ],
    );
  }

  // 5. ABA CARDIORRESPIRATÓRIA
  Widget _buildCardio(bool enabled) {
    return Column(
      children: [
        _field('Condição Física', TextEditingController(text: _condicaoFisicaCardio), enabled),
        const SizedBox(height: 12),
        _field('FC Repouso (bpm)', _fcRepousoCtrl, enabled, isNumber: true),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _field('VO2 Max Obtido', _vo2ObtidoCtrl, enabled, isNumber: true)), const SizedBox(width: 12), Expanded(child: _field('VO2 Max Previsto', _vo2PrevistoCtrl, enabled, isNumber: true))]),
      ],
    );
  }

  // 6. ABA NEUROMOTORES
  Widget _buildNeuromotores(bool enabled) {
    return Column(
      children: [
        _field('Flexão de Braços (Reps)', _flexaoBracosCtrl, enabled, isNumber: true),
        const SizedBox(height: 12),
        _field('Abdominal (Reps)', _abdominalRepsCtrl, enabled, isNumber: true),
        const SizedBox(height: 12),
        _field('Banco de Wells (cm)', _bancoWellsCtrl, enabled, isNumber: true),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, bool enabled, {bool isNumber = false, int maxLines = 1, Function(String)? onChanged}) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}