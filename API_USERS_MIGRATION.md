# 🔄 Migration API Utilisateurs - Strapi → Node.js Backend

## ✅ Étapes Complétées

### Backend Node.js (backend/src/)

#### 1. **Services** (`services/users.service.js`)
- ✅ `getAllUsers()` - Récupérer tous les utilisateurs
- ✅ `getUserById(userId)` - Récupérer un utilisateur
- ✅ `createUser(data)` - Créer un nouvel utilisateur
- ✅ `updateUser(userId, data)` - Mettre à jour un utilisateur
- ✅ `deleteUser(userId)` - Supprimer un utilisateur

#### 2. **Contrôleurs** (`controllers/users.controller.js`)
- ✅ Tous les endpoints avec gestion d'erreurs
- ✅ Réponses au format standardisé `{statusCode, message, success, data}`

#### 3. **Routes** (`routes/users.routes.js`)
- ✅ `GET /api/users` - Admin, Teacher Director (récupérer tous)
- ✅ `POST /api/users` - Admin, Teacher Director (créer)
- ✅ `GET /api/users/me` - Tous (profil actuel)
- ✅ `GET /api/users/:id` - Tous (détails utilisateur)
- ✅ `PUT /api/users/:id` - Admin (mettre à jour)
- ✅ `DELETE /api/users/:id` - Admin uniquement

#### 4. **Validateurs** (`validators/users.validator.js`)
- ✅ `createUserSchema` - Validation création
- ✅ `updateUserSchema` - Validation mise à jour

---

### Frontend Flutter (front/lib/)

#### 📝 Fichier Adapté: `app/data/services/users_api.dart`

**Changements:**
```dart
// ❌ Avant: Strapi
static const String baseUrl = 'http://193.111.250.244:3046/api';

// ✅ Après: Node.js Backend
static const String baseUrl = 'http://localhost:3001/api';
```

**Méthodes Adaptées:**
1. **`getUsers()`**
   - Parse le nouveau format: `{statusCode, message, success, data: [...]}`
   - Compatible avec ancien format Strapi
   - Retourne `List<User>`

2. **`createUser(User user, {String? password})`**
   - Parse réponse Node.js: `{..., data: user}`
   - Utilise payload: `{username, email, password, role, confirmed, blocked}`
   - Retourne `User`

3. **`updateUser(User user, {String? password})`**
   - Parse réponse Node.js: `{..., data: user}`
   - Payload compatible avec backend

4. **`_buildUserPayload()`** ⭐ IMPORTANTE
   - **AVANT:** Convertissait le rôle en ID (Strapi)
   - **APRÈS:** Passe le rôle directement en STRING (ADMIN, USER, TEACHER, etc.)
   - Compatible avec énums du backend Node.js

---

## 📋 Format de Réponse Backend

### GET /api/users (avec token Admin)
```json
{
  "statusCode": 200,
  "message": "Utilisateurs récupérés",
  "success": true,
  "data": [
    {
      "id": 1,
      "username": "testuser",
      "email": "test@example.com",
      "role": "USER",
      "confirmed": true,
      "blocked": false,
      "createdAt": "2026-04-01T10:18:06.881Z",
      "updatedAt": "2026-04-01T10:18:06.881Z"
    }
  ],
  "timestamp": "2026-04-01T11:01:52.504Z"
}
```

### POST /api/users (créer utilisateur)
```json
Request:
{
  "username": "newuser",
  "email": "newuser@example.com",
  "password": "securePassword123",
  "role": "STUDENT",
  "confirmed": true,
  "blocked": false
}

Response (201):
{
  "statusCode": 201,
  "message": "Utilisateur créé avec succès",
  "success": true,
  "data": {
    "id": 3,
    "username": "newuser",
    "email": "newuser@example.com",
    "role": "STUDENT",
    "confirmed": true,
    "blocked": false,
    "createdAt": "2026-04-01T11:02:00.000Z",
    "updatedAt": "2026-04-01T11:02:00.000Z"
  }
}
```

---

## 🔐 Authentification Requise

Tous les endpoints utilisateurs nécessitent:
- **Header:** `Authorization: Bearer <JWT_TOKEN>`
- **Origine:** Admin ou Teacher Director (sauf `/me` et `GET /:id` pour tous)

---

## ✅ Tests à Effectuer dans Flutter Web

### 1. Voir la liste des utilisateurs
```dart
// Dans UserController
await fetchUsers();
```

### 2. Créer un utilisateur
```dart
final newUser = User(
  id: 0,
  username: 'john_doe',
  email: 'john@example.com',
  role: 'STUDENT',
  confirmed: true,
  blocked: false,
  createdAt: DateTime.now(),
);
await addUser(newUser, password: 'securePassword123');
```

### 3. Mettre à jour un utilisateur
```dart
await editUser(user, password: 'newPassword123');
```

### 4. Supprimer un utilisateur
```dart
await removeUser(userId);
```

---

## 🚨 Points d'Attention

| ⚠️ Point | Solution |
|---------|----------|
| Rôles en STRING | Utiliser ENUM du backend: ADMIN, USER, TEACHER, STUDENT, etc. |
| Token JWT requis | Assurez-vous que le token est valide et non expiré |
| CORS + Authentification | Headers Bearer requis pour les requêtes |
| Réponse `{data: ...}` | Parser `decoded['data']` pour accéder aux utilisateurs |
| Validation côté serveur | Les validations Joi rejectent les données invalides |

---

## 📊 Rôles Disponibles

Enum `UserRole` dans Prisma:
- `ADMIN` - Administrateur système
- `TEACHERDIRECTOR` - Responsable pédagogique
- `TECHNICIAN` - Technicien
- `TEACHER` - Professeur
- `STUDENT` - Étudiant
- `USER` - Utilisateur standard

---

## 🎯 Status

✅ Backend Node.js: **COMPLET**
✅ Frontend Flutter Adapté: **COMPLET**
✅ Tests API: **PASSÉS**
⏳ Test dans Flutter Web: **À FAIRE**

Lancez Flutter Web et testez le menu **Utilisateurs** pour vérifier que tout fonctionne! 🚀
