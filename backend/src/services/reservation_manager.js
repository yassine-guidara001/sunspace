const fs = require('fs/promises');
const path = require('path');

const STORAGE_PATH = path.resolve(__dirname, '../../data/reservations.json');

function _toIso(value) {
  if (value === undefined || value === null || value === '') return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toISOString();
}

function _sameSpace(a, b) {
  return String(a || '').trim() === String(b || '').trim();
}

class ReservationManager {
  async _readStore() {
    try {
      const raw = await fs.readFile(STORAGE_PATH, 'utf8');
      const parsed = JSON.parse(raw);
      if (!parsed || typeof parsed !== 'object') {
        return { reservations: [] };
      }
      if (!Array.isArray(parsed.reservations)) {
        return { reservations: [] };
      }
      return { reservations: parsed.reservations };
    } catch (error) {
      if (error && error.code === 'ENOENT') {
        return { reservations: [] };
      }
      throw error;
    }
  }

  async _writeStore(store) {
    const payload = {
      reservations: Array.isArray(store?.reservations) ? store.reservations : [],
    };
    await fs.mkdir(path.dirname(STORAGE_PATH), { recursive: true });
    await fs.writeFile(STORAGE_PATH, `${JSON.stringify(payload, null, 2)}\n`, 'utf8');
  }

  _overlaps(existing, incomingStartIso, incomingEndIso) {
    const existingStart = new Date(existing.startAt);
    const existingEnd = new Date(existing.endAt);
    const incomingStart = new Date(incomingStartIso);
    const incomingEnd = new Date(incomingEndIso);

    if (
      Number.isNaN(existingStart.getTime()) ||
      Number.isNaN(existingEnd.getTime()) ||
      Number.isNaN(incomingStart.getTime()) ||
      Number.isNaN(incomingEnd.getTime())
    ) {
      return false;
    }

    return existingStart < incomingEnd && existingEnd > incomingStart;
  }

  async reserve_space(user_id, space_id, datetime, options = {}) {
    const startIso = _toIso(datetime);
    if (!startIso) {
      return {
        ok: false,
        code: 'INVALID_DATE',
        message: 'Date/heure invalide pour la réservation.',
      };
    }

    const endIso = _toIso(options.endDatetime || new Date(new Date(startIso).getTime() + 60 * 60 * 1000));
    if (!endIso) {
      return {
        ok: false,
        code: 'INVALID_END_DATE',
        message: 'Créneau de fin invalide.',
      };
    }

    if (new Date(endIso) <= new Date(startIso)) {
      return {
        ok: false,
        code: 'INVALID_RANGE',
        message: 'Le créneau doit se terminer après le début.',
      };
    }

    const store = await this._readStore();

    const conflict = store.reservations.find((item) => {
      if (item.status === 'cancelled') return false;
      if (!_sameSpace(item.spaceId, space_id)) return false;
      return this._overlaps(item, startIso, endIso);
    });

    if (conflict) {
      return {
        ok: false,
        code: 'CONFLICT',
        message: 'Cet espace est déjà réservé sur ce créneau.',
        conflict,
      };
    }

    const now = new Date().toISOString();
    const reservation = {
      id: `rsv_${Date.now()}_${Math.floor(Math.random() * 10000)}`,
      userId: String(user_id),
      userName: String(options.userName || `User ${user_id}`),
      spaceId: String(space_id),
      startAt: startIso,
      endAt: endIso,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    };

    store.reservations.push(reservation);
    await this._writeStore(store);

    return {
      ok: true,
      reservation,
    };
  }

  async get_reservations(date_filter = {}, options = {}) {
    const store = await this._readStore();
    const userId = options.userId ? String(options.userId) : null;

    const start = _toIso(date_filter?.start || date_filter?.from || null);
    const end = _toIso(date_filter?.end || date_filter?.to || null);

    let items = store.reservations.filter((item) => item.status !== 'cancelled');

    if (userId) {
      items = items.filter((item) => String(item.userId) === userId);
    }

    if (start) {
      const startDate = new Date(start);
      items = items.filter((item) => new Date(item.endAt) >= startDate);
    }

    if (end) {
      const endDate = new Date(end);
      items = items.filter((item) => new Date(item.startAt) <= endDate);
    }

    items.sort((a, b) => new Date(a.startAt) - new Date(b.startAt));

    return items;
  }

  async cancel_reservation(user_id, space_id, datetime = null, options = {}) {
    const store = await this._readStore();
    const requester = String(user_id);
    const isAdmin = Boolean(options.isAdmin);
    const startIso = datetime ? _toIso(datetime) : null;

    const target = store.reservations.find((item) => {
      if (item.status === 'cancelled') return false;
      if (!_sameSpace(item.spaceId, space_id)) return false;
      if (!isAdmin && String(item.userId) !== requester) return false;
      if (startIso) {
        const delta = Math.abs(new Date(item.startAt).getTime() - new Date(startIso).getTime());
        return delta <= 30 * 60 * 1000;
      }
      return true;
    });

    if (!target) {
      return {
        ok: false,
        code: 'NOT_FOUND',
        message: 'Aucune réservation correspondante à annuler.',
      };
    }

    target.status = 'cancelled';
    target.cancelledAt = new Date().toISOString();
    target.updatedAt = target.cancelledAt;

    await this._writeStore(store);

    return {
      ok: true,
      reservation: target,
    };
  }
}

module.exports = new ReservationManager();
