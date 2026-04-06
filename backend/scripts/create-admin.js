// Script pour créer un utilisateur admin
// Usage: node scripts/create-admin.js

require('dotenv').config();
const bcryptjs = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function createAdmin() {
  try {
    console.log('🔧 Création de l\'utilisateur admin...\n');

    const username = 'admin';
    const email = 'admin@sunspace.gmail.com';
    const password = '123456789';

    // Vérifier si l'utilisateur existe déjà
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          { email },
          { username },
        ],
      },
    });

    if (existingUser) {
      console.log('⚠️  Utilisateur existe déjà:');
      console.log(`   ID: ${existingUser.id}`);
      console.log(`   Username: ${existingUser.username}`);
      console.log(`   Email: ${existingUser.email}`);
      console.log(`   Role: ${existingUser.role}`);
      await prisma.$disconnect();
      return;
    }

    // Hasher le mot de passe
    const hashedPassword = await bcryptjs.hash(password, 10);

    // Créer l'utilisateur
    const user = await prisma.user.create({
      data: {
        username,
        email,
        password: hashedPassword,
        role: 'ADMIN',
        confirmed: true,
        blocked: false,
      },
    });

    console.log('✅ Utilisateur admin créé avec succès!\n');
    console.log('📋 Détails du compte:');
    console.log(`   ID: ${user.id}`);
    console.log(`   Username: ${user.username}`);
    console.log(`   Email: ${user.email}`);
    console.log(`   Role: ${user.role}`);
    console.log(`   Confirmed: ${user.confirmed}`);
    console.log(`   Created: ${user.createdAt}\n`);
    console.log(`🔐 Mot de passe hashé: ${hashedPassword.substring(0, 20)}...\n`);
    console.log('✨ Vous pouvez maintenant vous connecter avec:');
    console.log(`   Email: ${email}`);
    console.log(`   Mot de passe: ${password}\n`);

  } catch (error) {
    console.error('❌ Erreur lors de la création:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

createAdmin();
