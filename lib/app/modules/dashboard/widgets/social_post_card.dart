import 'package:flutter/material.dart';
import '../../../core/components/status_badge.dart';
import '../../../core/theme/app_colors.dart';
import '../models/content_model.dart';

class SocialPostCard extends StatefulWidget {
  final ContentModel content;

  const SocialPostCard({super.key, required this.content});

  @override
  State<SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<SocialPostCard> {
  bool _isExpanded = false;

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

          // Media Content
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Image.network(
                widget.content.imageUrl,
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
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

          // Caption Content (Instagram style)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0, top: 16.0),
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
