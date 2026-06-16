import 'package:flutter/material.dart';
import '../../../core/components/status_badge.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/webhook_service.dart';
import '../models/content_model.dart';

class SocialPostCard extends StatefulWidget {
  final ContentModel content;

  const SocialPostCard({super.key, required this.content});

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> {
  bool _isExpanded = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
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
                StatusBadge(status: widget.content.status),
              ],
            ),
          ),

          // Media Content and Timeline Row
          if (widget.content.status == 'Pendente')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image (Left)
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.content.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          width: double.infinity,
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
                  ),
                  const SizedBox(width: 16),
                  
                  // Timeline (Right)
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Produção de Conteúdo',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 8),
                        ...widget.content.productionSteps.map((step) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0), // short space
                            child: Row(
                              children: [
                                Icon(
                                  step.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: step.isCompleted ? Colors.green : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    step.title,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: step.isCompleted ? AppColors.textDark : AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () async {
                              setState(() => _isLoading = true);
                              
                              final success = await WebhookService.continuarProducao(
                                codigoEmpresa: widget.content.companyId,
                                codigoContrato: widget.content.templateId,
                                idRow: widget.content.id,
                              );
                              
                              if (!mounted) return;
                              setState(() => _isLoading = false);
                              
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
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
                                : const Text('Continuar Produção', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.content.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      width: double.infinity,
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
              ),
            ),

          // Caption Content (Instagram style)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: (widget.content.status == 'Pendente' || widget.content.description.isEmpty)
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                        children: [
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
          ),
          
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}
