const { PrismaClient } = require('@prisma/client');
const { ValidationError } = require('../utils/errors');

const prisma = new PrismaClient();

class SubmissionsService {
  _toInt(value) {
    if (value === undefined || value === null || value === '') return null;
    const parsed = parseInt(String(value), 10);
    return Number.isNaN(parsed) ? null : parsed;
  }

  _extractFilters(query = {}) {
    const assignmentId = this._toInt(
      query?.['filters[assignment][id][$eq]'] ?? query?.filters?.assignment?.id?.$eq
    );
    const studentId = this._toInt(
      query?.['filters[student][id][$eq]'] ?? query?.filters?.student?.id?.$eq
    );

    const page = this._toInt(query?.['pagination[page]']) || 1;
    const pageSize = this._toInt(query?.['pagination[pageSize]']) || 100;

    return { assignmentId, studentId, page, pageSize };
  }

  _mapSubmission(row) {
    return {
      id: row.id,
      assignment: row.assignment
        ? {
            id: row.assignment.id,
            documentId: String(row.assignment.id),
            title: row.assignment.title,
          }
        : row.assignmentId,
      student: {
        id: row.student.id,
        documentId: String(row.student.id),
        username: row.student.username,
        email: row.student.email,
      },
      status: row.status,
      submittedAt: row.submittedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  async getAll(query = {}) {
    const filters = this._extractFilters(query);

    const where = {};
    if (filters.assignmentId) where.assignmentId = filters.assignmentId;
    if (filters.studentId) where.studentId = filters.studentId;

    const [total, rows] = await prisma.$transaction([
      prisma.submission.count({ where }),
      prisma.submission.findMany({
        where,
        include: {
          assignment: { select: { id: true, title: true } },
          student: { select: { id: true, username: true, email: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (filters.page - 1) * filters.pageSize,
        take: filters.pageSize,
      }),
    ]);

    const data = rows.map((row) => this._mapSubmission(row));

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
    const payload = body && typeof body === 'object' && body.data && typeof body.data === 'object'
      ? body.data
      : body;

    const assignmentId = this._toInt(payload.assignment);
    const studentId = this._toInt(payload.student) || context.userId;

    if (!assignmentId || !studentId) {
      throw new ValidationError('assignment et student sont requis');
    }

    const row = await prisma.submission.upsert({
      where: {
        assignmentId_studentId: {
          assignmentId,
          studentId,
        },
      },
      create: {
        assignmentId,
        studentId,
        content: payload.content ? String(payload.content) : null,
        status: payload.status ? String(payload.status) : 'SUBMITTED',
      },
      update: {
        content: payload.content ? String(payload.content) : null,
        status: payload.status ? String(payload.status) : 'SUBMITTED',
        submittedAt: new Date(),
      },
      include: {
        assignment: { select: { id: true, title: true } },
        student: { select: { id: true, username: true, email: true } },
      },
    });

    return { data: this._mapSubmission(row) };
  }
}

module.exports = new SubmissionsService();
