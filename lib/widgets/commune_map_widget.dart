// lib/widgets/commune_map_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/commune_model.dart';
import '../utils/app_constants.dart';

/// Carte interactive OpenStreetMap affichant les projets d'une commune.
/// Utilise flutter_map + tuiles OSM (pas de clé API requise).
class CommuneMapWidget extends StatefulWidget {
  final CommuneModel commune;
  final double height;
  final bool interactive;

  const CommuneMapWidget({
    super.key,
    required this.commune,
    this.height = 220,
    this.interactive = true,
  });

  @override
  State<CommuneMapWidget> createState() => _CommuneMapWidgetState();
}

class _CommuneMapWidgetState extends State<CommuneMapWidget> {
  final MapController _mapController = MapController();
  ProjectModel? _selectedProject;

  // Coordonnées par défaut : Adjamé, Abidjan
  static const LatLng _defaultCenter = LatLng(5.3600, -4.0083);

  // Coordonnées fictives par projet (à remplacer par vraies coords depuis l'API)
  static const Map<String, LatLng> _projectCoords = {
    'proj001': LatLng(5.3612, -4.0071),
    'proj002': LatLng(5.3588, -4.0102),
    'proj003': LatLng(5.3625, -4.0055),
    'proj004': LatLng(5.3570, -4.0120),
  };

  Color _markerColor(String statut) {
    switch (statut) {
      case 'livré':     return AppColors.success;
      case 'en_cours':  return AppColors.accent;
      default:          return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = widget.commune.projets.map((p) {
      final coord = _projectCoords[p.id] ?? _defaultCenter;
      final color = _markerColor(p.statut);
      return Marker(
        point: coord,
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => setState(() =>
              _selectedProject = _selectedProject?.id == p.id ? null : p),
          child: _ProjectMarker(color: color, isSelected: _selectedProject?.id == p.id),
        ),
      );
    }).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusL),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            // ── Carte OSM ─────────────────────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 14.5,
                interactionOptions: InteractionOptions(
                  flags: widget.interactive
                      ? InteractiveFlag.all
                      : InteractiveFlag.none,
                ),
                onTap: (_, __) => setState(() => _selectedProject = null),
              ),
              children: [
                // Tuiles OpenStreetMap (sans clé API)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ci.gouv.budgetouvert',
                  maxNativeZoom: 19,
                ),
                // Marqueurs des projets
                MarkerLayer(markers: markers),
              ],
            ),

            // ── Popup projet sélectionné ──────────────────────────────
            if (_selectedProject != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: _ProjectPopup(
                  project: _selectedProject!,
                  onClose: () => setState(() => _selectedProject = null),
                ),
              ),

            // ── Badge "Explorer" ──────────────────────────────────────
            if (_selectedProject == null)
              Positioned(
                bottom: 10,
                left: 12,
                child: _MapBadge(commune: widget.commune.name),
              ),

            // ── Légende ──────────────────────────────────────────────
            Positioned(
              top: 10,
              right: 10,
              child: _MapLegend(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Marqueur projet ──────────────────────────────────────────────────────
class _ProjectMarker extends StatelessWidget {
  final Color color;
  final bool isSelected;
  const _ProjectMarker({required this.color, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? 36 : 28,
      height: isSelected ? 36 : 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: isSelected ? 12 : 6,
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      child: Icon(
        Icons.construction,
        color: AppColors.white,
        size: isSelected ? 18 : 14,
      ),
    );
  }
}

// ─── Popup projet ─────────────────────────────────────────────────────────
class _ProjectPopup extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onClose;
  const _ProjectPopup({required this.project, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.construction, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.titre,
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${project.progressionGlobale.toInt()}% • ${project.categorie}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: project.progressionGlobale / 100,
                    minHeight: 5,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      project.statut == 'livré'
                          ? AppColors.success
                          : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 18, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ─── Badge commune ────────────────────────────────────────────────────────
class _MapBadge extends StatelessWidget {
  final String commune;
  const _MapBadge({required this.commune});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 12, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            'Explorer $commune',
            style: AppTextStyles.caption.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

// ─── Légende ──────────────────────────────────────────────────────────────
class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: AppColors.success, label: 'Livré'),
          const SizedBox(height: 4),
          _LegendItem(color: AppColors.accent,  label: 'En cours'),
          const SizedBox(height: 4),
          _LegendItem(color: AppColors.textHint, label: 'Planifié'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

// ─── Version compacte pour project_detail_screen ─────────────────────────
class ProjectLocationMap extends StatelessWidget {
  final String localisation;
  final LatLng coordinates;
  final double height;

  const ProjectLocationMap({
    super.key,
    required this.localisation,
    required this.coordinates,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: coordinates,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ci.gouv.budgetouvert',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: coordinates,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.construction,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
