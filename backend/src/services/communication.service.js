const { PrismaClient } = require('@prisma/client');
const {
  ValidationError,
  NotFoundError,
  AuthorizationError,
} = require('../utils/errors');
const { hasAnyRole, ROLES, ROLE_FILTERS } = require('../utils/roles');
const notificationsService = require('./notifications.service');

const prisma = new PrismaClient();

const FORUM_ALLOWED_TAGS = new Set([
  'Question de cours',
  'Devoir',
  'Examen',
  'Ressource',
  'Travail de groupe',
  'Problème technique',
  'Autre',
]);

const FORUM_ALLOWED_STATUS = new Set(['OPEN', 'RESOLU', 'EN_ATTENTE']);
const FORUM_ALLOWED_REACTIONS = new Set(['LIKE', 'HELPFUL']);

class CommunicationService {
  _toInt(value) {
    const parsed = parseInt(String(value), 10);
    if (Number.isNaN(parsed) || parsed <= 0) return null;
    return parsed;
  }

  _extractPayload(body = {}) {
    if (body && typeof body === 'object' && body.data && typeof body.data === 'object') {
      return body.data;
    }
    return body;
  }

  _isTeacherRole(role = '') {
    return hasAnyRole(role, [ROLES.ENSEIGNANT]);
  }

  _isStudentRole(role = '') {
    return hasAnyRole(role, [ROLES.ETUDIANT]);
  }

  async _resolveUserOrThrow(userId) {
    const id = this._toInt(userId);
    if (!id) throw new ValidationError('ID utilisateur invalide');

    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundError('Utilisateur introuvable');

    return user;
  }

  _mapRecipient(user) {
    return {
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
    };
  }

  async getRecipients(query = {}, context = {}) {
    const userId = this._toInt(context.userId);
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const currentUser = await this._resolveUserOrThrow(userId);
    const target = String(query.type || '').toLowerCase();

    const where = { id: { not: userId } };

    if (this._isTeacherRole(currentUser.role)) {
      where.role = { in: ROLE_FILTERS.ETUDIANTS };
    } else if (this._isStudentRole(currentUser.role)) {
      if (target === 'teacher' || target === 'enseignant') {
        where.role = { in: ROLE_FILTERS.ENSEIGNANTS };
      } else {
        where.role = { in: ROLE_FILTERS.ETUDIANTS };
      }
    }

    const recipients = await prisma.user.findMany({
      where,
      orderBy: [{ username: 'asc' }],
      select: {
        id: true,
        username: true,
        email: true,
        role: true,
      },
      take: 100,
    });

    return {
      data: recipients.map((recipient) => this._mapRecipient(recipient)),
    };
  }

  _normalizeTags(rawTags) {
    if (!Array.isArray(rawTags)) return [];

    return rawTags
      .map((tag) => String(tag || '').trim())
      .filter((tag) => tag.length > 0)
      .filter((tag) => FORUM_ALLOWED_TAGS.has(tag))
      .slice(0, 3);
  }

  _normalizeStatus(rawStatus) {
    const status = String(rawStatus || '')
      .trim()
      .toUpperCase()
      .replace('É', 'E');

    if (status === 'RESOLVED' || status === 'RESOLU' || status === 'RÉSOLU') {
      return 'RESOLU';
    }
    if (status === 'PENDING' || status === 'EN_ATTENTE') {
      return 'EN_ATTENTE';
    }
    if (status === 'OPEN') {
      return 'OPEN';
    }
    return null;
  }

  _isPrismaUnknownFieldError(error = null) {
    const text = String(error?.message || error || '').toLowerCase();
    return (
      text.includes('unknown arg') ||
      text.includes('unknown field') ||
      text.includes('does not exist in type') ||
      text.includes('column')
    );
  }

  _withLegacyReplyDefaults(rows = []) {
    return rows.map((thread) => ({
      ...thread,
      replies: Array.isArray(thread.replies)
        ? thread.replies.map((reply) => ({
            likeCount: 0,
            helpfulCount: 0,
            isValidated: false,
            validatedAt: null,
            validatedBy: null,
            ...reply,
          }))
        : [],
    }));
  }

  _tokenizeForumText(value) {
    return String(value || '')
      .toLowerCase()
      .replace(/[^a-z0-9\sàâäéèêëîïôöùûüç]/gi, ' ')
      .split(/\s+/)
      .map((token) => token.trim())
      .filter((token) => token.length >= 3);
  }

  _scoreThreadSimilarity(queryTokens, thread) {
    const threadTokens = new Set([
      ...this._tokenizeForumText(thread.title),
      ...this._tokenizeForumText(thread.body),
      ...((Array.isArray(thread.tags) ? thread.tags : []).flatMap((tag) =>
        this._tokenizeForumText(tag)
      )),
    ]);

    if (queryTokens.length === 0 || threadTokens.size === 0) return 0;

    let overlap = 0;
    for (const token of queryTokens) {
      if (threadTokens.has(token)) overlap += 1;
    }

    return overlap / Math.max(1, queryTokens.length);
  }

  async _notifyForumReply({ thread, replyAuthor, reply }) {
    const notifications = [];

    if (thread.authorId !== replyAuthor.id) {
      notifications.push(
        notificationsService.createNotification({
          userId: thread.authorId,
          type: 'TEACHER_MESSAGE',
          title: this._isTeacherRole(replyAuthor.role)
            ? 'Nouveau commentaire enseignant'
            : 'Nouvelle réponse à votre discussion',
          body: `${replyAuthor.username} a répondu à "${thread.title}".`,
          notificationData: {
            scope: 'forum',
            event: this._isTeacherRole(replyAuthor.role)
              ? 'teacher_reply'
              : 'new_reply',
            threadId: thread.id,
            replyId: reply.id,
          },
        })
      );
    }

    await Promise.allSettled(notifications);
  }

  async sendPrivateMessage(body, context = {}) {
    const payload = this._extractPayload(body);

    const senderId = this._toInt(context.userId);
    const recipientId = this._toInt(payload.recipientId ?? payload.recipient_id);
    const subject = String(payload.subject || '').trim();
    const content = String(payload.body || payload.content || '').trim();

    if (!senderId) {
      throw new ValidationError('Utilisateur non authentifié');
    }

    if (!recipientId) {
      throw new ValidationError('Destinataire requis');
    }

    if (!content) {
      throw new ValidationError('Le message ne peut pas être vide');
    }

    if (senderId === recipientId) {
      throw new ValidationError('Vous ne pouvez pas vous envoyer un message à vous-même');
    }

    const [sender, recipient] = await Promise.all([
      this._resolveUserOrThrow(senderId),
      this._resolveUserOrThrow(recipientId),
    ]);

    const senderIsStudent = this._isStudentRole(sender.role);
    const senderIsTeacher = this._isTeacherRole(sender.role);
    const recipientIsStudent = this._isStudentRole(recipient.role);
    const recipientIsTeacher = this._isTeacherRole(recipient.role);

    if (senderIsStudent && !(recipientIsTeacher || recipientIsStudent)) {
      throw new AuthorizationError(
        'Un étudiant peut communiquer uniquement avec un enseignant ou un autre étudiant'
      );
    }

    if (senderIsTeacher && !recipientIsStudent) {
      throw new AuthorizationError(
        'Un enseignant peut communiquer uniquement avec des apprenants'
      );
    }

    const created = await prisma.privateMessage.create({
      data: {
        senderId,
        recipientId,
        subject: subject || null,
        body: content,
      },
      include: {
        sender: { select: { id: true, username: true, email: true, role: true } },
        recipient: { select: { id: true, username: true, email: true, role: true } },
      },
    });

    return { data: created };
  }

  async getPrivateMessages(query = {}, context = {}) {
    const userId = this._toInt(context.userId);
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const box = String(query.box || 'inbox').toLowerCase();
    const skip = this._toInt(query.skip) || 0;
    const take = this._toInt(query.take) || 30;

    const where =
      box === 'sent'
        ? { senderId: userId }
        : box === 'all'
          ? { OR: [{ senderId: userId }, { recipientId: userId }] }
          : { recipientId: userId };

    const [rows, total] = await Promise.all([
      prisma.privateMessage.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          sender: { select: { id: true, username: true, email: true, role: true } },
          recipient: { select: { id: true, username: true, email: true, role: true } },
        },
      }),
      prisma.privateMessage.count({ where }),
    ]);

    return {
      data: rows,
      meta: {
        pagination: {
          total,
          skip,
          take,
        },
      },
    };
  }

  async markPrivateMessageRead(rawMessageId, context = {}) {
    const userId = this._toInt(context.userId);
    const messageId = this._toInt(rawMessageId);

    if (!userId) throw new ValidationError('Utilisateur non authentifié');
    if (!messageId) throw new ValidationError('ID message invalide');

    const existing = await prisma.privateMessage.findUnique({
      where: { id: messageId },
    });

    if (!existing) throw new NotFoundError('Message introuvable');
    if (existing.recipientId !== userId) {
      throw new AuthorizationError('Accès non autorisé à ce message');
    }

    const updated = await prisma.privateMessage.update({
      where: { id: messageId },
      data: { isRead: true, readAt: new Date() },
    });

    return { data: updated };
  }

  async createForumThread(body, context = {}) {
    const payload = this._extractPayload(body);

    const authorId = this._toInt(context.userId);
    const title = String(payload.title || '').trim();
    const threadBody = String(payload.body || payload.content || '').trim();
    const tags = this._normalizeTags(payload.tags);

    if (!authorId) throw new ValidationError('Utilisateur non authentifié');
    if (!title) throw new ValidationError('Titre requis');
    if (!threadBody) throw new ValidationError('Contenu requis');

    const created = await prisma.forumThread.create({
      data: {
        authorId,
        title,
        body: threadBody,
        tags,
      },
      include: {
        author: { select: { id: true, username: true, email: true, role: true } },
      },
    });

    return { data: created };
  }

  async getForumThreads(query = {}) {
    const skip = this._toInt(query.skip) || 0;
    const take = this._toInt(query.take) || 30;
    const status = this._normalizeStatus(query.status);

    const where = {};
    if (status && FORUM_ALLOWED_STATUS.has(status)) {
      where.status = status;
    }

    let rows;
    let total;

    try {
      [rows, total] = await Promise.all([
        prisma.forumThread.findMany({
          where,
          skip,
          take,
          orderBy: { createdAt: 'desc' },
          include: {
            author: { select: { id: true, username: true, email: true, role: true } },
            replies: {
              orderBy: { createdAt: 'asc' },
              include: {
                author: { select: { id: true, username: true, email: true, role: true } },
                validatedBy: {
                  select: { id: true, username: true, email: true, role: true },
                },
              },
            },
          },
        }),
        prisma.forumThread.count({ where }),
      ]);
    } catch (error) {
      if (!this._isPrismaUnknownFieldError(error)) throw error;

      [rows, total] = await Promise.all([
        prisma.forumThread.findMany({
          where,
          skip,
          take,
          orderBy: { createdAt: 'desc' },
          include: {
            author: { select: { id: true, username: true, email: true, role: true } },
            replies: {
              orderBy: { createdAt: 'asc' },
              include: {
                author: { select: { id: true, username: true, email: true, role: true } },
              },
            },
          },
        }),
        prisma.forumThread.count({ where }),
      ]);

      rows = this._withLegacyReplyDefaults(rows);
    }

    return {
      data: rows,
      meta: {
        pagination: {
          total,
          skip,
          take,
        },
      },
    };
  }

  async addForumReply(rawThreadId, body, context = {}) {
    const payload = this._extractPayload(body);

    const threadId = this._toInt(rawThreadId);
    const authorId = this._toInt(context.userId);
    const replyBody = String(payload.body || payload.content || '').trim();

    if (!threadId) throw new ValidationError('ID discussion invalide');
    if (!authorId) throw new ValidationError('Utilisateur non authentifié');
    if (!replyBody) throw new ValidationError('Réponse vide');

    const [thread, replyAuthor] = await Promise.all([
      prisma.forumThread.findUnique({ where: { id: threadId } }),
      this._resolveUserOrThrow(authorId),
    ]);
    if (!thread) throw new NotFoundError('Discussion introuvable');
    if (thread.status === 'RESOLU') {
      throw new ValidationError('Cette discussion est fermée');
    }

    let created;
    try {
      created = await prisma.forumReply.create({
        data: {
          threadId,
          authorId,
          body: replyBody,
        },
        include: {
          author: { select: { id: true, username: true, email: true, role: true } },
          validatedBy: {
            select: { id: true, username: true, email: true, role: true },
          },
        },
      });
    } catch (error) {
      if (!this._isPrismaUnknownFieldError(error)) throw error;

      created = await prisma.forumReply.create({
        data: {
          threadId,
          authorId,
          body: replyBody,
        },
        include: {
          author: { select: { id: true, username: true, email: true, role: true } },
        },
      });
      created = {
        likeCount: 0,
        helpfulCount: 0,
        isValidated: false,
        validatedAt: null,
        validatedBy: null,
        ...created,
      };
    }

    await this._notifyForumReply({
      thread,
      replyAuthor,
      reply: created,
    });

    return { data: created };
  }

  async addForumReplyFromPayload(body, context = {}) {
    const payload = this._extractPayload(body);
    const threadId = payload.threadId ?? payload.thread_id;
    return this.addForumReply(threadId, payload, context);
  }

  async updateForumThreadStatus(rawThreadId, body, context = {}) {
    const threadId = this._toInt(rawThreadId);
    const userId = this._toInt(context.userId);
    const payload = this._extractPayload(body);
    const status = this._normalizeStatus(payload.status);

    if (!threadId) throw new ValidationError('ID discussion invalide');
    if (!userId) throw new ValidationError('Utilisateur non authentifié');
    if (!status || !FORUM_ALLOWED_STATUS.has(status)) {
      throw new ValidationError('Statut invalide (OPEN, RESOLU, EN_ATTENTE)');
    }

    const [thread, user] = await Promise.all([
      prisma.forumThread.findUnique({ where: { id: threadId } }),
      this._resolveUserOrThrow(userId),
    ]);

    if (!thread) throw new NotFoundError('Discussion introuvable');

    if (!this._isTeacherRole(user.role)) {
      throw new AuthorizationError('Seul un enseignant peut changer le statut');
    }

    const updated = await prisma.forumThread.update({
      where: { id: threadId },
      data: { status },
    });

    return { data: updated };
  }

  async validateForumReply(body, context = {}) {
    const payload = this._extractPayload(body);
    const replyId = this._toInt(payload.replyId ?? payload.reply_id);
    const teacherId = this._toInt(context.userId);

    if (!replyId) throw new ValidationError('Réponse invalide');
    if (!teacherId) throw new ValidationError('Utilisateur non authentifié');

    const teacher = await this._resolveUserOrThrow(teacherId);
    if (!this._isTeacherRole(teacher.role)) {
      throw new AuthorizationError('Seul un enseignant peut valider une réponse');
    }

    const reply = await prisma.forumReply.findUnique({
      where: { id: replyId },
      include: {
        thread: true,
      },
    });

    if (!reply) throw new NotFoundError('Réponse introuvable');

    let updated;
    try {
      await prisma.forumReply.updateMany({
        where: {
          threadId: reply.threadId,
          id: { not: reply.id },
        },
        data: {
          isValidated: false,
          validatedAt: null,
          validatedById: null,
        },
      });

      updated = await prisma.forumReply.update({
        where: { id: reply.id },
        data: {
          isValidated: true,
          validatedAt: new Date(),
          validatedById: teacherId,
        },
        include: {
          author: { select: { id: true, username: true, email: true, role: true } },
          validatedBy: {
            select: { id: true, username: true, email: true, role: true },
          },
        },
      });
    } catch (error) {
      if (this._isPrismaUnknownFieldError(error)) {
        throw new ValidationError(
          'Mise à jour base requise: exécutez "npx prisma db push" puis redémarrez le backend.'
        );
      }
      throw error;
    }

    await prisma.forumThread.update({
      where: { id: reply.threadId },
      data: { status: 'RESOLU' },
    });

    if (reply.authorId !== teacherId) {
      await notificationsService.createNotification({
        userId: reply.authorId,
        type: 'TEACHER_MESSAGE',
        title: 'Réponse validée par l\'enseignant',
        body: `${teacher.username} a validé votre réponse dans "${reply.thread.title}".`,
        notificationData: {
          scope: 'forum',
          event: 'reply_validated',
          threadId: reply.threadId,
          replyId: reply.id,
        },
      });
    }

    return { data: updated };
  }

  async reactToForumReply(body, context = {}) {
    const payload = this._extractPayload(body);
    const replyId = this._toInt(payload.replyId ?? payload.reply_id);
    const reactionType = String(payload.reactionType || payload.type || '')
      .trim()
      .toUpperCase();

    if (!this._toInt(context.userId)) {
      throw new ValidationError('Utilisateur non authentifié');
    }
    if (!replyId) throw new ValidationError('Réponse invalide');
    if (!FORUM_ALLOWED_REACTIONS.has(reactionType)) {
      throw new ValidationError('Réaction invalide (LIKE, HELPFUL)');
    }

    const existing = await prisma.forumReply.findUnique({ where: { id: replyId } });
    if (!existing) throw new NotFoundError('Réponse introuvable');

    let updated;
    try {
      updated = await prisma.forumReply.update({
        where: { id: replyId },
        data:
          reactionType === 'LIKE'
            ? { likeCount: { increment: 1 } }
            : { helpfulCount: { increment: 1 } },
        include: {
          author: { select: { id: true, username: true, email: true, role: true } },
          validatedBy: {
            select: { id: true, username: true, email: true, role: true },
          },
        },
      });
    } catch (error) {
      if (this._isPrismaUnknownFieldError(error)) {
        throw new ValidationError(
          'Mise à jour base requise: exécutez "npx prisma db push" puis redémarrez le backend.'
        );
      }
      throw error;
    }

    return { data: updated };
  }

  async getSimilarForumThreads(query = {}) {
    const text = String(query.q || query.text || '').trim();
    if (!text) {
      return { data: [] };
    }

    const tokens = this._tokenizeForumText(text);
    const candidates = await prisma.forumThread.findMany({
      orderBy: { createdAt: 'desc' },
      take: 80,
      select: {
        id: true,
        title: true,
        body: true,
        status: true,
        tags: true,
        createdAt: true,
      },
    });

    const scored = candidates
      .map((thread) => ({
        ...thread,
        score: this._scoreThreadSimilarity(tokens, thread),
      }))
      .filter((thread) => thread.score >= 0.2)
      .sort((a, b) => b.score - a.score)
      .slice(0, 5);

    return { data: scored };
  }

  async improveForumDraft(body = {}) {
    const payload = this._extractPayload(body);
    const rawTitle = String(payload.title || '').trim();
    const rawContent = String(payload.body || payload.content || '').trim();

    if (!rawTitle && !rawContent) {
      throw new ValidationError('Titre ou contenu requis');
    }

    const normalizedContent = rawContent
      .replace(/\s+/g, ' ')
      .replace(/\s([,.;!?])/g, '$1')
      .trim();

    const suggestedTitle = rawTitle.isNotEmpty
      ? rawTitle[0].toUpperCase() + rawTitle.slice(1)
      : `Question: ${normalizedContent.split(' ').slice(0, 10).join(' ')}`;

    const suggestedTags = this._normalizeTags(payload.tags).length > 0
      ? this._normalizeTags(payload.tags)
      : this._suggestTagsFromText(`${suggestedTitle} ${normalizedContent}`);

    return {
      data: {
        title: suggestedTitle,
        body: normalizedContent,
        tags: suggestedTags,
        note:
          'Assistant local: texte clarifié, titre reformulé et tags suggérés automatiquement.',
      },
    };
  }

  _suggestTagsFromText(text) {
    const value = String(text || '').toLowerCase();
    if (value.includes('devoir') || value.includes('rendu')) {
      return ['Devoir', 'Question de cours'];
    }
    if (value.includes('examen') || value.includes('test')) {
      return ['Examen', 'Question de cours'];
    }
    if (value.includes('erreur') || value.includes('bug') || value.includes('connexion')) {
      return ['Problème technique', 'Autre'];
    }
    if (value.includes('groupe') || value.includes('équipe')) {
      return ['Travail de groupe', 'Ressource'];
    }
    return ['Question de cours', 'Autre'];
  }

  async getForumNotifications(query = {}, context = {}) {
    const userId = this._toInt(context.userId);
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const take = this._toInt(query.take) || 20;
    const skip = this._toInt(query.skip) || 0;

    const rows = await prisma.notification.findMany({
      where: {
        userId,
        type: 'TEACHER_MESSAGE',
      },
      orderBy: { createdAt: 'desc' },
      take: take + skip + 40,
    });

    const forumRows = rows.filter((row) => row?.data?.scope === 'forum');
    const paged = forumRows.slice(skip, skip + take);

    return {
      data: paged,
      meta: {
        pagination: {
          total: forumRows.length,
          skip,
          take,
        },
      },
    };
  }

  async closeForumThread(rawThreadId, context = {}) {
    const threadId = this._toInt(rawThreadId);
    const userId = this._toInt(context.userId);

    if (!threadId) throw new ValidationError('ID discussion invalide');
    if (!userId) throw new ValidationError('Utilisateur non authentifié');

    const [thread, user] = await Promise.all([
      prisma.forumThread.findUnique({ where: { id: threadId } }),
      this._resolveUserOrThrow(userId),
    ]);

    if (!thread) throw new NotFoundError('Discussion introuvable');

    const canClose =
      thread.authorId === userId ||
      this._isTeacherRole(user.role) ||
      String(user.role || '').toLowerCase().includes('admin');

    if (!canClose) {
      throw new AuthorizationError('Vous ne pouvez pas fermer cette discussion');
    }

    const updated = await prisma.forumThread.update({
      where: { id: threadId },
      data: { status: 'EN_ATTENTE' },
    });

    return { data: updated };
  }
}

module.exports = new CommunicationService();
