import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../models/produto_model.dart';
import '../repositories/produto_repository.dart';
import 'historico_vendas_page.dart';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  List<Produto> _produtos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() => _isLoading = true);
    final produtos = await ProdutoRepository.getProdutos();
    if (mounted) {
      setState(() {
        _produtos = produtos;
        _isLoading = false;
      });
    }
  }

  void _abrirModalVenda(Produto produto) {
    int quantidade = 1;
    String metodoSelecionado = 'PIX';

    final Map<String, String> opcoesPagamento = {
      'PIX': 'Pix',
      'DINHEIRO': 'Dinheiro',
      'DEBITO': 'Débito',
      'CREDITO': 'Crédito',
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          final total = produto.preco * quantidade;

          return AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            title: Text(
              'Vender ${produto.nome}',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: AppColors.orangePrimary),
                      onPressed: quantidade > 1
                          ? () => setStateModal(() => quantidade--)
                          : null,
                    ),
                    Text(
                      '$quantidade',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.orangePrimary),
                      onPressed: () => setStateModal(() => quantidade++),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Forma de Pagamento:',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: opcoesPagamento.entries.map((entry) {
                    final bool isSelected = metodoSelecionado == entry.key;
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      selectedColor: AppColors.orangePrimary,
                      backgroundColor: AppColors.backgroundInput,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setStateModal(() => metodoSelecionado = entry.key);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Total: R\$ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.orangePrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCELAR', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.orangePrimary),
                onPressed: () async {
                  final auth = AuthService();
                  final vendedorId = int.tryParse(auth.usuarioLogado?['id']?.toString() ?? '0') ?? 0;

                  final sucesso = await ProdutoRepository.registrarVenda(
                    produtoId: produto.id ?? 0,
                    quantidade: quantidade,
                    usuarioIdVendedor: vendedorId,
                    metodoPagamento: metodoSelecionado,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          sucesso ? 'Venda realizada com sucesso!' : 'Erro ao registrar venda.',
                        ),
                      ),
                    );
                    _carregarProdutos();
                  }
                },
                child: const Text('CONFIRMAR VENDA', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _abrirModalNovoProduto() {
    final nomeController = TextEditingController();
    final precoController = TextEditingController();
    final estoqueController = TextEditingController();
    String categoriaSelecionada = 'FREEZER';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Cadastrar Produto', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto (ex: Água 500ml)',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$)',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: estoqueController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Quantidade em Estoque',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: categoriaSelecionada,
                dropdownColor: AppColors.backgroundCard,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Origem / Categoria',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'FREEZER',
                    child: Text('Freezer (Bebidas)'),
                  ),
                  DropdownMenuItem(
                    value: 'SUPLEMENTO',
                    child: Text('Suplementos / Outros'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setStateModal(() => categoriaSelecionada = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orangePrimary),
              onPressed: () async {
                final novo = Produto(
                  nome: nomeController.text,
                  preco: double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0.0,
                  estoque: int.tryParse(estoqueController.text) ?? 0,
                  categoria: categoriaSelecionada,
                );

                final ok = await ProdutoRepository.criarProduto(novo);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (ok) _carregarProdutos();
                }
              },
              child: const Text('SALVAR', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lanchonete / Loja'),
        backgroundColor: AppColors.backgroundSecondary,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.history, color: AppColors.orangePrimary),
              tooltip: 'Histórico de Vendas',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoricoVendasPage(),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orangePrimary))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _produtos.length,
              itemBuilder: (context, index) {
                final prod = _produtos[index];
                final bool isFreezer = prod.categoria == 'FREEZER';

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
                            prod.nome,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
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
                      'Estoque: ${prod.estoque} un',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'R\$ ${prod.preco.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.orangePrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_checkout, color: Colors.green),
                          onPressed: () => _abrirModalVenda(prod),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: AppColors.orangePrimary,
              onPressed: _abrirModalNovoProduto,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }
}