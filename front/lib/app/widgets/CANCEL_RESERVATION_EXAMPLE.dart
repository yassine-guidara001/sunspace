import 'package:flutter_getx_app/app/widgets/delete_confirmation_dialog.dart';

/// Exemple compilable d'ouverture du dialogue d'annulation reservation.
Future<bool> openCancelReservationDialogExample({
  required String spaceName,
  required String dateTime,
  double? amount,
}) {
  return showCancelReservationDialog(
    spaceName: spaceName,
    dateTime: dateTime,
    amount: amount,
  );
}

/// Snippet de reference (texte uniquement, non execute).
const String kCancelReservationExampleSnippet = '''
final confirmed = await showCancelReservationDialog(
  spaceName: reservation.spaceName,
  dateTime: formattedDate,
  amount: reservation.amount,
);

if (!confirmed) return;
await controller.cancelReservation(reservation.id);
''';
