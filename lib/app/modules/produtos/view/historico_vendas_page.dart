import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../repositories/produto_repository.dart';

class HistoricoVendasPage extends StatefulWidget {
  const HistoricoVendasPage({super.key});

  @override
  State<HistoricoVendasPage> createState() => _HistoricoVendasPageState();
}

class _HistoricoVendasPageState extends State<HistoricoVendasPage> {
  List<Map<String, dynamic>> _vendas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _isLoading = true);
    final historico = await ProdutoRepository.getHistoricoVendas();
    if (mounted) {
      setState(() {
        _vendas = historico;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Vendas'),
        backgroundColor: AppColors.backgroundSecondary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orangePrimary))
          : _vendas.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma venda registrada até o momento.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vendas.length,
                  itemBuilder: (context, index) {
                    final item = _vendas[index];
                    final double valorTotal = double.tryParse(item['valor_total']?.toString() ?? '0') ?? 0.0;
                    final String dataFormatada = item['data_venda'] != null
                        ? item['data_venda'].toString().replaceAll('T', ' ').substring(0, 16)
                        : '--';
                    final String pagamento = item['metodo_pagamento']?.toString().toUpperCase() ?? 'N/A';
                    final String categoria = item['produto_categoria']?.toString().toUpperCase() ?? 'FREEZER';
                    final bool isFreezer = categoria == 'FREEZER';

                    return Card(
                      color: AppColors.backgroundCard,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          isFreezer ? Icons.kitchen : Icons.fitness_center,
                          color: AppColors.orangePrimary,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item['quantidade']}x ${item['produto_nome']}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isFreezer ? Colors.blue.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isFreezer ? 'FREEZER' : 'SUPLEMENTO',
                                style: TextStyle(
                                  color: isFreezer ? Colors.lightBlueAccent : Colors.purpleAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Vendedor: ${item['vendedor_nome'] ?? 'Sistema'}\nPagamento: $pagamento\nData: $dataFormatada',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        trailing: Text(
                          'R\$ ${valorTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.orangePrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}