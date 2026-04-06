const { PrismaClient } = require('@prisma/client');
const { ValidationError, ConflictError, NotFoundError } = require('../utils/errors');

const prisma = new PrismaClient();

class EnrollmentsService {
  _toInt(value) {
    if (value === undefined || value === null || value === '') return null;
    const parsed = parseInt(String(value), 10);
    return Number.isNaN(parsed) ? null : parsed;
  }

  _extractPayload(body = {}) {
    if (body && typeof body === 'object' && body.data && typeof body.data === 'object') {
      return body.data;
    }
    return body;
  }

  _extractFilters(query = {}) {
    const studentId = this._toInt(
      query?.['filters[student][id][$eq]'] ?? query?.filters?.student?.id?.$eq
    );
    const instructorId = this._toInt(
      query?.['filters[course][instructor][id][$eq]'] ?? query?.filters?.course?.instructor?.id?.$eq
    );

    const page = this._toInt(query?.['pagination[page]']) || 1;
    const pageSize = this._toInt(query?.['pagination[pageSize]']) || 100;

    return { studentId, instructorId, page, pageSize };
  }

  _mapEnrollment(row) {
    return {
      id: row.id,
      documentId: String(row.id),
      mystatus: row.mystatus,
      enrolled_at: row.enrolledAt,
      student: row.student
        ? {
            id: row.student.id,
            documentId: String(row.student.id),
            username: row.student.username,
            email: row.student.email,
          }
        : null,
      course: row.course
        ? {
            id: row.course.id,
            documentId: String(row.course.id),
            title: row.course.title,
            instructor: row.course.instructorId ? { id: row.course.instructorId } : null,
          }
        : null,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  async getAll(query = {}) {
    const filters = this._extractFilters(query);

    const where = {};
    if (filters.studentId) where.studentId = filters.studentId;
    if (filters.instructorId) {
      where.course = { instructorId: filters.instructorId };
    }

    const [total, rows] = await prisma.$transaction([
      prisma.enrollment.count({ where }),
      prisma.enrollment.findMany({
        where,
        include: {
          student: { select: { id: true, username: true, email: true } },
          course: { select: { id: true, title: true, instructorId: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (filters.page - 1) * filters.pageSize,
        take: filters.pageSize,
      }),
    ]);

    const data = rows.map((row) => this._mapEnrollment(row));

    return {
      data,
      meta: {
        pagination: {
          page: filters.page,
          pageSize: filters.pageSize,
          pageCount: total > 0 ? Math.ceil(total / filters.pageSize) : 1,
          total,
        },
      },
    };
  }

  async create(body, context = {}) {
    const payload = this._extractPayload(body);

    const studentId = this._toInt(payload.student) || context.userId;
    const courseId = this._toInt(payload.course);

    if (!studentId || !courseId) {
      throw new ValidationError('student et course sont requis');
    }

    const existing = await prisma.enrollment.findUnique({
      where: {
        studentId_courseId: {
          studentId,
          courseId,
        },
      },
    });

    if (existing) {
      throw new ConflictError('Inscription déjà existante');
    }

    const row = await prisma.enrollment.create({
      data: {
        studentId,
        courseId,
        mystatus: payload.mystatus ? String(payload.mystatus) : 'Active',
      },
      include: {
        student: { select: { id: true, username: true, email: true } },
        course: { select: { id: true, title: true, instructorId: true } },
      },
    });

    return { data: this._mapEnrollment(row) };
  }

  async delete(rawId) {
    const id = this._toInt(rawId);
    if (!id || id <= 0) throw new ValidationError('ID enrollment invalide');

    const existing = await prisma.enrollment.findUnique({ where: { id } });
    if (!existing) throw new NotFoundError('Enrollment non trouvé');

    await prisma.enrollment.delete({ where: { id } });
    return { data: { id, deleted: true } };
  }
}

module.exports = new EnrollmentsService();
