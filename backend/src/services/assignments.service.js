const { PrismaClient } = require('@prisma/client');
const { NotFoundError, ValidationError, ConflictError } = require('../utils/errors');

const prisma = new PrismaClient();

class AssignmentsService {
  _extractPayload(body = {}) {
    if (body && typeof body === 'object' && body.data && typeof body.data === 'object') {
      return body.data;
    }
    return body;
  }

  _toInt(value) {
    if (value === undefined || value === null || value === '') return null;
    const parsed = parseInt(String(value), 10);
    if (Number.isNaN(parsed)) return null;
    if (parsed < -2147483648 || parsed > 2147483647) {
      return null;
    }
    return parsed;
  }

  _parseId(rawId) {
    const id = this._toInt(rawId);
    if (!id || id <= 0) {
      throw new ValidationError('ID devoir invalide');
    }
    return id;
  }

  _parseDate(value) {
    if (value === undefined || value === null || value === '') return null;
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      throw new ValidationError('Date limite invalide');
    }
    return date;
  }

  _normalizeDescription(value) {
    if (value === undefined || value === null) return null;

    if (Array.isArray(value)) {
      const chunks = [];

      for (const block of value) {
        if (!block || typeof block !== 'object') continue;
        const children = Array.isArray(block.children) ? block.children : [];
        for (const child of children) {
          if (!child || typeof child !== 'object') continue;
          const text = String(child.text || '').trim();
          if (text) chunks.push(text);
        }
      }

      const merged = chunks.join('\n').trim();
      return merged || null;
    }

    if (typeof value === 'object') {
      const text = String(value.text || '').trim();
      return text || null;
    }

    const text = String(value).trim();
    return text || null;
  }

  _resolveCourseId(payload = {}) {
    const directCourseId = this._toInt(payload.courseId ?? payload.course_id);
    if (directCourseId) return directCourseId;

    const courseValue = payload.course;

    if (courseValue && typeof courseValue === 'object') {
      const nestedId = this._toInt(courseValue.id ?? courseValue.courseId ?? courseValue.course_id);
      if (nestedId) return nestedId;
    }

    const fromCourseField = this._toInt(courseValue);
    if (fromCourseField) return fromCourseField;

    return null;
  }

  _extractQuery(query = {}) {
    const page = this._toInt(query?.['pagination[page]']) || 1;
    const pageSize = this._toInt(query?.['pagination[pageSize]']) || 100;

    const courseId = this._toInt(
      query?.['filters[course][id][$eq]'] ?? query?.filters?.course?.id?.$eq
    );

    const courseDocumentId = String(
      query?.['filters[course][documentId][$eq]'] ?? query?.filters?.course?.documentId?.$eq ?? ''
    ).trim();

    const instructorId = this._toInt(
      query?.['filters[course][instructor][id][$eq]'] ?? query?.filters?.course?.instructor?.id?.$eq
    );

    return { page, pageSize, courseId, courseDocumentId, instructorId };
  }

  _buildWhere(filters) {
    const where = {};

    if (filters.courseId) {
      where.courseId = filters.courseId;
    } else if (filters.courseDocumentId) {
      const asInt = this._toInt(filters.courseDocumentId);
      if (asInt) {
        where.courseId = asInt;
      }
    }

    if (filters.instructorId) {
      where.OR = [
        { instructorId: filters.instructorId },
        { course: { instructorId: filters.instructorId } },
      ];
    }

    return where;
  }

  _mapCourse(course) {
    if (!course) return null;
    return {
      id: course.id,
      documentId: String(course.id),
      title: course.title,
      name: course.title,
      instructor: course.instructorId ? { id: course.instructorId } : null,
    };
  }

  _mapAssignment(record) {
    return {
      id: record.id,
      documentId: String(record.id),
      title: record.title,
      description: record.description || '',
      due_date: record.dueDate ? record.dueDate.toISOString() : null,
      max_points: record.maxPoints ?? 100,
      passing_score: record.passingScore ?? 0,
      allow_late_submission: Boolean(record.allowLateSubmission),
      attachment: record.attachment || null,
      attachment_url: record.attachmentUrl || null,
      attachment_name: record.attachmentName || null,
      course: this._mapCourse(record.course),
      submissions: Array.isArray(record.submissions)
        ? record.submissions.map((item) => ({
            id: item.id,
            student: { id: item.studentId },
            status: item.status,
            submittedAt: item.submittedAt,
          }))
        : [],
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    };
  }

  _toCollection(items, page, pageSize, total) {
    const data = items.map((item) => this._mapAssignment(item));
    const pageCount = total > 0 ? Math.ceil(total / pageSize) : 1;

    return {
      data,
      meta: {
        pagination: {
          page,
          pageSize,
          pageCount,
          total,
        },
      },
    };
  }

  _toItem(item) {
    return { data: this._mapAssignment(item) };
  }

  _include() {
    return {
      course: {
        select: {
          id: true,
          title: true,
          instructorId: true,
        },
      },
      submissions: {
        select: {
          id: true,
          studentId: true,
          status: true,
          submittedAt: true,
        },
      },
    };
  }

  async getAll(query = {}) {
    const filters = this._extractQuery(query);
    const where = this._buildWhere(filters);

    const [total, rows] = await prisma.$transaction([
      prisma.assignment.count({ where }),
      prisma.assignment.findMany({
        where,
        include: this._include(),
        orderBy: { createdAt: 'desc' },
        skip: (filters.page - 1) * filters.pageSize,
        take: filters.pageSize,
      }),
    ]);

    return this._toCollection(rows, filters.page, filters.pageSize, total);
  }

  async getById(rawId) {
    const id = this._parseId(rawId);

    const row = await prisma.assignment.findUnique({
      where: { id },
      include: this._include(),
    });

    if (!row) {
      throw new NotFoundError('Devoir non trouvé');
    }

    return this._toItem(row);
  }

  async create(body, context = {}) {
    const payload = this._extractPayload(body);

    const title = String(payload.title || '').trim();
    if (!title) throw new ValidationError('Titre devoir requis');

    const dueDate = this._parseDate(payload.due_date ?? payload.dueDate);
    if (!dueDate) throw new ValidationError('Date limite requise');

    const maxPoints = this._toInt(payload.max_points ?? payload.maxPoints) ?? 100;
    const passingScore = this._toInt(payload.passing_score ?? payload.passing_grade ?? payload.passingGrade) ?? 0;

    const row = await prisma.assignment.create({
      data: {
        title,
        description: this._normalizeDescription(payload.description),
        dueDate,
        maxPoints,
        passingScore,
        allowLateSubmission: Boolean(payload.allow_late_submission ?? payload.allowLateSubmission),
        attachment: this._toInt(payload.attachment),
        attachmentUrl: payload.attachment_url ? String(payload.attachment_url).trim() : null,
        attachmentName: payload.attachment_name ? String(payload.attachment_name).trim() : null,
        courseId: this._resolveCourseId(payload),
        instructorId: context.userId || null,
      },
      include: this._include(),
    });

    return this._toItem(row);
  }

  async update(rawId, body) {
    const id = this._parseId(rawId);
    const payload = this._extractPayload(body);

    const existing = await prisma.assignment.findUnique({ where: { id } });
    if (!existing) {
      throw new NotFoundError('Devoir non trouvé');
    }

    const data = {};

    if (payload.title !== undefined) {
      const title = String(payload.title || '').trim();
      if (!title) throw new ValidationError('Titre devoir requis');
      data.title = title;
    }

    if (payload.description !== undefined) {
      data.description = this._normalizeDescription(payload.description);
    }
    if (payload.due_date !== undefined || payload.dueDate !== undefined) {
      data.dueDate = this._parseDate(payload.due_date ?? payload.dueDate);
    }
    if (payload.max_points !== undefined || payload.maxPoints !== undefined) {
      data.maxPoints = this._toInt(payload.max_points ?? payload.maxPoints) ?? 100;
    }
    if (payload.passing_score !== undefined || payload.passing_grade !== undefined || payload.passingGrade !== undefined) {
      data.passingScore = this._toInt(payload.passing_score ?? payload.passing_grade ?? payload.passingGrade) ?? 0;
    }
    if (payload.allow_late_submission !== undefined || payload.allowLateSubmission !== undefined) {
      data.allowLateSubmission = Boolean(payload.allow_late_submission ?? payload.allowLateSubmission);
    }
    if (payload.attachment !== undefined) data.attachment = this._toInt(payload.attachment);
    if (payload.attachment_url !== undefined) {
      data.attachmentUrl = payload.attachment_url
        ? String(payload.attachment_url).trim()
        : null;
    }
    if (payload.attachment_name !== undefined) {
      data.attachmentName = payload.attachment_name
        ? String(payload.attachment_name).trim()
        : null;
    }
    if (payload.course !== undefined || payload.courseId !== undefined || payload.course_id !== undefined) {
      data.courseId = this._resolveCourseId(payload);
    }

    const row = await prisma.assignment.update({
      where: { id },
      data,
      include: this._include(),
    });

    return this._toItem(row);
  }

  async delete(rawId) {
    const id = this._parseId(rawId);
    const existing = await prisma.assignment.findUnique({ where: { id } });
    if (!existing) throw new NotFoundError('Devoir non trouvé');

    await prisma.assignment.delete({ where: { id } });
    return { data: { id, deleted: true } };
  }
}

module.exports = new AssignmentsService();
