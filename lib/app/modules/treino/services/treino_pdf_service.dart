import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/treino_model.dart';

class TreinoPdfService {
  static Future<void> gerarECompartilharPdf({
    required String nomeAluno,
    required String matricula,
    required List<FichaTreino> treinos,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // CABEÇALHO DO APLICATIVO
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1E1E1E'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'POWER SHAPE',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#FF8C00'),
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'FICHA DE TREINAMENTO',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Aluno: $nomeAluno',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Matrícula: $matricula',
                        style: const pw.TextStyle(
                          color: PdfColors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // SE NÃO HOUVER TREINOS
            if (treinos.isEmpty)
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Text(
                    'Nenhum treino cadastrado para este aluno.',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

            // LISTA DE FICHAS DE TREINO
            ...treinos.map((ficha) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#333333')),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${ficha.identificador.toUpperCase()} - ${ficha.titulo.toUpperCase()}',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#FF8C00'),
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (ficha.descricao.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        ficha.descricao,
                        style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
                      ),
                    ],
                    pw.SizedBox(height: 10),

                    // TABELA DE EXERCÍCIOS
                    if (ficha.exercicios.isNotEmpty)
                      pw.Table.fromTextArray(
                        headers: ['Exercício', 'Séries', 'Reps', 'Carga (kg)'],
                        data: ficha.exercicios.map((ex) {
                          return [
                            ex.nome,
                            ex.series.toString(),
                            ex.repeticoes,
                            ex.cargaKg > 0 ? '${ex.cargaKg} kg' : '-',
                          ];
                        }).toList(),
                        headerStyle: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                        headerDecoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#2C2C2C'),
                        ),
                        cellStyle: const pw.TextStyle(fontSize: 9),
                        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      )
                    else
                      pw.Text(
                        'Detalhes: ${ficha.descricao}',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                      ),
                  ],
                ),
              );
            }).toList(),
          ];
        },
      ),
    );

    // ABRE A INTERFACE NATIVA DE IMPRESSÃO / COMPARTILHAMENTO / SALVAR EM PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ficha_Treino_$nomeAluno.pdf',
    );
  }
}