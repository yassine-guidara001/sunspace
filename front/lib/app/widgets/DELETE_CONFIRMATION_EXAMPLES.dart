import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/widgets/delete_confirmation_dialog.dart';

/// Exemples compilables d'utilisation du dialogue de suppression.
class DeleteConfirmationExamples {
  static Future<bool> confirmCourseDelete(String courseName) {
    return showDeleteConfirmationDialog(
      title: 'Supprimer le cours',
      itemName: courseName,
      description: 'Cette action est irreversible.',
      confirmButtonText: 'Supprimer',
      confirmButtonColor: const Color(0xFFDC2626),
    );
  }

  static Future<bool> confirmUserDelete(String displayName) {
    return showDeleteConfirmationDialog(
      title: 'Supprimer l\'utilisateur',
      itemName: displayName,
      description: 'L\'utilisateur ne pourra plus se connecter.',
      confirmButtonText: 'Supprimer',
      confirmButtonColor: const Color(0xFFDC2626),
    );
  }
}

/// Snippets de reference (texte uniquement, non execute).
const String kDeleteConfirmationExamplesSnippet = '''
final confirmed = await showDeleteConfirmationDialog(
  title: 'Supprimer le cours',
  itemName: course.title,
  description: 'Cette action est irreversible.',
);

if (!confirmed) return;
await controller.deleteCourse(course.id);
''';
