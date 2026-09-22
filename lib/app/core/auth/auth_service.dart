enum TipoPerfil { admin, personal, aluno }

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  TipoPerfil perfilAtual = TipoPerfil.aluno;
  Map<String, dynamic>? usuarioLogado;

  // Getters para checagem rápida de permissão
  bool get isAdmin => perfilAtual == TipoPerfil.admin;
  bool get isPersonal => perfilAtual == TipoPerfil.personal;

  /// Retorna true se for Admin OU Personal/Professor (para telas/operações de gestão de treinos e alunos)
  bool get isGestor => isAdmin || isPersonal;

  String get nomeCompleto => usuarioLogado?['nome'] ?? (isGestor ? 'Treinador' : 'Atleta');

  // Retorna apenas o Primeiro e Último Nome (Ex: "Gabriel Silva")
  String get nomeExibicao {
    final nomeLimpo = nomeCompleto.trim();
    if (nomeLimpo.isEmpty) return isGestor ? 'Treinador' : 'Atleta';

    final partes = nomeLimpo.split(RegExp(r'\s+'));
    if (partes.length <= 1) {
      return partes.first;
    }

    return '${partes.first} ${partes.last}';
  }

  String get fotoUrl => usuarioLogado?['foto_url'] ?? '';
  String get matricula => usuarioLogado?['matricula'] ?? '';
  String get email => usuarioLogado?['email'] ?? '';

  void deslogar() {
    usuarioLogado = null;
    perfilAtual = TipoPerfil.aluno;
  }
}