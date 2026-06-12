import 'package:flutter/material.dart';
import '../../../core/services/baserow_service.dart';
import '../models/content_model.dart';

class DashboardController extends ChangeNotifier {
  final BaserowService _baserowService = BaserowService();
  
  List<AccountModel> _accounts = [];
  List<TemplateModel> _templates = [];
  List<ContentModel> _contents = [];
  
  bool isLoading = true;
  String? errorMessage;

  // Navigation State
  int _currentTabIndex = 0; // 0 = Em Construção, 1 = Finalizados
  
  // Filter & Pagination State
  String? _selectedCompany;
  String _selectedTemplate = 'Todos';
  int _feedLimit = 10;

  DashboardController() {
    _loadData();
  }

  // Getters
  int get currentTabIndex => _currentTabIndex;
  String? get selectedCompany => _selectedCompany;
  String get selectedTemplate => _selectedTemplate;
  
  List<AccountModel> get accounts => _accounts;
  
  List<TemplateModel> get templates {
    if (_selectedCompany == null || _selectedCompany == 'Todas') {
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
    final filtered = _applyFilters(_contents.where((c) => c.status == 'Postado').toList());
    // Ordem decrescente por DataHora
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered.take(_feedLimit).toList();
  }

  bool get hasMoreFeed {
    final filtered = _applyFilters(_contents.where((c) => c.status == 'Postado').toList());
    return _feedLimit < filtered.length;
  }

  void loadMoreFeed() {
    _feedLimit += 10;
    notifyListeners();
  }

  Future<void> _loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Fetch data in parallel
      final results = await Future.wait([
        _baserowService.fetchAccounts(),
        _baserowService.fetchTemplates(),
      ]);
      
      _accounts = results[0] as List<AccountModel>;
      _templates = results[1] as List<TemplateModel>;
      
      if (_accounts.isNotEmpty) {
        _selectedCompany = _accounts.first.accountName; // Default select first
      }

      // We need the accounts list to resolve the content links properly
      _contents = await _baserowService.fetchPosts(_accounts);

    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<ContentModel> _applyFilters(List<ContentModel> list) {
    return list.where((content) {
      final matchCompany = _selectedCompany == null || _selectedCompany == 'Todas' || content.companyName == _selectedCompany;
      final matchTemplate = _selectedTemplate == 'Todos' || content.templateName == _selectedTemplate;
      return matchCompany && matchTemplate;
    }).toList();
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void setCompany(String company) {
    _selectedCompany = company;
    _selectedTemplate = 'Todos'; // Reset template on company change
    _feedLimit = 10; // Reset pagination
    notifyListeners();
  }

  void setTemplate(String template) {
    _selectedTemplate = template;
    _feedLimit = 10; // Reset pagination
    notifyListeners();
  }
}
