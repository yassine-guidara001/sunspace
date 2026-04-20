const communicationService = require('../services/communication.service');

class CommunicationController {
  async getRecipients(req, res, next) {
    try {
      const result = await communicationService.getRecipients(req.query, {
        userId: req.user?.id,
      });
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async sendPrivateMessage(req, res, next) {
    try {
      const result = await communicationService.sendPrivateMessage(req.body, {
        userId: req.user?.id,
      });
      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getPrivateMessages(req, res, next) {
    try {
      const result = await communicationService.getPrivateMessages(req.query, {
        userId: req.user?.id,
      });
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async markPrivateMessageRead(req, res, next) {
    try {
      const result = await communicationService.markPrivateMessageRead(
        req.params.id,
        {
          userId: req.user?.id,
        }
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async deletePrivateMessages(req, res, next) {
    try {
      const result = await communicationService.deletePrivateMessages(
        req.query,
        {
          userId: req.user?.id,
        }
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async deleteOldPrivateMessages(req, res, next) {
    try {
      const result = await communicationService.deleteOldPrivateMessages(
        req.query,
        {
          userId: req.user?.id,
        }
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async createForumThread(req, res, next) {
    try {
      const result = await communicationService.createForumThread(req.body, {
        userId: req.user?.id,
      });
      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getForumThreads(req, res, next) {
    try {
      const result = await communicationService.getForumThreads(req.query);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async deleteOldForumThreads(req, res, next) {
    try {
      const result = await communicationService.deleteOldForumThreads(
        req.query,
        {
          userId: req.user?.id,
        }
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async deleteForumThreads(req, res, next) {
    try {
      const result = await communicationService.deleteForumThreads(
        req.query,
        {
          userId: req.user?.id,
        }
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async addForumReply(req, res, next) {
    try {
      const result = await communicationService.addForumReply(
        req.params.threadId,
        req.body,
        {
          userId: req.user?.id,
        }
      );
      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async addForumReplyAlias(req, res, next) {
    try {
      const result = await communicationService.addForumReplyFromPayload(req.body, {
        userId: req.user?.id,
      });
      return res.status(201).json(result);
    } catch (error) {
      next(error);
    }
  }

  async updateForumThreadStatus(req, res, next) {
    try {
      const result = await communicationService.updateForumThreadStatus(
        req.params.threadId,
        req.body,
        {
          userId: req.user?.id,
        }
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async validateForumReply(req, res, next) {
    try {
      const result = await communicationService.validateForumReply(req.body, {
        userId: req.user?.id,
      });
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async reactToForumReply(req, res, next) {
    try {
      const result = await communicationService.reactToForumReply(req.body, {
        userId: req.user?.id,
      });
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getSimilarForumThreads(req, res, next) {
    try {
      const result = await communicationService.getSimilarForumThreads(req.query);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async improveForumDraft(req, res, next) {
    try {
      const result = await communicationService.improveForumDraft(req.body);
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async chatWithSunspaceAssistant(req, res, next) {
    try {
      const result = await communicationService.chatWithSunspaceAssistant(req.body, {
        userId: req.user?.id,
      });
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async getForumNotifications(req, res, next) {
    try {
      const result = await communicationService.getForumNotifications(req.query, {
        userId: req.user?.id,
      });
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }

  async closeForumThread(req, res, next) {
    try {
      const result = await communicationService.closeForumThread(
        req.params.threadId,
        {
          userId: req.user?.id,
        }
      );
      return res.status(200).json(result);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CommunicationController();
