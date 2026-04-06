# Sunspace Backend API Documentation

## 🚀 Installation & Lancement

### 1. Installez les dépendances
```bash
npm install
```

### 2. Configurez la base de données MySQL
Assurez-vous que MySQL est en cours d'exécution sur `localhost:3306`
- Database: `sunspace`
- User: `root`
- Password: (vide par défaut dans Laragon)

### 3. Appliquez les migrations Prisma
```bash
npm run prisma:migrate
```

### 4. Lancez le serveur
```bash
npm run dev
```

Le serveur démarre à `http://localhost:3001`

---

## 📋 Endpoints d'Authentification

### **POST /api/auth/local**
Authentifier un utilisateur (login)

**Request:**
```json
{
  "identifier": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Connexion réussie",
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "username": "username",
      "email": "user@example.com",
      "role": "USER",
      "confirmed": true,
      "blocked": false,
      "createdAt": "2024-04-01T10:00:00Z",
      "updatedAt": "2024-04-01T10:00:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "timestamp": "2024-04-01T10:00:00Z"
}
```

---

### **POST /api/auth/local/register**
Enregistrer un nouvel utilisateur

**Request:**
```json
{
  "username": "newuser",
  "email": "newuser@example.com",
  "password": "password123",
  "confirmPassword": "password123"
}
```

**Response (201):**
```json
{
  "statusCode": 201,
  "message": "Inscription réussie",
  "success": true,
  "data": {
    "user": { ... },
    "token": "...",
    "jwt": "..."
  }
}
```

---

### **GET /api/auth/me**
Obtenir l'utilisateur actuel authentifié

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "statusCode": 200,
  "message": "Utilisateur actuel",
  "success": true,
  "data": {
    "user": { ... }
  }
}
```

---

## 📋 Endpoints des Utilisateurs

### **GET /api/users/me**
Alias pour récupérer le profil actuel

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "statusCode": 200,
  "message": "Profil utilisateur",
  "success": true,
  "data": {
    "data": { user object }
  }
}
```

---

### **GET /api/users/:id**
Récupérer un utilisateur par ID

**Response:**
```json
{
  "statusCode": 200,
  "message": "Utilisateur récupéré",
  "success": true,
  "data": { user object }
}
```

---

## 🔒 En-têtes d'Authentification

Tous les endpoints protégés nécessitent un header `Authorization`:

```
Authorization: Bearer <JWT_TOKEN>
```

Le token est retourné lors du login ou de l'enregistrement.

---

## ✅ Variables d'Environnement (.env)

```env
PORT=3001
NODE_ENV=development
DATABASE_URL="mysql://root:@127.0.0.1:3306/sunspace"
JWT_SECRET="sunspace-secret-jwt-2024-dev"
JWT_EXPIRY="7d"
CORS_ORIGIN="http://localhost:3000"
```

---

## 🗄️ Structure de la Base de Données

### Table `User`
- `id` (INT, PK)
- `username` (VARCHAR, UNIQUE)
- `email` (VARCHAR, UNIQUE)
- `password` (VARCHAR, hashed)
- `role` (ENUM: ADMIN, TEACHERDIRECTOR, TECHNICIAN, TEACHER, STUDENT, USER)
- `confirmed` (BOOLEAN)
- `blocked` (BOOLEAN)
- `createdAt` (DATETIME)
- `updatedAt` (DATETIME)

---

## 🧪 Tester avec Curl

```bash
# Login
curl -X POST http://localhost:3001/api/auth/local \
  -H "Content-Type: application/json" \
  -d '{"identifier":"user@example.com","password":"password123"}'

# Register
curl -X POST http://localhost:3001/api/auth/local/register \
  -H "Content-Type: application/json" \
  -d '{
    "username":"newuser",
    "email":"newuser@example.com",
    "password":"password123",
    "confirmPassword":"password123"
  }'

# Get Current User
curl -X GET http://localhost:3001/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🚨 Gestion des Erreurs

Tous les erreurs retournent un format cohérent:

```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "success": false,
  "error": {
    "message": "...",
    "details": [...]
  },
  "timestamp": "2024-04-01T10:00:00Z"
}
```

---

## 🔐 Sécurité

✅ Mots de passe hashés (bcrypt)
✅ JWT pour l'authentification
✅ CORS configuré
✅ Helmet pour les headers de sécurité
✅ Rate limiting sur login
✅ Validation des données (Joi)
