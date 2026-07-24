import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/baserow_service.dart';
import '../../../core/services/webhook_service.dart';
import '../../../core/models/api_response.dart';
import '../models/content_model.dart';


class DashboardController extends ChangeNotifier {
  final BaserowService _baserowService = BaserowService();
  
  List<AccountModel> _accounts = [];
  List<TemplateModel> _templates = [];
  List<ContentModel> _contents = [];
  
  bool isLoading = true;
  String? errorMessage;

  // Polling State
  final Set<int> pollingPostIds = {};

  void setPolling(int id, bool isPolling) {
    if (isPolling) {
      pollingPostIds.add(id);
    } else {
      pollingPostIds.remove(id);
    }
  }

  // Navigation State
  int _currentTabIndex = 0; // 0 = Finalizados, 1 = Em Construção
  
  // Filter & Pagination State
  String? _selectedCompany;
  String _selectedTemplate = 'Todos';
  int _feedLimit = 10;

  DashboardController() {
    loadData();
  }

  // Getters
  int get currentTabIndex => _currentTabIndex;
  String? get selectedCompany => _selectedCompany;
  String get selectedTemplate => _selectedTemplate;
  
  List<AccountModel> get accounts => _accounts;
  List<TemplateModel> get allTemplates => _templates;
  
  List<TemplateModel> get templates {
    if (_selectedCompany == null) {
      return _templates;
    } else {
      try {
        final company = _accounts.firstWhere((a) => a.accountName == _selectedCompany);
        return _templates.where((t) => company.templateIds.contains(t.id)).toList();
      } catch (e) {
        return _templates;
      }
    }
  }

  // Filtered lists
  List<ContentModel> get pendingContents {
    final filtered = _applyFilters(_contents.where((c) => c.status == 'Pendente').toList());
    // Ordem decrescente por DataHora
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  List<ContentModel> get postedContents {
    final filtered = _applyFilters(_contents.where((c) => c.status == 'Postado' || c.status == 'Agendado').toList());
    // Ordem decrescente por DataHora
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered.take(_feedLimit).toList();
  }

  bool get hasMoreFeed {
    final filtered = _applyFilters(_contents.where((c) => c.status == 'Postado' || c.status == 'Agendado').toList());
    return _feedLimit < filtered.length;
  }

  void loadMoreFeed() {
    _feedLimit += 10;
    notifyListeners();
  }

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedCompany ??= prefs.getString('selectedCompany');
      if (_selectedTemplate == 'Todos') {
        _selectedTemplate = prefs.getString('selectedTemplate') ?? 'Todos';
      }

      // Fetch data in parallel
      final results = await Future.wait([
        _baserowService.fetchAccounts(),
        _baserowService.fetchTemplates(),
      ]);
      
      _accounts = results[0] as List<AccountModel>;
      _templates = results[1] as List<TemplateModel>;
      
      if (_accounts.isNotEmpty && _selectedCompany == null) {
        _selectedCompany = _accounts.first.accountName; // Default select first
      } else if (_selectedCompany != null) {
        final companyExists = _accounts.any((a) => a.accountName == _selectedCompany);
        if (!companyExists) {
          _selectedCompany = _accounts.isNotEmpty ? _accounts.first.accountName : null;
          _selectedTemplate = 'Todos';
        }
      }

      // We need the accounts list to resolve the content links properly
      _contents = await _baserowService.fetchPosts(_accounts);

      if (_selectedTemplate != 'Todos') {
        final templateExists = _templates.any((t) => t.name == _selectedTemplate);
        if (!templateExists) {
          _selectedTemplate = 'Todos';
        }
      }

    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePost(int id) async {
    try {
      final updatedPost = await _baserowService.fetchPost(id, _accounts);
      final index = _contents.indexWhere((c) => c.id == id);
      if (index != -1) {
        _contents[index] = updatedPost;
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao atualizar post: $e');
    }
  }

  Future<ApiResponse> criarConteudo(AccountModel company, int codigoContrato, DateTime scheduleDate, {bool apenasGerarIdeia = false, String? observacaoDoUsuario}) async {
    try {
      final idRow = await _baserowService.createPostRow(
        scheduleDate: scheduleDate,
        companyId: company.id,
        templateId: codigoContrato,
        idInstagramLinked: company.idInstagramLinked,
        observacaoDoUsuario: observacaoDoUsuario,
      );
      // Dispara o webhook em background sem bloquear a UI
      WebhookService.criarNovoPost(
        codigoEmpresa: company.id,
        codigoContrato: codigoContrato,
        idRow: idRow,
        dataAgendamento: scheduleDate,
        apenasGerarIdeia: apenasGerarIdeia,
      ).then((response) {
        if (!response.success) {
          print('Erro no webhook em background: ${response.message}');
          setPolling(idRow, false);
          
          final index = _contents.indexWhere((c) => c.id == idRow);
          if (index != -1) {
            _contents[index].hasError = true;
          }
          notifyListeners();
        } else if (apenasGerarIdeia) {
          setPolling(idRow, false);
          loadData();
        }
      });

      // Adiciona na timeline imediatamente
      pollingPostIds.add(idRow);
      await loadData();

      return ApiResponse(success: true);
    } catch (e) {
      print('Erro ao criar conteudo: $e');
      return ApiResponse(success: false, message: 'Erro ao criar conteudo: $e');
    }
  }

  Future<bool> deletarConteudo(int postId) async {
    try {
      await _baserowService.deletePostRow(postId);
      _contents.removeWhere((c) => c.id == postId);
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao deletar conteudo: $e');
      return false;
    }
  }

  List<ContentModel> _applyFilters(List<ContentModel> list) {
    return list.where((content) {
      final matchCompany = _selectedCompany == null || content.companyName == _selectedCompany;
      final matchTemplate = _selectedTemplate == 'Todos' || content.templateName == _selectedTemplate;
      return matchCompany && matchTemplate;
    }).toList();
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void setCompany(String company) async {
    _selectedCompany = company;
    _selectedTemplate = 'Todos'; // Reset template on company change
    _feedLimit = 10; // Reset pagination
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCompany', company);
    await prefs.setString('selectedTemplate', 'Todos');
  }

  void setTemplate(String template) async {
    _selectedTemplate = template;
    _feedLimit = 10; // Reset pagination
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTemplate', template);
  }
}
