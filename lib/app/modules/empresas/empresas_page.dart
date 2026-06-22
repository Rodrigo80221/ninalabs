import 'package:flutter/material.dart';
import '../../core/services/baserow_service.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/models/content_model.dart';
import 'empresa_form_page.dart';

class EmpresasPage extends StatefulWidget {
  const EmpresasPage({super.key});

  @override
  State<EmpresasPage> createState() => _EmpresasPageState();
}

class _EmpresasPageState extends State<EmpresasPage> {
  final BaserowService _baserowService = BaserowService();
  List<AccountModel> _accounts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accounts = await _baserowService.fetchAccounts();
      setState(() {
        _accounts = accounts;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empresas'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EmpresaFormPage(),
            ),
          );
          if (result == true) {
            _loadAccounts();
          }
        },
        backgroundColor: AppColors.terracotta,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.terracotta));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erro: $_errorMessage', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAccounts,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_accounts.isEmpty) {
      return const Center(child: Text('Nenhuma empresa encontrada.'));
    }

    return ListView.builder(
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.terracotta,
            child: Icon(Icons.business, color: Colors.white),
          ),
          title: Text(account.accountName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: account.informacoesDaEmpresa != null && account.informacoesDaEmpresa!.isNotEmpty
              ? Text(
                  account.informacoesDaEmpresa!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : const Text('Sem informações', style: TextStyle(color: AppColors.textLight)),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmpresaFormPage(account: account),
              ),
            );
            if (result == true) {
              _loadAccounts();
            }
          },
        );
      },
    );
  }
}
