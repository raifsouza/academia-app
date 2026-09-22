import 'dart:math' as math;

class AvaliacaoResult {
  final double percentualGordura;
  final double massaMagraKg;
  final double massaGordaKg;

  AvaliacaoResult({
    required this.percentualGordura,
    required this.massaMagraKg,
    required this.massaGordaKg,
  });
}

class AvaliacaoCalculator {
  static AvaliacaoResult calcularComposicao({
    required String sexo, // 'M' ou 'F'
    required int idade,
    required double pesoKg,
    required String protocolo,
    required Map<String, double> dobras, // valores em mm
  }) {
    if (pesoKg <= 0) {
      return AvaliacaoResult(percentualGordura: 0, massaMagraKg: 0, massaGordaKg: 0);
    }

    double dc = 1.0; // Densidade Corporal
    double percGordura = 0.0;

    double sum(List<String> keys) => keys.fold(0.0, (s, k) => s + (dobras[k] ?? 0.0));

    if (protocolo == 'JP3') {
      if (sexo == 'M') {
        final soma3 = sum(['peitoral', 'abdominal', 'coxa']);
        dc = 1.109380 - (0.0008267 * soma3) + (0.0000016 * soma3 * soma3) - (0.0002574 * idade);
      } else {
        final soma3 = sum(['tricipital', 'suprailiaca', 'coxa']);
        dc = 1.0994921 - (0.0009929 * soma3) + (0.0000023 * soma3 * soma3) - (0.0001392 * idade);
      }
      percGordura = ((4.95 / dc) - 4.50) * 100;

    } else if (protocolo == 'JP7') {
      final soma7 = sum(['subescapular', 'bicipital', 'tricipital', 'axilarMedia', 'suprailiaca', 'peitoral', 'abdominal', 'coxa']);
      if (sexo == 'M') {
        dc = 1.1120 - (0.00043499 * soma7) + (0.00000055 * soma7 * soma7) - (0.00028826 * idade);
      } else {
        dc = 1.0970 - (0.00046971 * soma7) + (0.00000056 * soma7 * soma7) - (0.00012828 * idade);
      }
      percGordura = ((4.95 / dc) - 4.50) * 100;

    } else if (protocolo == 'FAULKNER') {
      final soma4 = sum(['triceps', 'subescapular', 'suprailiaca', 'abdominal']);
      percGordura = (soma4 * 0.153) + 5.783;

    } else if (protocolo == 'PETROSKI') {
      if (sexo == 'M') {
        final soma4 = sum(['subescapular', 'triceps', 'suprailiaca', 'gastrocnemio']);
        dc = 1.10726863 - (0.00081201 * soma4) + (0.00000212 * soma4 * soma4) - (0.00041761 * idade);
      } else {
        final soma4 = sum(['subescapular', 'suprailiaca', 'coxa', 'gastrocnemio']);
        dc = 1.02902413 - (0.00067159 * soma4) + (0.00000242 * soma4 * soma4) - (0.000256 * idade);
      }
      percGordura = ((4.95 / dc) - 4.50) * 100;

    } else if (protocolo == 'GUEDES') {
      if (sexo == 'M') {
        final soma3 = sum(['triceps', 'suprailiaca', 'abdominal']);
        dc = 1.1714 - (0.0671 * math.log(soma3) / math.ln10);
      } else {
        final soma3 = sum(['subescapular', 'suprailiaca', 'coxa']);
        dc = 1.1668 - (0.0706 * math.log(soma3) / math.ln10);
      }
      percGordura = ((4.95 / dc) - 4.50) * 100;
    }

    if (percGordura.isNaN || percGordura.isInfinite || percGordura < 0) {
      percGordura = 0.0;
    }

    final massaGordaKg = pesoKg * (percGordura / 100);
    final massaMagraKg = pesoKg - massaGordaKg;

    return AvaliacaoResult(
      percentualGordura: percGordura,
      massaMagraKg: massaMagraKg,
      massaGordaKg: massaGordaKg,
    );
  }
}