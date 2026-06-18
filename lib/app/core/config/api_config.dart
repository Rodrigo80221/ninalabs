class ApiConfig {
  static const String webhookBaseUrl = 'https://n8n.progridai.com.br/webhook';

  // Endpoints
  static const String continuarProducao = '$webhookBaseUrl/continuarProdução';
  static const String criarNovoPost = '$webhookBaseUrl/criarNovoPost';
}
