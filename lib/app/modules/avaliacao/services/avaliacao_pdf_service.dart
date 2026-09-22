import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AvaliacaoPdfService {
  static Future<void> gerarECompartilharPdf({
    required String nomeAluno,
    required String sexo,
    required int idade,
    required double peso,
    required double percentualGordura,
    required double massaMagraKg,
    required double massaGordaKg,
    required String historicoSaude,
    required String objetivo,
  }) async {
    final pdf = pw.Document();

    final primaryOrange = PdfColor.fromHex('#FF8C00');
    final darkBg = PdfColor.fromHex('#121212');
    final cardBg = PdfColor.fromHex('#1E1E1E');
    final textWhite = PdfColor.fromHex('#FFFFFF');
    final textMuted = PdfColor.fromHex('#A0A0A0');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            color: darkBg,
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // CABEÇALHO
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'POWER SHAPE',
                      style: pw.TextStyle(
                        color: primaryOrange,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'RELATÓRIO DE AVALIAÇÃO FÍSICA',
                      style: pw.TextStyle(color: textWhite, fontSize: 12),
                    ),
                  ],
                ),
                pw.Divider(color: primaryOrange, thickness: 1.5),
                pw.SizedBox(height: 16),

                // DADOS DO ALUNO
                pw.Text('DADOS DO ATLETA', style: pw.TextStyle(color: primaryOrange, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  color: cardBg,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Nome: $nomeAluno', style: pw.TextStyle(color: textWhite)),
                      pw.SizedBox(height: 4),
                      pw.Text('Idade: $idade anos  |  Sexo: $sexo  |  Peso: ${peso}kg', style: pw.TextStyle(color: textMuted)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),

                // COMPOSIÇÃO CORPORAL
                pw.Text('COMPOSIÇÃO CORPORAL', style: pw.TextStyle(color: primaryOrange, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        color: cardBg,
                        child: pw.Column(
                          children: [
                            pw.Text('% GORDURA', style: pw.TextStyle(color: textMuted, fontSize: 10)),
                            pw.Text('${percentualGordura.toStringAsFixed(1)}%', style: pw.TextStyle(color: primaryOrange, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        color: cardBg,
                        child: pw.Column(
                          children: [
                            pw.Text('MASSA MAGRA', style: pw.TextStyle(color: textMuted, fontSize: 10)),
                            pw.Text('${massaMagraKg.toStringAsFixed(1)} kg', style: pw.TextStyle(color: textWhite, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        color: cardBg,
                        child: pw.Column(
                          children: [
                            pw.Text('MASSA GORDA', style: pw.TextStyle(color: textMuted, fontSize: 10)),
                            pw.Text('${massaGordaKg.toStringAsFixed(1)} kg', style: pw.TextStyle(color: textWhite, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),

                // ANAMNESE
                pw.Text('RESUMO DA ANAMNESE', style: pw.TextStyle(color: primaryOrange, fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  color: cardBg,
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Objetivo:', style: pw.TextStyle(color: primaryOrange, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(objetivo, style: pw.TextStyle(color: textWhite)),
                      pw.SizedBox(height: 8),
                      pw.Text('Histórico de Saúde / Lesões:', style: pw.TextStyle(color: primaryOrange, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(historicoSaude, style: pw.TextStyle(color: textWhite)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Avaliacao_Fisica_$nomeAluno.pdf',
    );
  }
}