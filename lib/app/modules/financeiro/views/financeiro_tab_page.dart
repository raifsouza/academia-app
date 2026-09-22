import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../treino/models/aluno_model.dart';
import '../models/financeiro_model.dart';
import '../repositories/financeiro_repository.dart';
import '../service/comprovante_pdf_service.dart';


class FinanceiroTabPage extends StatefulWidget {
  final bool isAdmin;
  final int usuarioIdLogado;

  const FinanceiroTabPage({
    super.key,
    required this.isAdmin,
    required this.usuarioIdLogado,
  });

  @override
  State<FinanceiroTabPage> createState() => _FinanceiroTabPageState();
}

class _FinanceiroTabPageState extends State<FinanceiroTabPage> {
  // Para o fluxo do Admin
  List<Aluno> _alunos = [];
  Aluno? _alunoSelecionado;
  bool _isLoadingAlunos = false;

  // Para o fluxo do Aluno / Histórico individual
  late Future<List<Fatura>> _faturasFuture;

  @override
  void initState() {
    super.initState();
    _inicializarTela();
  }

  void _inicializarTela() {
    if (widget.isAdmin) {
      _carregarAlunosAdmin();
    } else {
      _carregarFaturasAluno(widget.usuarioIdLogado);
    }
  }

  Future<void> _carregarAlunosAdmin() async {
    setState(() => _isLoadingAlunos = true);
    final lista = await FinanceiroRepository.getAlunos();
    if (mounted) {
      setState(() {
        _alunos = lista;
        _isLoadingAlunos = false;
      });
    }
  }

  void _carregarFaturasAluno(int alunoId) {
    setState(() {
      _faturasFuture = FinanceiroRepository.getHistoricoFaturasAluno(alunoId);
    });
  }

  void _selecionarAluno(Aluno aluno) {
    setState(() {
      _alunoSelecionado = aluno;
    });
    _carregarFaturasAluno(int.parse(aluno.id));
  }

  @override
  Widget build(BuildContext context) {
    final plano = FinanceiroRepository.getPlanoPadrao();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        title: Text(
          widget.isAdmin
              ? (_alunoSelecionado != null
                  ? 'FINANCEIRO: ${_alunoSelecionado!.nome.toUpperCase()}'
                  : 'GESTÃO FINANCEIRA (ALUNOS)')
              : 'MEU FINANCEIRO',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        leading: widget.isAdmin && _alunoSelecionado != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => setState(() => _alunoSelecionado = null),
              )
            : null,
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _exibirDialogoNovoPagamento(
                context,
                alunoIdInicial: _alunoSelecionado?.id,
              ),
              backgroundColor: AppColors.orangePrimary,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'LANÇAR PAGAMENTO',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: widget.isAdmin && _alunoSelecionado == null
          ? _buildListaAlunosAdmin()
          : _buildHistoricoFaturasView(plano),
    );
  }

  // --- 1. VISÃO DO ADMIN: LISTA DE ALUNOS ---
  Widget _buildListaAlunosAdmin() {
    if (_isLoadingAlunos) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orangePrimary),
      );
    }

    if (_alunos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum aluno encontrado no banco de dados.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarAlunosAdmin,
      child: ListView.builder(
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.orangePrimary,
                backgroundImage: aluno.fotoUrl.isNotEmpty ? NetworkImage(aluno.fotoUrl) : null,
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
                'ID: ${aluno.id} | Plano: ${aluno.plano}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.orangePrimary),
              onTap: () => _selecionarAluno(aluno),
            ),
          );
        },
      ),
    );
  }

  // --- 2. VISÃO DO HISTÓRICO DE PAGAMENTOS (DO ALUNO SELECIONADO OU LOGADO) ---
  Widget _buildHistoricoFaturasView(PlanoAssinatura plano) {
    final targetId = _alunoSelecionado != null
        ? int.parse(_alunoSelecionado!.id)
        : widget.usuarioIdLogado;

    return RefreshIndicator(
      onRefresh: () async => _carregarFaturasAluno(targetId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isAdmin) ...[
              _PlanoCard(plano: plano),
              const SizedBox(height: 24),
            ],
            Text(
              _alunoSelecionado != null
                  ? 'HISTÓRICO DE PAGAMENTOS DE ${_alunoSelecionado!.nome.toUpperCase()}'
                  : 'HISTÓRICO DE MENSALIDADES',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Fatura>>(
              future: _faturasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: AppColors.orangePrimary),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar pagamentos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final faturas = snapshot.data ?? [];

                if (faturas.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'Nenhum pagamento registrado para este aluno.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: faturas.length,
                  itemBuilder: (context, index) {
                    return _FaturaTile(
                      fatura: faturas[index],
                      isAdmin: widget.isAdmin,
                      onPagamentoConcluido: () => _carregarFaturasAluno(targetId),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- DIÁLOGO PARA REGISTRAR NOVO PAGAMENTO ---
  void _exibirDialogoNovoPagamento(BuildContext context, {String? alunoIdInicial}) {
    final usuarioController = TextEditingController(text: alunoIdInicial ?? '');
    final valorController = TextEditingController(text: '80.00');
    final mesRefController = TextEditingController(text: 'Setembro 2026');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'REGISTRAR NOVO PAGAMENTO',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usuarioController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'ID do Aluno',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valorController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mesRefController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Mês / Referência',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final id = int.tryParse(usuarioController.text);
                  final valor = double.tryParse(valorController.text);

                  if (id == null || valor == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preencha os campos corretamente.')),
                    );
                    return;
                  }

                  final dataHoje = DateTime.now().toIso8601String().split('T')[0];
                  final sucesso = await FinanceiroRepository.registrarPagamento(
                    usuarioId: id,
                    valor: valor,
                    dataPagamento: dataHoje,
                    mesReferencia: mesRefController.text,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    if (sucesso) {
                      if (_alunoSelecionado != null) {
                        _carregarFaturasAluno(int.parse(_alunoSelecionado!.id));
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pagamento registrado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangePrimary,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('CONFIRMAR REGISTRO',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlanoCard extends StatelessWidget {
  final PlanoAssinatura plano;
  const _PlanoCard({required this.plano});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                plano.nome.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.orangePrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'ATIVO',
                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'R\$ ${plano.valorMensal.toStringAsFixed(2).replaceAll('.', ',')} / ${plano.ciclo.toLowerCase()}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _FaturaTile extends StatelessWidget {
  final Fatura fatura;
  final bool isAdmin;
  final VoidCallback onPagamentoConcluido;

  const _FaturaTile({
    required this.fatura,
    required this.isAdmin,
    required this.onPagamentoConcluido,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPago = fatura.status == StatusPagamento.pago;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fatura.descricao,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'R\$ ${fatura.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vencimento: ${fatura.dataVencimento.day.toString().padLeft(2, '0')}/${fatura.dataVencimento.month.toString().padLeft(2, '0')}/${fatura.dataVencimento.year}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPago ? Colors.green : AppColors.orangePrimary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (isPago ? Colors.green : AppColors.orangePrimary).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  isPago ? 'PAGO' : 'PENDENTE',
                  style: TextStyle(
                    color: isPago ? Colors.green : AppColors.orangePrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPago) ...[
            ElevatedButton.icon(
              onPressed: () => ComprovantePdfService.imprimirOuCompartilhar(fatura),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('BAIXAR COMPROVANTE PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.backgroundInput,
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => _exibirDialogoPagamento(context),
              icon: const Icon(Icons.pix, size: 18),
              label: const Text('PAGAR COM PIX / CARTÃO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangePrimary,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _exibirDialogoPagamento(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAGAMENTO DA MENSALIDADE',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.qr_code_2, size: 120, color: AppColors.orangePrimary),
              const SizedBox(height: 12),
              const Text(
                'Copia e Cola Pix:',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundInput,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '00020126360014BR.GOV.BCB.PIX0114+55919999999995204000053039865405149.90',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontFamily: 'monospace'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final ok = await FinanceiroRepository.confirmarPagamentoFatura(fatura.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (ok) {
                      onPagamentoConcluido();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pagamento realizado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangePrimary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 42),
                ),
                child: const Text('CONFIRMAR PAGAMENTO REALIZADO', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}