import 'package:flutter_getx_app/app/widgets/delete_confirmation_dialog.dart';

/// Helpers de migration compilables pour centraliser la confirmation.
class MigrationPatterns {
  static Future<bool> confirmAssignmentDelete(String assignmentTitle) {
    return showDeleteConfirmationDialog(
      title: 'Supprimer le devoir',
      itemName: assignmentTitle,
      description:
          'Cette action est irreversible et retire le devoir de la liste.',
      confirmButtonText: 'Supprimer',
    );
  }

  static Future<bool> confirmReservationCancel(String reservationLabel) {
    return showDeleteConfirmationDialog(
      title: 'Annuler la reservation',
      itemName: reservationLabel,
      description: 'La reservation sera annulee definitivement.',
      confirmButtonText: 'Annuler',
      cancelButtonText: 'Conserver',
    );
  }
}

/// Checklist texte de migration (non executable).
const String kMigrationChecklist = '''
- Ajouter l'import delete_confirmation_dialog.dart
- Remplacer AlertDialog par showDeleteConfirmationDialog
- Stopper l'action si confirmed == false
- Executer la suppression si confirmed == true
''';
