# Formulaire de Confirmation de Suppression Amélioré

## Vue d'ensemble

Un widget réutilisable pour afficher un formulaire de confirmation de suppression élégant et professionnel dans toute l'application.

## Fichiers

- **`delete_confirmation_dialog.dart`** - Widget principal
- **`dialogs.dart`** - Exports centralisés

## Installation

Importer dans votre fichier :

```dart
import 'package:flutter_getx_app/app/widgets/delete_confirmation_dialog.dart';
// ou
import 'package:flutter_getx_app/app/widgets/dialogs.dart';
```

## Utilisation

### 1. Version simple (usage rapide)

```dart
final confirmed = await confirmDelete(item: 'Session Flutter');
```

### 2. Version avec tous les paramètres

```dart
final confirmed = await showDeleteConfirmationDialog(
  title: 'Supprimer la session',
  itemName: 'Session Flutter',
  description: 'Cette action est irréversible. Tous les participants seront désinscrits.',
  confirmButtonText: 'Oui, supprimer',
  confirmButtonColor: Colors.red,
  cancelButtonText: 'Non, conserver',
);

if (confirmed) {
  // Effectuer la suppression
  await deleteItem();
}
```

### 3. Dans un contrôleur GetX

```dart
import 'package:flutter_getx_app/app/widgets/delete_confirmation_dialog.dart';

class MyController extends GetxController {
  Future<void> removeItem(MyItem item) async {
    final confirmed = await showDeleteConfirmationDialog(
      title: 'Supprimer l\'élément',
      itemName: item.name,
      description: 'Cette action ne peut pas être annulée.',
    );

    if (!confirmed) return;

    try {
      await _api.delete(item.id);
      items.removeWhere((i) => i.id == item.id);
      Get.snackbar('Succès', 'Élément supprimé');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de supprimer');
    }
  }
}
```

## Paramètres

| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `title` | String | Requis | Titre du dialogue |
| `itemName` | String | Requis | Nom de l'élément à supprimer |
| `description` | String? | null | Message additionnel |
| `confirmButtonText` | String? | 'Supprimer' | Texte du bouton de confirmation |
| `confirmButtonColor` | Color? | Color(0xFFDC2626) | Couleur du bouton rouge |
| `cancelButtonText` | String? | 'Annuler' | Texte du bouton d'annulation |
| `customIcon` | Widget? | null | Icône personnalisée |

## Résultats

La fonction retourne `Future<bool>` :
- `true` si l'utilisateur confirme
- `false` si l'utilisateur annule

## Caractéristiques

✅ Design moderne et attrayant
✅ Icône d'avertissement rouge
✅ Message de confirmation centralisé
✅ Boutons d'action clairs
✅ Messagre "Cette action est irréversible"
✅ Responsive (mobile & desktop)
✅ Barrière de dialogue non-dismissible
✅ Paramètres personnalisables

## Migration depuis AlertDialog

### Avant (ancien code)
```dart
final confirmed = await Get.dialog<bool>(
  AlertDialog(
    title: const Text('Supprimer'),
    content: Text('Supprimer "${item.title}" ?'),
    actions: [
      TextButton(
        onPressed: () => Get.back(result: false),
        child: const Text('Annuler'),
      ),
      ElevatedButton(
        onPressed: () => Get.back(result: true),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: const Text('Supprimer'),
      ),
    ],
  ),
) ?? false;
```

### Après (nouveau code)
```dart
final confirmed = await showDeleteConfirmationDialog(
  title: 'Supprimer',
  itemName: item.title,
);
```

## Fichiers à mettre à jour

Les contrôleurs suivants utilisent maintenant le nouveau formulaire :
- ✅ TrainingSessionsController

### Contrôleurs à migrer
- [ ] CoursesController
- [ ] UsersController
- [ ] EquipmentController
- [ ] SpacesController
- [ ] ReservationsController
- [ ] AssignmentsController

### Vues à migrer
- [ ] courses_view.dart
- [ ] user_view.dart
- [ ] equipments_view.dart
- [ ] association_formations_page.dart
