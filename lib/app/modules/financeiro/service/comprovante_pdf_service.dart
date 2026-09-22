import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/financeiro_model.dart';

class ComprovantePdfService {
  static Future<Uint8List> gerarComprovante(Fatura fatura) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cabecalho
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'POWER SHAPE FITNESS',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                    pw.Text(
                      'RECIBO DE PAGAMENTO',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 20),

                // Detalhes da Transação
                _buildInfoRow('ID do Comprovante:', '#${fatura.id}'),
                _buildInfoRow('Aluno:', fatura.alunoNome ?? 'ID Aluno: ${fatura.usuarioId}'),
                _buildInfoRow('Descrição:', fatura.descricao),
                _buildInfoRow(
                  'Data de Pagamento:',
                  '${fatura.dataVencimento.day.toString().padLeft(2, '0')}/${fatura.dataVencimento.month.toString().padLeft(2, '0')}/${fatura.dataVencimento.year}',
                ),
                _buildInfoRow('Forma de Pagamento:', fatura.formaPagamento ?? 'Pix / Cartão'),
                _buildInfoRow('Status:', 'CONCLUÍDO (PAGO)', color: PdfColors.green700),
                
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 10),

                // Valor Final
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'VALOR TOTAL:',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'R\$ ${fatura.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Rodapé / Assinatura
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: PdfColors.grey600,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Assinatura da Administração',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

static pw.Widget _buildInfoRow(String label, String value, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.DefaultTextStyle(
        style: const pw.TextStyle(fontSize: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(color: color ?? PdfColors.black),
            ),
          ],
        ),
      ),
    );
  }

  // Abre a tela de pré-visualização, impressão e compartilhamento
  static Future<void> imprimirOuCompartilhar(Fatura fatura) async {
    final pdfBytes = await gerarComprovante(fatura);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Comprovante_${fatura.id}.pdf',
    );
  }
}