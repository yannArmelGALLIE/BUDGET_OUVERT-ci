// lib/widgets/audio_player_card.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../utils/app_constants.dart';

/// Carte lecteur audio complète avec play/pause, barre de progression
/// et affichage du temps. Remplace l'ancien AudioCard statique.
class AudioPlayerCard extends StatefulWidget {
  final String langue;

  /// URL réseau ou chemin asset.
  /// Ex réseau : "https://mon-api.ci/audio/proj001_dioula.mp3"
  /// Ex asset  : "audio/proj001_dioula.mp3"
  final String audioUrl;

  /// Si true → AssetSource, si false → UrlSource
  final bool isAsset;

  const AudioPlayerCard({
    super.key,
    required this.langue,
    required this.audioUrl,
    this.isAsset = false,
  });

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  final _audio = AudioService.instance;

  bool get _isMine => _audio.currentUrl == widget.audioUrl;
  bool get _isPlaying => _isMine && _audio.isPlaying;

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlayerState>(
      valueListenable: _audio.stateNotifier,
      builder: (context, state, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: _audio.currentUrlNotifier,
          builder: (context, currentUrl, _) {
            final isMine = currentUrl == widget.audioUrl;
            final isPlaying = isMine && state == PlayerState.playing;
            final isLoading = isMine && state == PlayerState.playing &&
                _audio.durationNotifier.value == Duration.zero;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primarySurface : AppColors.inputBg,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
                border: isMine
                    ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Bouton play/pause
                      GestureDetector(
                        onTap: () => _audio.playOrPause(
                          widget.audioUrl,
                          isAsset: widget.isAsset,
                        ),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: AppColors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Langue + statut
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.headphones,
                                    size: 13, color: AppColors.primary),
                                const SizedBox(width: 5),
                                Text(
                                  'Écouter : ${widget.langue}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (isMine)
                              ValueListenableBuilder<Duration>(
                                valueListenable: _audio.positionNotifier,
                                builder: (_, pos, __) =>
                                    ValueListenableBuilder<Duration>(
                                  valueListenable: _audio.durationNotifier,
                                  builder: (_, dur, __) => Text(
                                    '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Text(
                                'Appuyez pour écouter',
                                style: AppTextStyles.caption,
                              ),
                          ],
                        ),
                      ),

                      // Icône onde sonore (décorative quand actif)
                      if (isPlaying)
                        const _SoundWaveIcon(),
                    ],
                  ),

                  // Barre de progression (visible seulement si c'est la piste active)
                  if (isMine) ...[
                    const SizedBox(height: 10),
                    ValueListenableBuilder<Duration>(
                      valueListenable: _audio.positionNotifier,
                      builder: (_, pos, __) =>
                          ValueListenableBuilder<Duration>(
                        valueListenable: _audio.durationNotifier,
                        builder: (_, dur, __) {
                          final progress = dur.inMilliseconds > 0
                              ? pos.inMilliseconds / dur.inMilliseconds
                              : 0.0;
                          return SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor:
                                  AppColors.primary.withOpacity(0.15),
                              thumbColor: AppColors.primary,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                              trackHeight: 3,
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: dur.inMilliseconds > 0
                                  ? (v) => _audio.seek(
                                      Duration(
                                          milliseconds:
                                              (v * dur.inMilliseconds).toInt()))
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Icône animée de son (3 barres qui ondulent)
class _SoundWaveIcon extends StatefulWidget {
  const _SoundWaveIcon();

  @override
  State<_SoundWaveIcon> createState() => _SoundWaveIconState();
}

class _SoundWaveIconState extends State<_SoundWaveIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anims = [
      Tween(begin: 4.0, end: 14.0).animate(
          CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5))),
      Tween(begin: 8.0, end: 18.0).animate(
          CurvedAnimation(parent: _ctrl, curve: const Interval(0.2, 0.7))),
      Tween(begin: 4.0, end: 12.0).animate(
          CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 0.9))),
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _anims.map((a) {
          return Container(
            width: 3,
            height: a.value,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }).toList(),
      ),
    );
  }
}
