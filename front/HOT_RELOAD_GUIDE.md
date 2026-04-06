# 🚀 Guide Hot Reload Automatique Flutter

## ✅ Configuration Activée

Votre VS Code est maintenant configuré pour :

1. **Auto-save** : Sauvegarde automatique toutes les 500ms
2. **Hot Reload au save** : Active le hot reload lors de la sauvegarde
3. **Format on save** : Formate le code Dart automatiquement

---

## 🎯 Comment l'utiliser

### Option 1 : Utiliser Dart Debugger (Recommandé)
1. Appuyez sur **F5** ou allez à Run → Start Debugging
2. Sélectionnez **"Flutter (Windows - Hot Reload)"**
3. Modifiez votre code Dart
4. Sauvegardez avec **Ctrl+S**
5. L'app se met à jour **automatiquement** ! ✨

### Option 2 : Utiliser la tâche VS Code
1. Appuyez sur **Ctrl+Shift+D** → Run → "Flutter Run (Auto Hot Reload)"
2. Même workflow que Option 1

### Option 3 : Terminal Manuel (si besoin)
1. Exécutez : `flutter run -d windows`
2. Dans le terminal, appuyez sur **r** pour hot reload
3. Appuyez sur **R** pour hot restart (redémarre l'app complètement)

---

## 🔧 Commandes Clavier en Terminal Flutter

| Touche | Action |
|--------|--------|
| **r** | Hot reload (rapide) |
| **R** | Hot restart (complet) |
| **q** | Quitter l'app |
| **d** | Détacher |

---

## ⚡ Conseils

- **Hot reload** = Recharge le code, garde l'état → Plus rapide
- **Hot restart** = Recharge + reinitialise l'état → Complet
- Si hot reload échoue (ex: changement de classe), tapez **R**

---

## 📝 Fichiers Configurés

- `.vscode/launch.json` → Débuggeur Dart optimisé
- `.vscode/tasks.json` → Tâches Flutter / Hot reload automatique  
- `.vscode/settings.json` → Auto-save + Format on save

---

**Testez maintenant** : Modifiez un texte dans l'app, sauvegardez, et regardez le changement s'appliquer instantanément !
