import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? postDate;

  const StatusBadge({super.key, required this.status, this.postDate});

  @override
  Widget build(BuildContext context) {
    final bool isError = status.toLowerCase().contains('erro');
    final bool isPending = status.toLowerCase() == 'pendente';
    final bool isScheduled = status.toLowerCase() == 'agendado';
    final Color bgColor = isError ? Colors.red.withOpacity(0.1) : (isPending ? AppColors.statusPendingBg : (isScheduled ? AppColors.quartzPink : AppColors.statusPostedBg));
    final Color textColor = isError ? Colors.red : (isPending ? AppColors.statusPendingText : (isScheduled ? AppColors.terracotta : AppColors.statusPostedText));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isScheduled && postDate != null && postDate!.isNotEmpty
            ? 'Data Agendamento: $postDate'
            : (!isPending && !isScheduled && postDate != null && postDate!.isNotEmpty)
                ? 'Data Postagem: $postDate'
                : status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
