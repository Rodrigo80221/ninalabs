import 'package:flutter/material.dart';
import '../../core/components/custom_dropdown.dart';
import '../../core/theme/app_colors.dart';
import 'controllers/dashboard_controller.dart';
import 'widgets/social_post_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardController _controller = DashboardController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nina Labs'),
      ),
      body: Column(
        children: [
          if (_controller.isLoading)
            const LinearProgressIndicator(color: AppColors.terracotta),
          if (!_controller.isLoading && _controller.errorMessage == null)
            _buildFilters(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _buildBodyContent(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _controller.currentTabIndex,
        onTap: _controller.setTabIndex,
        selectedItemColor: AppColors.terracotta,
        unselectedItemColor: AppColors.textLight,
        backgroundColor: AppColors.surface,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            activeIcon: Icon(Icons.build_circle),
            label: 'Em Construção',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed_outlined),
            activeIcon: Icon(Icons.dynamic_feed),
            label: 'Finalizados',
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.terracotta));
    }
    if (_controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Erro: ${_controller.errorMessage}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    return _controller.currentTabIndex == 0 ? _buildPendingSection() : _buildFeedSection();
  }

  Widget _buildFilters() {
    final accountNames = ['Todas', ..._controller.accounts.map((a) => a.accountName)];
    final templateNames = ['Todos', ..._controller.templates.map((t) => t.name)];
    
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          CustomDropdown(
            label: 'Empresa',
            hint: 'Selecionar Empresa',
            value: _controller.selectedCompany ?? 'Todas',
            items: accountNames,
            onChanged: (value) {
              if (value != null) {
                _controller.setCompany(value);
              }
            },
          ),
          const SizedBox(height: 8),
          CustomDropdown(
            label: 'Template de Conteúdo',
            hint: 'Modelo',
            value: _controller.selectedTemplate,
            items: templateNames,
            onChanged: (value) {
              if (value != null) {
                _controller.setTemplate(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    final contents = _controller.pendingContents;
    
    if (contents.isEmpty) {
      return const Center(child: Text('Nenhum conteúdo em construção.'));
    }

    return ListView.builder(
      itemCount: contents.length,
      itemBuilder: (context, index) {
        return SocialPostCard(content: contents[index]);
      },
    );
  }

  Widget _buildFeedSection() {
    final contents = _controller.postedContents;

    if (contents.isEmpty) {
      return const Center(child: Text('Nenhum conteúdo finalizado.'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
          if (_controller.hasMoreFeed) {
            _controller.loadMoreFeed();
          }
        }
        return false;
      },
      child: ListView.builder(
        itemCount: contents.length + (_controller.hasMoreFeed ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == contents.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
            );
          }
          return SocialPostCard(content: contents[index]);
        },
      ),
    );
  }
}
