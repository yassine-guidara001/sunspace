// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/modules/plan/floor%20plan%20data.dart';

class InteractiveFloorPlan extends StatefulWidget {
  final void Function(String spaceId, String label, Offset globalPosition)
      onSpaceTapped;
  final String? selectedSpaceId;
  final Map<String, String>? zoneLabels;

  const InteractiveFloorPlan({
    super.key,
    required this.onSpaceTapped,
    this.selectedSpaceId,
    this.zoneLabels,
  });

  @override
  State<InteractiveFloorPlan> createState() => _InteractiveFloorPlanState();
}

class _InteractiveFloorPlanState extends State<InteractiveFloorPlan> {
  late final String _viewId;
  html.DivElement? _container;
  html.DivElement? _tooltip;
  String? _previousSelectedId;
  bool _modalOpen = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'floor-plan-${DateTime.now().millisecondsSinceEpoch}';
    _registerView();
  }

  void _registerView() {
    _container = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'relative'
      ..style.overflow = 'hidden';

    final svgObject = html.ObjectElement()
      ..data = 'assets/plan.svg'
      ..type = 'image/svg+xml'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0';

    final zonesContainer = html.DivElement()
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.pointerEvents = 'none';

    // ── Tooltip ───────────────────────────────────────────────────────────
    _tooltip = html.DivElement()
      ..style.position = 'fixed'
      ..style.background = '#1E293B'
      ..style.color = 'white'
      ..style.padding = '8px 14px'
      ..style.borderRadius = '8px'
      ..style.fontSize = '13px'
      ..style.fontFamily = '-apple-system, BlinkMacSystemFont, sans-serif'
      ..style.fontWeight = '600'
      ..style.pointerEvents = 'none'
      ..style.display = 'none'
      ..style.whiteSpace = 'nowrap'
      ..style.zIndex = '9999'
      ..style.boxShadow = '0 4px 12px rgba(0,0,0,0.25)'
      ..style.border = '1px solid rgba(255,255,255,0.1)';
    html.document.body!.append(_tooltip!);

    for (final zone in FloorPlanData.zones) {
      final zoneLabel = widget.zoneLabels?[zone.spaceId] ?? zone.label;
      final zoneEl = html.DivElement()
        ..id = 'zone-${zone.spaceId}'
        ..style.position = 'absolute'
        ..style.cursor = 'pointer'
        ..style.borderRadius = '6px'
        ..style.border = '2px solid transparent'
        ..style.pointerEvents = 'auto'
        ..style.transition =
            'background 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease';

      _positionZone(zoneEl, zone);

      // ── Hover : vert clair comme capture 3 ──────────────────────────
      zoneEl.onMouseEnter.listen((_) {
        if (_modalOpen) return;
        zoneEl.style.background = 'rgba(34, 197, 94, 0.25)';
        zoneEl.style.border = '2.5px solid #22C55E';
        zoneEl.style.boxShadow = '0 0 0 3px rgba(34,197,94,0.15)';

        // Tooltip avec nom de l'espace
        _tooltip!
          ..innerHtml = '''
            <div style="display:flex;align-items:center;gap:8px">
              <div style="width:8px;height:8px;border-radius:50%;background:#22C55E;flex-shrink:0"></div>
              <span>$zoneLabel</span>
            </div>
          '''
          ..style.display = 'block';
      });

      zoneEl.onMouseMove.listen((e) {
        if (_modalOpen) {
          _tooltip!.style.display = 'none';
          return;
        }
        double x = e.client.x + 16;
        double y = e.client.y + 16;
        if (x + 200 > (html.window.innerWidth ?? 1200)) x = e.client.x - 210;
        if (y + 50 > (html.window.innerHeight ?? 800)) y = e.client.y - 56;
        _tooltip!.style
          ..left = '${x}px'
          ..top = '${y}px';
      });

      zoneEl.onMouseLeave.listen((_) {
        // Si pas sélectionné → remet transparent
        if (widget.selectedSpaceId != zone.spaceId) {
          zoneEl.style.background = 'transparent';
          zoneEl.style.border = '2px solid transparent';
          zoneEl.style.boxShadow = 'none';
        }
        _tooltip!.style.display = 'none';
      });

      zoneEl.onClick.listen((_) {
        _tooltip!.style.display = 'none';
        _modalOpen = true;
        widget.onSpaceTapped(zone.spaceId, zoneLabel, Offset.zero);
      });

      zonesContainer.append(zoneEl);
    }

    html.window.onResize.listen((_) => _repositionAllZones());

    _container!
      ..append(svgObject)
      ..append(zonesContainer);

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _container!,
    );
  }

  void _positionZone(html.DivElement el, FloorSpaceZone zone) {
    final left = zone.rect.left / FloorPlanData.svgWidth * 100;
    final top = zone.rect.top / FloorPlanData.svgHeight * 100;
    final width = zone.rect.width / FloorPlanData.svgWidth * 100;
    final height = zone.rect.height / FloorPlanData.svgHeight * 100;
    el.style
      ..left = '$left%'
      ..top = '$top%'
      ..width = '$width%'
      ..height = '$height%';
  }

  void _repositionAllZones() {
    for (final zone in FloorPlanData.zones) {
      final el = html.document.getElementById('zone-${zone.spaceId}');
      if (el is html.DivElement) _positionZone(el, zone);
    }
  }

  void modalClosed() {
    _modalOpen = false;
    _tooltip!.style.display = 'none';
  }

  void _updateSelection() {
    // Déselectionne l'ancien
    if (_previousSelectedId != null) {
      final prev = html.document.getElementById('zone-$_previousSelectedId');
      if (prev != null) {
        prev.style.background = 'transparent';
        prev.style.border = '2px solid transparent';
        prev.style.boxShadow = 'none';
      }
    }
    // Sélectionne le nouveau
    if (widget.selectedSpaceId != null) {
      final el = html.document.getElementById('zone-${widget.selectedSpaceId}');
      if (el != null) {
        el.style.background = 'rgba(34, 197, 94, 0.30)';
        el.style.border = '3px solid #22C55E';
        el.style.boxShadow = '0 0 0 4px rgba(34,197,94,0.20)';
      }
    }
    _previousSelectedId = widget.selectedSpaceId;
  }

  @override
  void didUpdateWidget(InteractiveFloorPlan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSpaceId != _previousSelectedId) {
      _updateSelection();
    }
    if (widget.selectedSpaceId == null && _modalOpen) {
      _modalOpen = false;
    }
  }

  @override
  void dispose() {
    _tooltip?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
