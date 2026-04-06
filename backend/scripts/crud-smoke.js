/* eslint-disable no-console */
const BASE_URL = process.env.API_BASE_URL || 'http://localhost:3001';

async function request(method, path, token, body) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_) {
    json = { raw: text };
  }

  return { ok: res.ok, status: res.status, json };
}

function unwrapData(payload) {
  if (!payload || typeof payload !== 'object') return null;
  if (payload.data && typeof payload.data === 'object') {
    if (payload.data.data && typeof payload.data.data === 'object') return payload.data.data;
    return payload.data;
  }
  return payload;
}

function extractId(payload) {
  const data = unwrapData(payload);
  if (!data) return null;
  if (typeof data.id === 'number') return data.id;
  if (Array.isArray(data) && data.length > 0 && typeof data[0].id === 'number') return data[0].id;
  return null;
}

async function assertOk(label, action) {
  try {
    const res = await action();
    if (!res.ok) {
      console.error(`FAIL ${label}: ${res.status}`, JSON.stringify(res.json));
      return { pass: false, res };
    }
    console.log(`PASS ${label}: ${res.status}`);
    return { pass: true, res };
  } catch (error) {
    console.error(`FAIL ${label}:`, error.message);
    return { pass: false, res: null };
  }
}

async function main() {
  const summary = { pass: 0, fail: 0 };

  const login = await assertOk('POST /api/auth/local', () =>
    request('POST', '/api/auth/local', null, {
      identifier: 'admin@sunspace.gmail.com',
      password: 'admin1234',
    })
  );

  if (!login.pass) {
    process.exitCode = 1;
    return;
  }

  const token = login.res.json?.data?.jwt || login.res.json?.jwt;
  if (!token) {
    console.error('FAIL auth: token manquant');
    process.exitCode = 1;
    return;
  }

  const usersGet = await assertOk('GET /api/users', () => request('GET', '/api/users', token));
  const usersList = unwrapData(usersGet.res?.json);
  const studentCandidate = Array.isArray(usersList)
    ? usersList.find((u) => u.role === 'STUDENT' || u.role === 'USER')
    : null;

  const testUsername = `usercrud${Date.now()}`;
  const testEmail = `${testUsername}@example.com`;

  const userCreate = await assertOk('POST /api/users', () =>
    request('POST', '/api/users', token, {
      username: testUsername,
      email: testEmail,
      password: 'User123456',
      role: 'USER',
    })
  );
  const userId = extractId(userCreate.res?.json);

  await assertOk('GET /api/users/me', () => request('GET', '/api/users/me', token));

  if (userId) {
    await assertOk('PUT /api/users/:id', () =>
      request('PUT', `/api/users/${userId}`, token, { confirmed: true, blocked: false })
    );
    await assertOk('DELETE /api/users/:id', () => request('DELETE', `/api/users/${userId}`, token));
  }

  await assertOk('GET /api/spaces', () => request('GET', '/api/spaces', token));
  const spaceCreate = await assertOk('POST /api/spaces', () =>
    request('POST', '/api/spaces', token, {
      name: `Space CRUD ${Date.now()}`,
      type: 'Salle de Reunion',
      location: 'Bloc C',
      floor: 'RDC',
      capacity: 10,
      status: 'Disponible',
      currency: 'TND',
    })
  );
  const spaceId = extractId(spaceCreate.res?.json);
  if (spaceId) {
    await assertOk('GET /api/spaces/:id', () => request('GET', `/api/spaces/${spaceId}`, token));
    await assertOk('PUT /api/spaces/:id', () =>
      request('PUT', `/api/spaces/${spaceId}`, token, { capacity: 12, location: 'Bloc D' })
    );
  }

  await assertOk('GET /api/equipment-assets', () => request('GET', '/api/equipment-assets', token));
  const eqCreate = await assertOk('POST /api/equipment-assets', () =>
    request('POST', '/api/equipment-assets', token, {
      name: `Equip CRUD ${Date.now()}`,
      type: 'Informatique',
      mystatus: 'Disponible',
      quantity: 1,
      spaceIds: spaceId ? [spaceId] : [],
    })
  );
  const eqId = extractId(eqCreate.res?.json);
  if (eqId) {
    await assertOk('GET /api/equipment-assets/:id', () => request('GET', `/api/equipment-assets/${eqId}`, token));
    await assertOk('PUT /api/equipment-assets/:id', () =>
      request('PUT', `/api/equipment-assets/${eqId}`, token, { notes: 'updated' })
    );
  }

  await assertOk('GET /api/courses', () => request('GET', '/api/courses', token));
  const courseCreate = await assertOk('POST /api/courses', () =>
    request('POST', '/api/courses', token, {
      title: `Cours CRUD ${Date.now()}`,
      description: 'test',
      level: 'Débutant',
      price: 100,
      status: 'Brouillon',
    })
  );
  const courseId = extractId(courseCreate.res?.json);
  if (courseId) {
    await assertOk('GET /api/courses/:id', () => request('GET', `/api/courses/${courseId}`, token));
    await assertOk('PUT /api/courses/:id', () =>
      request('PUT', `/api/courses/${courseId}`, token, { status: 'Publié', price: 120 })
    );
  }

  await assertOk('GET /api/training-sessions', () => request('GET', '/api/training-sessions', token));
  const tsCreate = await assertOk('POST /api/training-sessions', () =>
    request('POST', '/api/training-sessions', token, {
      title: `Session CRUD ${Date.now()}`,
      course: courseId,
      start_datetime: new Date(Date.now() + 3600000).toISOString(),
      end_datetime: new Date(Date.now() + 7200000).toISOString(),
      type: 'En_ligne',
      mystatus: 'Planifiée',
    })
  );
  const tsId = extractId(tsCreate.res?.json);
  if (tsId) {
    await assertOk('GET /api/training-sessions/:id', () => request('GET', `/api/training-sessions/${tsId}`, token));
    await assertOk('PUT /api/training-sessions/:id', () =>
      request('PUT', `/api/training-sessions/${tsId}`, token, { mystatus: 'En cours' })
    );
  }

  await assertOk('GET /api/assignments', () => request('GET', '/api/assignments', token));
  const assCreate = await assertOk('POST /api/assignments', () =>
    request('POST', '/api/assignments', token, {
      title: `Assignment CRUD ${Date.now()}`,
      due_date: new Date(Date.now() + 3 * 24 * 3600000).toISOString(),
      course: courseId,
      max_points: 100,
      passing_score: 50,
    })
  );
  const assignmentId = extractId(assCreate.res?.json);
  if (assignmentId) {
    await assertOk('GET /api/assignments/:id', () => request('GET', `/api/assignments/${assignmentId}`, token));
    await assertOk('PUT /api/assignments/:id', () =>
      request('PUT', `/api/assignments/${assignmentId}`, token, { max_points: 90 })
    );
  }

  await assertOk('GET /api/enrollments', () => request('GET', '/api/enrollments', token));
  let enrollmentId = null;
  if (studentCandidate && courseId) {
    const enrCreate = await assertOk('POST /api/enrollments', () =>
      request('POST', '/api/enrollments', token, {
        student: studentCandidate.id,
        course: courseId,
        mystatus: 'Active',
      })
    );
    enrollmentId = extractId(enrCreate.res?.json);
  }

  await assertOk('GET /api/submissions', () => request('GET', '/api/submissions', token));
  if (assignmentId && studentCandidate) {
    await assertOk('POST /api/submissions', () =>
      request('POST', '/api/submissions', token, {
        assignment: assignmentId,
        student: studentCandidate.id,
        content: 'Soumission test',
        status: 'SUBMITTED',
      })
    );
  }

  await assertOk('GET /api/reservations', () => request('GET', '/api/reservations', token));
  let reservationId = null;
  if (spaceId) {
    const start = new Date(Date.now() + 5 * 3600000);
    const end = new Date(Date.now() + 7 * 3600000);
    const resCreate = await assertOk('POST /api/reservations', () =>
      request('POST', '/api/reservations', token, {
        space: spaceId,
        start_datetime: start.toISOString(),
        end_datetime: end.toISOString(),
        attendees: 2,
      })
    );
    reservationId = extractId(resCreate.res?.json);
    if (reservationId) {
      await assertOk('PUT /api/reservations/:id', () =>
        request('PUT', `/api/reservations/${reservationId}`, token, { mystatus: 'Confirmée' })
      );
    }
  }

  await assertOk('GET /api/notifications', () => request('GET', '/api/notifications', token));
  await assertOk('GET /api/notifications/unread-count', () => request('GET', '/api/notifications/unread-count', token));
  await assertOk('PATCH /api/notifications/read-all', () => request('PATCH', '/api/notifications/read-all', token));

  await assertOk('GET /api/associations', () => request('GET', '/api/associations', token));
  let associationId = null;
  if (studentCandidate) {
    const assocCreate = await assertOk('POST /api/associations', () =>
      request('POST', '/api/associations', token, {
        name: `Association CRUD ${Date.now()}`,
        adminId: studentCandidate.id,
        budget: 1000,
        currency: 'TND',
      })
    );
    associationId = extractId(assocCreate.res?.json);
    if (associationId) {
      await assertOk('PUT /api/associations/:id', () =>
        request('PUT', `/api/associations/${associationId}`, token, { budget: 1200 })
      );
    }
  }

  if (reservationId) await assertOk('DELETE /api/reservations/:id', () => request('DELETE', `/api/reservations/${reservationId}`, token));
  if (enrollmentId) await assertOk('DELETE /api/enrollments/:id', () => request('DELETE', `/api/enrollments/${enrollmentId}`, token));
  if (assignmentId) await assertOk('DELETE /api/assignments/:id', () => request('DELETE', `/api/assignments/${assignmentId}`, token));
  if (tsId) await assertOk('DELETE /api/training-sessions/:id', () => request('DELETE', `/api/training-sessions/${tsId}`, token));
  if (courseId) await assertOk('DELETE /api/courses/:id', () => request('DELETE', `/api/courses/${courseId}`, token));
  if (associationId) await assertOk('DELETE /api/associations/:id', () => request('DELETE', `/api/associations/${associationId}`, token));
  if (eqId) await assertOk('DELETE /api/equipment-assets/:id', () => request('DELETE', `/api/equipment-assets/${eqId}`, token));
  if (spaceId) await assertOk('DELETE /api/spaces/:id', () => request('DELETE', `/api/spaces/${spaceId}`, token));

  console.log('CRUD smoke test termine.');

  if (summary.fail > 0) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error('Erreur smoke test:', error);
  process.exitCode = 1;
});
