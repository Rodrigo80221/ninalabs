import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../core/components/status_badge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/webhook_service.dart';
import '../models/content_model.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialPostCard extends StatefulWidget {
  final ContentModel content;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onDelete;
  final bool isInitiallyWaiting;
  final Function(bool)? onPollingChanged;

  const SocialPostCard({
    super.key, 
    required this.content, 
    this.onRefresh, 
    this.onDelete,
    this.isInitiallyWaiting = false,
    this.onPollingChanged,
  });

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isWaitingForWebhook = false;
  int _secondsElapsed = 0;
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  late AnimationController _animationController;

  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _showVideoPlayer = false;
  
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isInitiallyWaiting) {
      _startWaiting();
    }
  }

  @override
  void didUpdateWidget(SocialPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInitiallyWaiting != oldWidget.isInitiallyWaiting) {
      if (widget.isInitiallyWaiting && !_isWaitingForWebhook) {
        _startWaiting();
      } else if (!widget.isInitiallyWaiting && _isWaitingForWebhook) {
        _stopWaiting();
      }
    }
    if (widget.content.hasError && _isWaitingForWebhook) {
      _stopWaiting();
      setState(() {
        _errorMessage = widget.content.status.toLowerCase().contains('erro')
            ? widget.content.status
            : 'Ocorreu um erro durante a produção.';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _startWaiting() {
    if (widget.onPollingChanged != null) widget.onPollingChanged!(true);
    setState(() {
      _isWaitingForWebhook = true;
      _secondsElapsed = 0;
    });

    _animationController.repeat();

    _countdownTimer?.cancel();
    _refreshTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
      });
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }
      
      if (!mounted) return;
      // Check if all steps are completed or if there is an error
      final allCompleted = widget.content.productionSteps.every((step) => step.isCompleted);
      if (allCompleted || widget.content.hasError) {
        _stopWaiting();
        if (widget.content.hasError && _errorMessage == null) {
          setState(() {
            _errorMessage = widget.content.status.toLowerCase().contains('erro')
                ? widget.content.status
                : 'Ocorreu um erro durante a produção.';
          });
        }
      }
    });
  }

  void _stopWaiting() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _animationController.stop();
    if (widget.onPollingChanged != null) widget.onPollingChanged!(false);
    if (mounted) {
      setState(() {
        _isWaitingForWebhook = false;
      });
    }
  }

  void _showStrategyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx2) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Estratégia de Conteúdo'),
            IconButton(
              icon: const Icon(Icons.copy, color: AppColors.terracotta),
              tooltip: 'Copiar Estratégia',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.content.strategyText ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Estratégia copiada com sucesso!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(widget.content.strategyText!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx2).pop(),
            child: const Text('Fechar', style: TextStyle(color: AppColors.terracotta)),
          ),
        ],
      ),
    );
  }

  void _showDescriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx2) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Descrição', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.copy, color: AppColors.terracotta),
              tooltip: 'Copiar Descrição',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.content.description));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Descrição copiada com sucesso!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(widget.content.description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx2).pop(),
            child: const Text('Fechar', style: TextStyle(color: AppColors.terracotta)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.content.templateName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                ),
                if (widget.content.status != 'Pendente')
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: StatusBadge(status: widget.content.status, postDate: widget.content.postDate),
                  ),
                if (widget.content.status == 'Pendente' && widget.content.date.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Última alteração: ${widget.content.date}',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.content.status == 'Pendente' || widget.content.videoUrl != null || (widget.content.strategyText != null && widget.content.strategyText!.trim().isNotEmpty))
            IconButton(
              icon: const Icon(Icons.more_vert),
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
                        if (widget.content.strategyText != null && widget.content.strategyText!.trim().isNotEmpty) ...[
                          ListTile(
                            leading: const Icon(Icons.lightbulb_outline, color: AppColors.textDark),
                            title: const Text('Ver Estratégia', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              _showStrategyDialog(context);
                            },
                          ),
                          const Divider(),
                        ],
                        if (widget.content.videoUrl != null) ...[
                          ListTile(
                            leading: const Icon(Icons.download, color: AppColors.textDark),
                            title: const Text('Baixar Vídeo', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                            onTap: () async {
                              Navigator.of(ctx).pop();
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Iniciando download...'),
                                    backgroundColor: AppColors.terracotta,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }

                              try {
                                final dateStr = widget.content.date.replaceAll('/', '-').replaceAll(':', '').replaceAll(' ', '_');
                                final templateName = widget.content.templateName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
                                final filename = '${templateName}_$dateStr.mp4';

                                final response = await http.get(Uri.parse(widget.content.videoUrl!));
                                final blob = html.Blob([response.bodyBytes]);
                                final objectUrl = html.Url.createObjectUrlFromBlob(blob);
                                final anchor = html.AnchorElement(href: objectUrl)
                                  ..setAttribute("download", filename)
                                  ..click();
                                html.Url.revokeObjectUrl(objectUrl);
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Download concluído!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                final url = Uri.parse(widget.content.videoUrl!);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao baixar vídeo: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const Divider(),
                        ],
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
      child: GestureDetector(
        onTap: () async {
          if (widget.content.videoUrl != null) {
            if (_showVideoPlayer) {
              if (_isVideoInitialized && _videoPlayerController != null) {
                if (_videoPlayerController!.value.isPlaying) {
                  _videoPlayerController!.pause();
                } else {
                  _videoPlayerController!.play();
                }
                setState(() {});
              }
            } else {
              setState(() {
                _showVideoPlayer = true;
              });
              _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.content.videoUrl!));
              _videoPlayerController!.addListener(() {
                if (mounted) setState(() {});
              });
              await _videoPlayerController!.initialize();
              if (mounted) {
                setState(() {
                  _isVideoInitialized = true;
                });
                _videoPlayerController!.play();
              }
            }
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!_showVideoPlayer)
              Container(
                color: AppColors.background,
                width: double.infinity,
                height: double.infinity,
                child: Image.network(
                  widget.content.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.background,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.satellite_alt_outlined, size: 36, color: AppColors.terracotta),
                        const SizedBox(height: 12),
                        Text(
                          'SINAL NÃO ENCONTRADO',
                          style: GoogleFonts.spaceGrotesk(color: AppColors.terracotta, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2.0),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ainda sem mídia gerada.',
                          style: TextStyle(color: AppColors.textLight, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_showVideoPlayer && _isVideoInitialized && _videoPlayerController != null)
              Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _videoPlayerController!.value.aspectRatio,
                        child: VideoPlayer(_videoPlayerController!),
                      ),
                    ),
                    Container(
                      color: Colors.black54,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_videoPlayerController!.value.isPlaying) {
                                      _videoPlayerController!.pause();
                                    } else {
                                      _videoPlayerController!.play();
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.stop, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _videoPlayerController!.pause();
                                    _videoPlayerController!.seekTo(Duration.zero);
                                    _showVideoPlayer = false;
                                  });
                                },
                              ),
                            ],
                          ),
                          VideoProgressIndicator(
                            _videoPlayerController!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: AppColors.terracotta,
                              backgroundColor: Colors.white30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (_showVideoPlayer && !_isVideoInitialized)
              const CircularProgressIndicator(color: AppColors.terracotta),
              
            if (!_showVideoPlayer && widget.content.videoUrl != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    if (widget.content.status == 'Pendente') return const SizedBox.shrink();
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
    if (widget.content.status != 'Pendente' && !widget.content.hasError) return const SizedBox.shrink();

    final lastCompletedIndex = widget.content.productionSteps.lastIndexWhere((s) => s.isCompleted);
    final nextStepIndex = lastCompletedIndex + 1 < widget.content.productionSteps.length ? lastCompletedIndex + 1 : -1;

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
            
            final isVisuallyCompleted = index <= lastCompletedIndex;
            final isNextStep = _isWaitingForWebhook && index == nextStepIndex && !widget.content.hasError;
            final isErrorStep = widget.content.hasError && index == nextStepIndex;

            final stepWidget = Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(left: 2, right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isErrorStep ? AppColors.errorText : (isNextStep ? AppColors.terracotta : (isVisuallyCompleted ? AppColors.successGreen : Colors.transparent)),
                    border: Border.all(
                      color: isErrorStep ? AppColors.errorText : (isNextStep ? AppColors.terracotta : (isVisuallyCompleted ? AppColors.successGreen : AppColors.border)),
                      width: 2,
                    ),
                    boxShadow: isNextStep ? [BoxShadow(color: AppColors.terracotta.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)] : null,
                  ),
                ),
                Expanded(
                  child: () {
                    final isEstrategiaClickable = step.title == 'Estratégia' && widget.content.strategyText != null && widget.content.strategyText!.trim().isNotEmpty;
                    final isDescricaoClickable = step.title == 'Descrição' && widget.content.description.trim().isNotEmpty;
                    
                    if (isEstrategiaClickable || isDescricaoClickable) {
                      return InkWell(
                        onTap: () => isEstrategiaClickable ? _showStrategyDialog(context) : _showDescriptionDialog(context),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                step.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_outward, size: 12, color: AppColors.successGreen),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: isErrorStep ? AppColors.errorText : (isNextStep ? AppColors.terracotta : (isVisuallyCompleted ? AppColors.successGreen : AppColors.textLight)),
                          fontWeight: (isNextStep || isErrorStep) ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }
                  }(),
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
          (_isLoading || _isWaitingForWebhook)
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.quartzPink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RotationTransition(
                        turns: _animationController,
                        child: const Icon(Icons.refresh, size: 16, color: Color(0xFFA9534C)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aguardando... ${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFA9534C)),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        widget.content.hasError = false;
                        _errorMessage = null;
                      });
                      _startWaiting();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ação enviada com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      WebhookService.continuarProducao(
                        codigoEmpresa: widget.content.companyId,
                        codigoContrato: widget.content.templateId,
                        idRow: widget.content.id,
                        dataAgendamento: widget.content.dataAgendamentoInstagram ?? widget.content.createdAt,
                      ).then((apiResponse) {
                        if (mounted) {
                          if (!apiResponse.success) {
                            _stopWaiting();
                            setState(() {
                              widget.content.hasError = true;
                              _errorMessage = apiResponse.message ?? 'Erro ao continuar produção.';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_errorMessage!),
                                backgroundColor: AppColors.errorText,
                              ),
                            );
                          }
                        }
                      }).catchError((error) {
                        if (mounted) {
                          _stopWaiting();
                          setState(() {
                            widget.content.hasError = true;
                            _errorMessage = 'Erro de conexão: $error';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro: $error'),
                              backgroundColor: AppColors.errorText,
                            ),
                          );
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Continuar Produção', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.terracotta, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPendingOrError = widget.content.status == 'Pendente' || widget.content.hasError;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isPendingOrError ? 900 : 500),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border, width: 0.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 600;

              if (isDesktop && isPendingOrError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const Divider(height: 1, color: AppColors.border),
                    _buildCaption(context),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildImage(context),
                        ),
                        Expanded(
                          flex: 4,
                          child: _buildTimeline(context),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _buildCaption(context),
                  _buildImage(context),
                  if (isPendingOrError) _buildTimeline(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
