// lib/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../services/firebase_auth_service.dart';

// ─── APP BAR ───────────────────────────────────────────────────────────────
class BudgetAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String communeName;
  final bool showProfile;
  final VoidCallback? onProfileTap;

  const BudgetAppBar({
    super.key,
    this.communeName = 'BudgetOuvert',
    this.showProfile = true,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimens.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      titleSpacing: AppDimens.paddingM,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on,
                size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(communeName,
              style: AppTextStyles.titleLarge.copyWith(fontSize: 14)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppDimens.paddingM),
          child: GestureDetector(
            onTap: onProfileTap,
            child: showProfile ? _ProfileAvatar() : _UnconnectedAvatar(),
          ),
        ),
      ],
    );
  }
}

class _UnconnectedAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: const Center(
        child: Text("?",
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.primary,
            )),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final citoyen = FirebaseAuthService.currentCitoyen;
    final initiale = citoyen != null && citoyen.prenom.isNotEmpty
        ? citoyen.prenom[0].toUpperCase()
        : '?';
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Center(
        child: Text(initiale,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.primary,
            )),
      ),
    );
  }
}

// ─── PRIMARY BUTTON ────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.white)))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.white)),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(trailingIcon, size: 16),
                  ],
                ],
              ),
      ),
    );
  }
}

// ─── INPUT FIELD ───────────────────────────────────────────────────────────
class BudgetTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  const BudgetTextField({
    super.key,
    required this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─── STATUS CHIP ───────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final String label;
  final String statut;
  const StatusChip({super.key, required this.label, required this.statut});

  Color get _bgColor {
    switch (statut) {
      case 'livré':
        return AppColors.statusLivre.withOpacity(0.15);
      case 'en_cours':
        return AppColors.statusEnCours.withOpacity(0.15);
      case 'resolu':
        return AppColors.statusResolu.withOpacity(0.15);
      default:
        return AppColors.inputBg;
    }
  }

  Color get _textColor {
    switch (statut) {
      case 'livré':
        return AppColors.statusLivre;
      case 'en_cours':
        return AppColors.statusEnCours;
      case 'resolu':
        return AppColors.statusResolu;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Text(label.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
              color: _textColor, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

// ─── LOGO ──────────────────────────────────────────────────────────────────
class BudgetLogo extends StatelessWidget {
  final double size;
  final bool dark;
  const BudgetLogo({super.key, this.size = 72, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Center(
          child: Icon(Icons.savings_outlined,
              size: size * 0.45, color: AppColors.primary)),
    );
  }
}

// ─── AUDIO CARD ────────────────────────────────────────────────────────────
class AudioCard extends StatelessWidget {
  final String langue;
  final VoidCallback? onPlay;
  const AudioCard({super.key, required this.langue, this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Row(
        children: [
          const Icon(Icons.headphones, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Écouter : $langue',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary)),
          const Spacer(),
          const Icon(Icons.volume_up, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
}

// ─── LANGUE CHIP ───────────────────────────────────────────────────────────
class LangueChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const LangueChip(
      {super.key, required this.label, this.selected = false, this.onTap});

  @override
  State<LangueChip> createState() => _LangueChipState();
}

class _LangueChipState extends State<LangueChip> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSelected = !_isSelected;
        });
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isSelected ? AppColors.primary : AppColors.inputBg,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(
              color: _isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(widget.label,
            style: AppTextStyles.caption.copyWith(
              color: _isSelected ? AppColors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

// ─── SECTION HEADER ────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.titleLarge),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
