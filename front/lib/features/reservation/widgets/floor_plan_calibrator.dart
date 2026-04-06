// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/modules/plan/floor%20plan%20data.dart';

class FloorPlanCalibrator extends StatefulWidget {
  const FloorPlanCalibrator({super.key});

  @override
  State<FloorPlanCalibrator> createState() => _FloorPlanCalibratorState();
}

class _FloorPlanCalibratorState extends State<FloorPlanCalibrator> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'calibrator-${DateTime.now().millisecondsSinceEpoch}';
    _register();
  }

  void _register() {
    final container = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'relative'
      ..style.overflow = 'hidden';

    final svgObj = html.ObjectElement()
      ..data = 'assets/plan.svg'
      ..type = 'image/svg+xml'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0';

    final overlay = html.DivElement()
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.cursor = 'crosshair'
      ..style.zIndex = '10';

    final panel = html.DivElement()
      ..style.position = 'fixed'
      ..style.bottom = '80px'
      ..style.left = '260px'
      ..style.background = 'rgba(0,0,0,0.88)'
      ..style.color = '#00FF88'
      ..style.padding = '14px 18px'
      ..style.borderRadius = '10px'
      ..style.fontSize = '13px'
      ..style.fontFamily = 'monospace'
      ..style.zIndex = '9999'
      ..style.maxWidth = '700px'
      ..style.lineHeight = '1.8'
      ..innerHtml = '<b style="color:white">🎯 Outil de calibration</b><br>'
          'Entre un nom puis clique HAUT-GAUCHE puis BAS-DROIT de chaque pièce.<br>'
          '<span style="color:#aaa">Le code Dart sera copié automatiquement.</span>';

    final hint = html.DivElement()
      ..style.position = 'fixed'
      ..style.top = '100px'
      ..style.left = '260px'
      ..style.background = '#22C55E'
      ..style.color = 'white'
      ..style.padding = '7px 14px'
      ..style.borderRadius = '6px'
      ..style.fontSize = '13px'
      ..style.fontWeight = 'bold'
      ..style.zIndex = '9999'
      ..text = '① Entre le nom ci-dessous puis clique HAUT-GAUCHE';

    final nameInput = html.InputElement()
      ..placeholder = 'Nom de la pièce (ex: Salle de Réunion A)'
      ..style.position = 'fixed'
      ..style.top = '140px'
      ..style.left = '260px'
      ..style.padding = '8px 12px'
      ..style.borderRadius = '8px'
      ..style.border = '2px solid #22C55E'
      ..style.fontSize = '13px'
      ..style.width = '340px'
      ..style.zIndex = '9999'
      ..style.background = 'white';

    final resetBtn = html.ButtonElement()
      ..text = '🗑 Effacer tout'
      ..style.position = 'fixed'
      ..style.top = '140px'
      ..style.left = '620px'
      ..style.padding = '8px 14px'
      ..style.borderRadius = '8px'
      ..style.border = 'none'
      ..style.background = '#EF4444'
      ..style.color = 'white'
      ..style.cursor = 'pointer'
      ..style.fontSize = '13px'
      ..style.zIndex = '9999';

    html.document.body!
      ..append(hint)
      ..append(nameInput)
      ..append(resetBtn)
      ..append(panel);

    int clickCount = 0;
    double x1 = 0, y1 = 0;
    String currentLabel = '';
    final List<html.Element> dots = [];
    final List<html.Element> rects = [];
    int zoneIndex = 1;

    overlay.onClick.listen((e) {
      final rect = overlay.getBoundingClientRect();
      final cx = e.client.x - rect.left;
      final cy = e.client.y - rect.top;
      final svgX = cx / rect.width  * FloorPlanData.svgWidth;
      final svgY = cy / rect.height * FloorPlanData.svgHeight;

      final dot = html.DivElement()
        ..style.position = 'absolute'
        ..style.left  = '${cx - 5}px'
        ..style.top   = '${cy - 5}px'
        ..style.width  = '10px'
        ..style.height = '10px'
        ..style.borderRadius = '50%'
        ..style.zIndex = '20';

      if (clickCount == 0) {
        currentLabel = nameInput.value?.trim() ?? '';
        if (currentLabel.isEmpty) currentLabel = 'Espace $zoneIndex';
        x1 = svgX; y1 = svgY;
        dot.style.background = '#22C55E';
        hint
          ..text = '② Clique maintenant sur le coin BAS-DROIT'
          ..style.background = '#F59E0B';
        panel.innerHtml =
            '<b style="color:white">📍 Point 1</b> x1=${svgX.round()}, y1=${svgY.round()}<br>'
            '<span style="color:#aaa">Clique le coin BAS-DROIT...</span>';
        clickCount = 1;
      } else {
        final left   = (x1 < svgX ? x1 : svgX);
        final top    = (y1 < svgY ? y1 : svgY);
        final width  = (svgX - x1).abs();
        final height = (svgY - y1).abs();

        dot.style.background = '#EF4444';

        // Rectangle visuel orange
        final visRect = html.DivElement()
          ..style.position = 'absolute'
          ..style.left   = '${left  / FloorPlanData.svgWidth  * rect.width}px'
          ..style.top    = '${top   / FloorPlanData.svgHeight * rect.height}px'
          ..style.width  = '${width / FloorPlanData.svgWidth  * rect.width}px'
          ..style.height = '${height/ FloorPlanData.svgHeight * rect.height}px'
          ..style.border = '2px solid #F59E0B'
          ..style.background = 'rgba(245,158,11,0.18)'
          ..style.zIndex = '15'
          ..style.borderRadius = '3px';

        final lbl = html.DivElement()
          ..style.position = 'absolute'
          ..style.left = '4px'
          ..style.top  = '4px'
          ..style.color = 'white'
          ..style.fontSize = '10px'
          ..style.fontWeight = 'bold'
          ..style.background = 'rgba(0,0,0,0.65)'
          ..style.padding = '2px 5px'
          ..style.borderRadius = '3px'
          ..text = currentLabel;
        visRect.append(lbl);
        overlay.append(visRect);
        rects.add(visRect);

        final id = 'space_$zoneIndex';
        final code =
            "FloorSpaceZone(\n"
            "  spaceId: '$id',\n"
            "  label: '$currentLabel',\n"
            "  rect: Rect.fromLTWH(${left.round()}, ${top.round()}, "
            "${width.round()}, ${height.round()}),\n"
            "),";

        panel.innerHtml =
            '<b style="color:white">✅ "$currentLabel"</b><br>'
            '<span style="color:#00FF88">$code</span><br><br>'
            '<span style="color:#aaa">📋 Copié dans le presse-papier !</span>';

        html.window.navigator.clipboard?.writeText(code);

        hint
          ..text = '① Entre le nom ci-dessous puis clique HAUT-GAUCHE'
          ..style.background = '#22C55E';
        nameInput.value = '';
        clickCount = 0;
        zoneIndex++;
      }

      overlay.append(dot);
      dots.add(dot);
    });

    resetBtn.onClick.listen((_) {
      for (final d in dots) d.remove();
      for (final r in rects) r.remove();
      dots.clear();
      rects.clear();
      clickCount = 0;
      zoneIndex = 1;
      nameInput.value = '';
      panel.innerHtml =
          '<b style="color:white">🎯 Prêt</b><br>Entre un nom et clique sur une pièce.';
      hint
        ..text = '① Entre le nom ci-dessous puis clique HAUT-GAUCHE'
        ..style.background = '#22C55E';
    });

    container
      ..append(svgObj)
      ..append(overlay);

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) => container,
    );
  }

  @override
  void dispose() {
    html.document.body
        ?.querySelectorAll('[style*="9999"]')
        .forEach((el) => el.remove());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}