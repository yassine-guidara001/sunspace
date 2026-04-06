const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function upsertUser({ username, email, role, password }) {
  const hashedPassword = await bcrypt.hash(password, 10);
  return prisma.user.upsert({
    where: { email },
    update: {
      username,
      role,
      password: hashedPassword,
      confirmed: true,
      blocked: false,
    },
    create: {
      username,
      email,
      role,
      password: hashedPassword,
      confirmed: true,
      blocked: false,
    },
  });
}

async function upsertSpace(space) {
  return prisma.space.upsert({
    where: { slug: space.slug },
    update: {
      name: space.name,
      type: space.type,
      description: space.description,
      location: space.location,
      floor: space.floor,
      capacity: space.capacity,
      surface: space.surface,
      width: space.width,
      height: space.height,
      status: space.status,
      hourlyRate: space.hourlyRate,
      dailyRate: space.dailyRate,
      monthlyRate: space.monthlyRate,
      overtimeRate: space.overtimeRate,
      currency: space.currency,
      isCoworkingSpace: space.isCoworkingSpace,
      allowLimitedReservations: space.allowLimitedReservations,
      available24h: space.available24h,
      features: space.features,
      imageUrl: space.imageUrl,
    },
    create: space,
  });
}

async function upsertCourse({ title, description, level, price, status, instructorId }) {
  const existing = await prisma.course.findFirst({ where: { title } });
  if (existing) {
    return prisma.course.update({
      where: { id: existing.id },
      data: { description, level, price, status, instructorId },
    });
  }

  return prisma.course.create({
    data: { title, description, level, price, status, instructorId },
  });
}

async function upsertEquipmentByName(data) {
  const existing = await prisma.equipment.findFirst({ where: { name: data.name } });
  if (existing) {
    return prisma.equipment.update({
      where: { id: existing.id },
      data,
    });
  }
  return prisma.equipment.create({ data });
}

async function upsertAssociationByName(data) {
  const existing = await prisma.association.findFirst({ where: { name: data.name } });
  if (existing) {
    return prisma.association.update({
      where: { id: existing.id },
      data,
    });
  }
  return prisma.association.create({ data });
}

async function upsertTrainingSession({ title, courseId, instructorId, startDate, endDate, meetingUrl }) {
  const existing = await prisma.trainingSession.findFirst({ where: { title } });
  if (existing) {
    return prisma.trainingSession.update({
      where: { id: existing.id },
      data: {
        courseId,
        instructorId,
        startDate,
        endDate,
        meetingUrl,
        mystatus: 'Planifiee',
      },
    });
  }

  return prisma.trainingSession.create({
    data: {
      title,
      courseId,
      instructorId,
      type: 'En_ligne',
      maxParticipants: 20,
      startDate,
      endDate,
      meetingUrl,
      mystatus: 'Planifiee',
      description: `Session pour ${title}`,
    },
  });
}

async function upsertAssignmentByTitle({ title, description, dueDate, courseId, instructorId, maxPoints, passingScore }) {
  const existing = await prisma.assignment.findFirst({ where: { title } });
  if (existing) {
    return prisma.assignment.update({
      where: { id: existing.id },
      data: {
        description,
        dueDate,
        courseId,
        instructorId,
        maxPoints,
        passingScore,
      },
    });
  }

  return prisma.assignment.create({
    data: {
      title,
      description,
      dueDate,
      courseId,
      instructorId,
      maxPoints,
      passingScore,
    },
  });
}

async function ensureOpeningHours(spaceId) {
  const rows = [
    { dayOfWeek: 0, openTime: '09:00', closeTime: '17:00', closed: true },
    { dayOfWeek: 1, openTime: '08:00', closeTime: '22:00', closed: false },
    { dayOfWeek: 2, openTime: '08:00', closeTime: '22:00', closed: false },
    { dayOfWeek: 3, openTime: '08:00', closeTime: '22:00', closed: false },
    { dayOfWeek: 4, openTime: '08:00', closeTime: '22:00', closed: false },
    { dayOfWeek: 5, openTime: '08:00', closeTime: '22:00', closed: false },
    { dayOfWeek: 6, openTime: '09:00', closeTime: '18:00', closed: false },
  ];

  for (const row of rows) {
    await prisma.openingHour.upsert({
      where: {
        spaceId_dayOfWeek: {
          spaceId,
          dayOfWeek: row.dayOfWeek,
        },
      },
      update: {
        openTime: row.openTime,
        closeTime: row.closeTime,
        closed: row.closed,
      },
      create: {
        spaceId,
        dayOfWeek: row.dayOfWeek,
        openTime: row.openTime,
        closeTime: row.closeTime,
        closed: row.closed,
      },
    });
  }
}

async function ensureReservation(data) {
  const existing = await prisma.reservation.findFirst({
    where: {
      userId: data.userId,
      spaceId: data.spaceId,
      startDateTime: data.startDateTime,
    },
  });

  if (existing) {
    return prisma.reservation.update({
      where: { id: existing.id },
      data,
    });
  }

  return prisma.reservation.create({ data });
}

async function ensureNotification(data) {
  const existing = await prisma.notification.findFirst({
    where: {
      userId: data.userId,
      type: data.type,
      title: data.title,
    },
  });

  if (existing) {
    return prisma.notification.update({
      where: { id: existing.id },
      data,
    });
  }

  return prisma.notification.create({ data });
}

async function main() {
  console.log('Debut du seed de developpement...');

  const users = {
    admin: await upsertUser({
      username: 'admin_sunspace',
      email: 'admin@sunspace.gmail.com',
      role: 'ADMIN',
      password: 'admin1234',
    }),
    director: await upsertUser({
      username: 'director_sunspace',
      email: 'director@sunspace.tn',
      role: 'TEACHERDIRECTOR',
      password: 'director1234',
    }),
    technician: await upsertUser({
      username: 'tech_sunspace',
      email: 'tech@sunspace.tn',
      role: 'TECHNICIAN',
      password: 'tech1234',
    }),
    teacher: await upsertUser({
      username: 'teacher_samia',
      email: 'teacher@sunspace.tn',
      role: 'TEACHER',
      password: 'teacher1234',
    }),
    student1: await upsertUser({
      username: 'student_amal',
      email: 'student1@sunspace.tn',
      role: 'STUDENT',
      password: 'student1234',
    }),
    student2: await upsertUser({
      username: 'student_youssef',
      email: 'student2@sunspace.tn',
      role: 'STUDENT',
      password: 'student1234',
    }),
    student3: await upsertUser({
      username: 'student_leila',
      email: 'student3@sunspace.tn',
      role: 'STUDENT',
      password: 'student1234',
    }),
  };

  const spaces = {
    innovationHub: await upsertSpace({
      slug: 'espace-innovation-hub',
      name: 'Innovation Hub',
      type: 'Espace de Travail',
      description: 'Espace ouvert pour ideation et prototypage.',
      location: 'Campus A - Bloc 1',
      floor: 'RDC',
      capacity: 28,
      surface: 140,
      width: 14,
      height: 10,
      status: 'Disponible',
      hourlyRate: 35,
      dailyRate: 220,
      monthlyRate: 2400,
      overtimeRate: 45,
      currency: 'TND',
      isCoworkingSpace: true,
      allowLimitedReservations: true,
      available24h: false,
      features: JSON.stringify(['WiFi', 'Projecteur', 'Tableau blanc', 'Climatisation']),
      imageUrl: null,
    }),
    reunionAlpha: await upsertSpace({
      slug: 'salle-reunion-alpha',
      name: 'Salle Reunion Alpha',
      type: 'Salle de Reunion',
      description: 'Salle de reunion premium pour equipes et clients.',
      location: 'Campus A - Bloc 2',
      floor: '1',
      capacity: 12,
      surface: 45,
      width: 9,
      height: 5,
      status: 'Disponible',
      hourlyRate: 50,
      dailyRate: 320,
      monthlyRate: 3500,
      overtimeRate: 60,
      currency: 'TND',
      isCoworkingSpace: false,
      allowLimitedReservations: true,
      available24h: false,
      features: JSON.stringify(['Ecran 4K', 'Visioconference', 'Sonorisation']),
      imageUrl: null,
    }),
    studioCreatif: await upsertSpace({
      slug: 'studio-creatif',
      name: 'Studio Creatif',
      type: 'Studio Multimedia',
      description: 'Studio dedie a la creation video/audio et podcast.',
      location: 'Campus B - Bloc 1',
      floor: '2',
      capacity: 8,
      surface: 35,
      width: 7,
      height: 5,
      status: 'Disponible',
      hourlyRate: 65,
      dailyRate: 400,
      monthlyRate: 4200,
      overtimeRate: 80,
      currency: 'TND',
      isCoworkingSpace: false,
      allowLimitedReservations: true,
      available24h: false,
      features: JSON.stringify(['Microphones', 'Camera', 'Isolation phonique']),
      imageUrl: null,
    }),
    laboData: await upsertSpace({
      slug: 'labo-data',
      name: 'Labo Data',
      type: 'Laboratoire',
      description: 'Laboratoire analytique pour data science et IA.',
      location: 'Campus B - Bloc 3',
      floor: '1',
      capacity: 20,
      surface: 90,
      width: 10,
      height: 9,
      status: 'Disponible',
      hourlyRate: 55,
      dailyRate: 360,
      monthlyRate: 3900,
      overtimeRate: 70,
      currency: 'TND',
      isCoworkingSpace: false,
      allowLimitedReservations: true,
      available24h: true,
      features: JSON.stringify(['Stations GPU', 'Internet fibre', 'Tableau interactif']),
      imageUrl: null,
    }),
  };

  for (const space of Object.values(spaces)) {
    await ensureOpeningHours(space.id);
  }

  const equipments = {
    projector: await upsertEquipmentByName({
      name: 'Projecteur Epson X1',
      type: 'Projection',
      mystatus: 'Disponible',
      serialNumber: 'EPSON-X1-2026',
      purchaseDate: new Date('2026-01-10T00:00:00.000Z'),
      purchasePrice: 2600,
      pricePerDay: 45,
      warrantyExpiry: new Date('2028-01-10T00:00:00.000Z'),
      description: 'Projecteur HD pour presentations et formations.',
      notes: null,
      quantity: 2,
      available: true,
      imageUrl: null,
    }),
    camera: await upsertEquipmentByName({
      name: 'Camera Sony A7',
      type: 'Video',
      mystatus: 'Disponible',
      serialNumber: 'SONY-A7-55',
      purchaseDate: new Date('2025-11-08T00:00:00.000Z'),
      purchasePrice: 4900,
      pricePerDay: 90,
      warrantyExpiry: new Date('2027-11-08T00:00:00.000Z'),
      description: 'Camera pour captation et production de contenu.',
      notes: null,
      quantity: 1,
      available: true,
      imageUrl: null,
    }),
    laptop: await upsertEquipmentByName({
      name: 'Laptop Dell Precision',
      type: 'Informatique',
      mystatus: 'Disponible',
      serialNumber: 'DELL-PR-900',
      purchaseDate: new Date('2025-09-01T00:00:00.000Z'),
      purchasePrice: 5200,
      pricePerDay: 70,
      warrantyExpiry: new Date('2028-09-01T00:00:00.000Z'),
      description: 'Machine puissante pour design, 3D et IA.',
      notes: null,
      quantity: 6,
      available: true,
      imageUrl: null,
    }),
  };

  await prisma.spaceEquipment.createMany({
    data: [
      { spaceId: spaces.innovationHub.id, equipmentId: equipments.projector.id, quantity: 1 },
      { spaceId: spaces.reunionAlpha.id, equipmentId: equipments.projector.id, quantity: 1 },
      { spaceId: spaces.studioCreatif.id, equipmentId: equipments.camera.id, quantity: 1 },
      { spaceId: spaces.laboData.id, equipmentId: equipments.laptop.id, quantity: 4 },
    ],
    skipDuplicates: true,
  });

  const courses = {
    flutter: await upsertCourse({
      title: 'Flutter Masterclass',
      description: 'Creation d apps multi-plateformes avec Flutter et bonnes pratiques.',
      level: 'Intermediaire',
      price: 450,
      status: 'Publie',
      instructorId: users.teacher.id,
    }),
    ai: await upsertCourse({
      title: 'Initiation a l IA',
      description: 'Bases du machine learning, evaluation et mise en production.',
      level: 'Debutant',
      price: 380,
      status: 'Publie',
      instructorId: users.teacher.id,
    }),
    devops: await upsertCourse({
      title: 'DevOps en pratique',
      description: 'Pipelines CI/CD, observabilite et deploiement cloud.',
      level: 'Avance',
      price: 520,
      status: 'Publie',
      instructorId: users.director.id,
    }),
  };

  await prisma.enrollment.upsert({
    where: {
      studentId_courseId: {
        studentId: users.student1.id,
        courseId: courses.flutter.id,
      },
    },
    update: { mystatus: 'Active' },
    create: {
      studentId: users.student1.id,
      courseId: courses.flutter.id,
      mystatus: 'Active',
    },
  });

  await prisma.enrollment.upsert({
    where: {
      studentId_courseId: {
        studentId: users.student2.id,
        courseId: courses.ai.id,
      },
    },
    update: { mystatus: 'Active' },
    create: {
      studentId: users.student2.id,
      courseId: courses.ai.id,
      mystatus: 'Active',
    },
  });

  await prisma.enrollment.upsert({
    where: {
      studentId_courseId: {
        studentId: users.student3.id,
        courseId: courses.devops.id,
      },
    },
    update: { mystatus: 'Active' },
    create: {
      studentId: users.student3.id,
      courseId: courses.devops.id,
      mystatus: 'Active',
    },
  });

  const now = Date.now();
  const sessions = {
    flutterSession: await upsertTrainingSession({
      title: 'Session Flutter UI avancee',
      courseId: courses.flutter.id,
      instructorId: users.teacher.id,
      startDate: new Date(now + (2 * 24 * 60 * 60 * 1000)),
      endDate: new Date(now + (2 * 24 * 60 * 60 * 1000) + (2 * 60 * 60 * 1000)),
      meetingUrl: 'https://meet.google.com/sunspace-flutter',
    }),
    aiSession: await upsertTrainingSession({
      title: 'Session IA - modeles supervises',
      courseId: courses.ai.id,
      instructorId: users.teacher.id,
      startDate: new Date(now + (3 * 24 * 60 * 60 * 1000)),
      endDate: new Date(now + (3 * 24 * 60 * 60 * 1000) + (2 * 60 * 60 * 1000)),
      meetingUrl: 'https://meet.google.com/sunspace-ai',
    }),
  };

  await prisma.trainingSessionAttendee.upsert({
    where: {
      sessionId_userId: {
        sessionId: sessions.flutterSession.id,
        userId: users.student1.id,
      },
    },
    update: {},
    create: {
      sessionId: sessions.flutterSession.id,
      userId: users.student1.id,
    },
  });

  await prisma.trainingSessionAttendee.upsert({
    where: {
      sessionId_userId: {
        sessionId: sessions.aiSession.id,
        userId: users.student2.id,
      },
    },
    update: {},
    create: {
      sessionId: sessions.aiSession.id,
      userId: users.student2.id,
    },
  });

  const assignment1 = await upsertAssignmentByTitle({
    title: 'Mini-projet UI responsive',
    description: 'Concevoir une interface Flutter responsive avec etat reactif.',
    dueDate: new Date(now + (7 * 24 * 60 * 60 * 1000)),
    courseId: courses.flutter.id,
    instructorId: users.teacher.id,
    maxPoints: 100,
    passingScore: 60,
  });

  const assignment2 = await upsertAssignmentByTitle({
    title: 'Classification de donnees clients',
    description: 'Entrainer un modele simple et presenter les metriques.',
    dueDate: new Date(now + (10 * 24 * 60 * 60 * 1000)),
    courseId: courses.ai.id,
    instructorId: users.teacher.id,
    maxPoints: 100,
    passingScore: 60,
  });

  await prisma.submission.upsert({
    where: {
      assignmentId_studentId: {
        assignmentId: assignment1.id,
        studentId: users.student1.id,
      },
    },
    update: {
      content: 'Prototype mobile + web avec architecture MVC.',
      grade: 88,
      status: 'GRADED',
    },
    create: {
      assignmentId: assignment1.id,
      studentId: users.student1.id,
      content: 'Prototype mobile + web avec architecture MVC.',
      grade: 88,
      status: 'GRADED',
    },
  });

  await prisma.submission.upsert({
    where: {
      assignmentId_studentId: {
        assignmentId: assignment2.id,
        studentId: users.student2.id,
      },
    },
    update: {
      content: 'Notebook avec modele RandomForest et rapport des resultats.',
      grade: 91,
      status: 'GRADED',
    },
    create: {
      assignmentId: assignment2.id,
      studentId: users.student2.id,
      content: 'Notebook avec modele RandomForest et rapport des resultats.',
      grade: 91,
      status: 'GRADED',
    },
  });

  const associationTech = await upsertAssociationByName({
    name: 'Club Tech Sunspace',
    description: 'Association etudiante autour des projets numeriques.',
    email: 'clubtech@sunspace.tn',
    phone: '+21671000001',
    website: 'https://sunspace.tn/club-tech',
    budget: 15000,
    currency: 'TND',
    verified: true,
    logoUrl: null,
    adminId: users.student1.id,
  });

  const associationMedia = await upsertAssociationByName({
    name: 'Creative Media Lab',
    description: 'Association dediee a la creation multimedia et evenements.',
    email: 'media.lab@sunspace.tn',
    phone: '+21671000002',
    website: 'https://sunspace.tn/media-lab',
    budget: 10000,
    currency: 'TND',
    verified: true,
    logoUrl: null,
    adminId: users.student2.id,
  });

  await prisma.associationMember.upsert({
    where: {
      associationId_userId: {
        associationId: associationTech.id,
        userId: users.student1.id,
      },
    },
    update: { role: 'ADMIN' },
    create: {
      associationId: associationTech.id,
      userId: users.student1.id,
      role: 'ADMIN',
    },
  });

  await prisma.associationMember.upsert({
    where: {
      associationId_userId: {
        associationId: associationTech.id,
        userId: users.student3.id,
      },
    },
    update: { role: 'MEMBER' },
    create: {
      associationId: associationTech.id,
      userId: users.student3.id,
      role: 'MEMBER',
    },
  });

  await prisma.associationMember.upsert({
    where: {
      associationId_userId: {
        associationId: associationMedia.id,
        userId: users.student2.id,
      },
    },
    update: { role: 'ADMIN' },
    create: {
      associationId: associationMedia.id,
      userId: users.student2.id,
      role: 'ADMIN',
    },
  });

  const reservation1 = await ensureReservation({
    userId: users.student1.id,
    spaceId: spaces.reunionAlpha.id,
    status: 'CONFIRMED',
    startDateTime: new Date(now + (1 * 24 * 60 * 60 * 1000) + (9 * 60 * 60 * 1000)),
    endDateTime: new Date(now + (1 * 24 * 60 * 60 * 1000) + (11 * 60 * 60 * 1000)),
    organizerName: 'Amal Ben Ali',
    organizerPhone: '+21620111222',
    attendees: 6,
    isAllDay: false,
    totalAmount: 100,
    paymentMethod: 'Carte',
    paymentStatus: 'Payee',
    notes: 'Reunion de lancement projet mobile.',
  });

  const reservation2 = await ensureReservation({
    userId: users.student2.id,
    spaceId: spaces.studioCreatif.id,
    status: 'PENDING',
    startDateTime: new Date(now + (2 * 24 * 60 * 60 * 1000) + (14 * 60 * 60 * 1000)),
    endDateTime: new Date(now + (2 * 24 * 60 * 60 * 1000) + (17 * 60 * 60 * 1000)),
    organizerName: 'Youssef Trabelsi',
    organizerPhone: '+21620444555',
    attendees: 4,
    isAllDay: false,
    totalAmount: 195,
    paymentMethod: 'Especes',
    paymentStatus: 'En attente',
    notes: 'Enregistrement podcast et video courte.',
  });

  const reservation3 = await ensureReservation({
    userId: users.student3.id,
    spaceId: spaces.laboData.id,
    status: 'CONFIRMED',
    startDateTime: new Date(now + (4 * 24 * 60 * 60 * 1000) + (10 * 60 * 60 * 1000)),
    endDateTime: new Date(now + (4 * 24 * 60 * 60 * 1000) + (13 * 60 * 60 * 1000)),
    organizerName: 'Leila Gharbi',
    organizerPhone: '+21622333444',
    attendees: 8,
    isAllDay: false,
    totalAmount: 165,
    paymentMethod: 'Virement',
    paymentStatus: 'Payee',
    notes: 'Atelier data visualisation.',
  });

  await ensureNotification({
    userId: users.student1.id,
    type: 'RESERVATION_CONFIRMATION',
    title: 'Reservation confirmee',
    body: 'Votre reservation de la Salle Reunion Alpha est confirmee.',
    isRead: false,
    reservationId: reservation1.id,
    courseId: null,
    sessionId: null,
    data: {
      spaceName: spaces.reunionAlpha.name,
      reservationId: reservation1.id,
    },
  });

  await ensureNotification({
    userId: users.student2.id,
    type: 'RESERVATION_REMINDER_24H',
    title: 'Rappel reservation (24h)',
    body: 'Rappel: votre reservation du Studio Creatif approche.',
    isRead: false,
    reservationId: reservation2.id,
    courseId: null,
    sessionId: null,
    data: {
      spaceName: spaces.studioCreatif.name,
      reservationId: reservation2.id,
    },
  });

  await ensureNotification({
    userId: users.student3.id,
    type: 'NEW_COURSE_AVAILABLE',
    title: 'Nouveau cours disponible',
    body: 'Le cours DevOps en pratique est maintenant publie.',
    isRead: false,
    reservationId: null,
    courseId: courses.devops.id,
    sessionId: null,
    data: {
      courseTitle: courses.devops.title,
    },
  });

  await ensureNotification({
    userId: users.student1.id,
    type: 'TRAINING_SESSION_STARTED',
    title: 'Session de formation planifiee',
    body: 'Votre session Flutter UI avancee est programmee.',
    isRead: false,
    reservationId: null,
    courseId: courses.flutter.id,
    sessionId: sessions.flutterSession.id,
    data: {
      sessionTitle: sessions.flutterSession.title,
    },
  });

  console.log('Seed termine avec succes.');
  console.log('Comptes de test:');
  console.log('- admin@sunspace.gmail.com / admin1234');
  console.log('- teacher@sunspace.tn / teacher1234');
  console.log('- student1@sunspace.tn / student1234');
  console.log('- student2@sunspace.tn / student1234');
  console.log('- student3@sunspace.tn / student1234');

  console.log('Reservations creees/maj: ', [reservation1.id, reservation2.id, reservation3.id].join(', '));
}

main()
  .catch((error) => {
    console.error('Erreur pendant le seed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
