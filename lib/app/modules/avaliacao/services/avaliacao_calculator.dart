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
  /// Retorna o valor de uma dobra buscando por chaves equivalentes/sinônimos
  static double _getValorDobra(Map<String, double> dobras, List<String> chaves) {
    for (var k in chaves) {
      if (dobras.containsKey(k) && dobras[k] != null) {
        return dobras[k]!;
      }
    }
    return 0.0;
  }

  /// Calcula a soma de dobras normalizando variações de nomes nas chaves
  static double _sum(Map<String, double> dobras, List<List<String>> listaChaves) {
    double soma = 0.0;
    for (var chavesPossiveis in listaChaves) {
      soma += _getValorDobra(dobras, chavesPossiveis);
    }
    return soma;
  }

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

    // Mapeamento de sinônimos de dobras cutâneas
    final tricepsKeys = ['triceps', 'tricipital'];
    final subescapularKeys = ['subescapular', 'subEscapular'];
    final suprailiacaKeys = ['suprailiaca', 'supraIliaca', 'supra_iliaca'];
    final abdominalKeys = ['abdominal', 'abdomen'];
    final coxaKeys = ['coxa'];
    final peitoralKeys = ['peitoral', 'peito'];
    final axilarMediaKeys = ['axilarMedia', 'axilar_media', 'axilar'];
    final bicipitalKeys = ['bicipital', 'biceps'];
    final gastrocnemioKeys = ['gastrocnemio', 'panturrilha'];

    double dc = 1.0; // Densidade Corporal
    double percGordura = 0.0;
    final proto = protocolo.toUpperCase().trim();

    // --- PROTOCOLO JACKSON & POLLOCK 3 DOBRAS (JP3) ---
    if (proto == 'JP3') {
      if (sexo.toUpperCase() == 'M') {
        final soma3 = _sum(dobras, [peitoralKeys, abdominalKeys, coxaKeys]);
        dc = 1.109380 - (0.0008267 * soma3) + (0.0000016 * soma3 * soma3) - (0.0002574 * idade);
      } else {
        final soma3 = _sum(dobras, [tricepsKeys, suprailiacaKeys, coxaKeys]);
        dc = 1.0994921 - (0.0009929 * soma3) + (0.0000023 * soma3 * soma3) - (0.0001392 * idade);
      }
      percGordura = ((4.95 / dc) - 4.50) * 100;

    // --- PROTOCOLO JACKSON & POLLOCK 7 DOBRAS (JP7) ---
    } else if (proto == 'JP7') {
      // 7 Dobras: Peitoral, Axilar Média, Subescapular, Tricipital, Abdominal, Suprailíaca, Coxa (Bicipital removido)
      final soma7 = _sum(dobras, [
        peitoralKeys,
        axilarMediaKeys,
        subescapularKeys,
        tricepsKeys,
        abdominalKeys,
        suprailiacaKeys,
        coxaKeys
      ]);

      if (sexo.toUpperCase() == 'M') {
        dc = 1.1120 - (0.00043499 * soma7) + (0.00000055 * soma7 * soma7) - (0.00028826 * idade);
      } else {
        dc = 1.0970 - (0.00046971 * soma7) + (0.00000056 * soma7 * soma7) - (0.00012828 * idade);
      }
      percGordura = ((4.95 / dc) - 4.50) * 100;

    // --- PROTOCOLO FAULKNER (4 Dobras) ---
    } else if (proto == 'FAULKNER') {
      final soma4 = _sum(dobras, [tricepsKeys, subescapularKeys, suprailiacaKeys, abdominalKeys]);
      percGordura = (soma4 * 0.153) + 5.783;

    // --- PROTOCOLO PETROSKI (4 Dobras) ---
    } else if (proto == 'PETROSKI') {
      if (sexo.toUpperCase() == 'M') {
        final soma4 = _sum(dobras, [subescapularKeys, tricepsKeys, suprailiacaKeys, gastrocnemioKeys]);
        dc = 1.10726863 - (0.00081201 * soma4) + (0.00000212 * soma4 * soma4) - (0.00041761 * idade);
      } else {
        final soma4 = _sum(dobras, [subescapularKeys, suprailiacaKeys, coxaKeys, gastrocnemioKeys]);
        dc = 1.02902413 - (0.00067159 * soma4) + (0.00000242 * soma4 * soma4) - (0.000256 * idade);
      }
      percGordura = ((4.95 / dc) - 4.50) * 100;

    // --- PROTOCOLO GUEDES (3 Dobras) ---
    } else if (proto == 'GUEDES') {
      if (sexo.toUpperCase() == 'M') {
        final soma3 = _sum(dobras, [tricepsKeys, suprailiacaKeys, abdominalKeys]);
        if (soma3 > 0) {
          dc = 1.1714 - (0.0671 * (math.log(soma3) / math.ln10));
        }
      } else {
        final soma3 = _sum(dobras, [subescapularKeys, suprailiacaKeys, coxaKeys]);
        if (soma3 > 0) {
          dc = 1.1668 - (0.0706 * (math.log(soma3) / math.ln10));
        }
      }
      percGordura = ((4.95 / dc) - 4.50) * 100;
    }

    // Proteção contra resultados incorretos ou vazios
    if (percGordura.isNaN || percGordura.isInfinite || percGordura < 0) {
      percGordura = 0.0;
    }

    final massaGordaKg = pesoKg * (percGordura / 100);
    final massaMagraKg = pesoKg - massaGordaKg;

    return AvaliacaoResult(
      percentualGordura: double.parse(percGordura.toStringAsFixed(2)),
      massaMagraKg: double.parse(massaMagraKg.toStringAsFixed(2)),
      massaGordaKg: double.parse(massaGordaKg.toStringAsFixed(2)),
    );
  }
}