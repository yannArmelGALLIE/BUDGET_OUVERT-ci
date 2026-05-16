import 'package:budget_ouvert/utils/app_constants.dart';
import 'package:flutter/material.dart';

class QrInfoCard extends StatelessWidget {
  const QrInfoCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projets publics',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'QR Code & Mairie',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.primarySurface,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Les projets publics de la mairie (marchés, routes…) seront désormais accompagnés d\'une pancarte QR code. Scannez-la pour accéder aux informations du projet.',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.accent, size: 20),
                SizedBox(width: 10),
                Text(
                  'Pointez votre caméra sur le QR code',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
