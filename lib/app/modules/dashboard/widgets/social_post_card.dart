import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/components/status_badge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/webhook_service.dart';
import '../models/content_model.dart';

class SocialPostCard extends StatefulWidget {
  final ContentModel content;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onDelete;

  const SocialPostCard({super.key, required this.content, this.onRefresh, this.onDelete});

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isWaitingForWebhook = false;
  int _secondsRemaining = 600; // 10 minutes
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startWaiting() {
    setState(() {
      _isWaitingForWebhook = true;
      _secondsRemaining = 600;
    });

    _animationController.repeat();

    _countdownTimer?.cancel();
    _refreshTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _stopWaiting();
        }
      });
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }
      
      if (!mounted) return;
      // Check if all steps are completed
      final allCompleted = widget.content.productionSteps.every((step) => step.isCompleted);
      if (allCompleted) {
        _stopWaiting();
      }
    });
  }

  void _stopWaiting() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _animationController.stop();
    if (mounted) {
      setState(() {
        _isWaitingForWebhook = false;
      });
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.quartzPink,
            child: Text(
              widget.content.companyName.isNotEmpty ? widget.content.companyName[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.content.templateName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (widget.content.status == 'Pendente' && widget.content.date.isNotEmpty)
                  Text(
                    'Última alteração: ${widget.content.date}',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (widget.content.status != 'Pendente')
            StatusBadge(status: widget.content.status),
          if (widget.content.status == 'Pendente')
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: Colors.red),
                          title: const Text('Excluir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            showDialog(
                              context: context,
                              builder: (ctx2) => AlertDialog(
                                title: const Text('Excluir Conteúdo'),
                                content: const Text('Tem certeza que deseja excluir este conteúdo? Esta ação não pode ser desfeita.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx2).pop(false),
                                    child: const Text('Cancelar', style: TextStyle(color: AppColors.textLight)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(ctx2).pop(true);
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Excluir', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ).then((confirmed) {
                              if (confirmed == true && widget.onDelete != null) {
                                widget.onDelete!();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        color: Colors.black,
        width: double.infinity,
        child: Image.network(
          widget.content.imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.quartzPink.withAlpha(76),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported_outlined, size: 32, color: AppColors.terracotta),
                SizedBox(height: 8),
                Text(
                  'Ainda sem imagem gerada',
                  style: TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.bold, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    if (widget.content.description.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () {
          setState(() => _isExpanded = !_isExpanded);
        },
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            children: [
              TextSpan(
                text: widget.content.companyName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: _isExpanded
                    ? widget.content.description
                    : (widget.content.description.length > 50
                        ? '${widget.content.description.substring(0, 50).replaceAll('\n', ' ')}...'
                        : widget.content.description),
              ),
              if (widget.content.description.length > 50)
                TextSpan(
                  text: _isExpanded ? ' menos' : ' mais',
                  style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    if (widget.content.status != 'Pendente') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produção de Conteúdo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          ...widget.content.productionSteps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final nextStepIndex = widget.content.productionSteps.indexWhere((s) => !s.isCompleted);
            final isNextStep = _isWaitingForWebhook && index == nextStepIndex;

            final stepWidget = Row(
              children: [
                Icon(
                  step.isCompleted ? Icons.check_circle : (isNextStep ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  color: isNextStep ? AppColors.terracotta : (step.isCompleted ? Colors.green : Colors.grey),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: isNextStep ? AppColors.terracotta : (step.isCompleted ? AppColors.textDark : AppColors.textLight),
                      fontWeight: isNextStep ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: isNextStep
                  ? AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        final opacity = 0.4 + 0.6 * (0.5 * (1 + math.sin(_animationController.value * math.pi * 2)));
                        return Opacity(
                          opacity: opacity,
                          child: child,
                        );
                      },
                      child: stepWidget,
                    )
                  : stepWidget,
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isLoading || _isWaitingForWebhook) ? null : () async {
                setState(() => _isLoading = true);
                
                final success = await WebhookService.continuarProducao(
                  codigoEmpresa: widget.content.companyId,
                  codigoContrato: widget.content.templateId,
                  idRow: widget.content.id,
                );
                
                if (!mounted) return;
                setState(() => _isLoading = false);
                
                if (success) {
                  _startWaiting();
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Ação enviada com sucesso!' : 'Erro ao enviar ação para o webhook.'),
                    backgroundColor: success ? Colors.green : AppColors.terracotta,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : _isWaitingForWebhook
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RotationTransition(
                              turns: _animationController,
                              child: const Icon(Icons.refresh, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Aguardando... ${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        )
                      : const Text('Continuar Produção', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 600;

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                        child: _buildImage(context),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const Divider(height: 1, color: AppColors.border),
                          _buildCaption(context),
                          _buildTimeline(context),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _buildImage(context),
                  _buildCaption(context),
                  _buildTimeline(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
