<template>
  <transition name="notif-panel">
    <div
      v-if="open"
      ref="panelRef"
      class="notification-panel"
      role="dialog"
      aria-label="Notifications"
      @click.stop
    >
      <header class="panel-header">
        <div class="title-wrap">
          <h3 class="panel-title">Notifications</h3>
          <span class="count-badge">{{ unreadCount }}</span>
        </div>
        <button
          type="button"
          class="mark-all"
          :disabled="unreadCount === 0"
          @click="markAllAsRead"
        >
          Tout marquer comme lu
        </button>
      </header>

      <section class="panel-list" aria-live="polite">
        <article
          v-for="item in localNotifications"
          :key="item.id"
          class="notification-item"
          :class="{ unread: !item.read }"
          @click="markOneAsRead(item)"
        >
          <div class="item-left">
            <span class="type-icon-wrap" :style="{ backgroundColor: getTypeMeta(item.type).bg }">
              <span
                class="type-icon"
                :style="{ color: getTypeMeta(item.type).color }"
                aria-hidden="true"
              >
                {{ getTypeMeta(item.type).icon }}
              </span>
            </span>

            <div class="item-content">
              <p class="item-title">{{ item.title }}</p>
              <p class="item-description">{{ item.description }}</p>
            </div>
          </div>

          <div class="item-right">
            <time class="item-time">{{ formatRelativeTime(item.createdAt) }}</time>
            <span v-if="!item.read" class="unread-dot" aria-label="Non lue">•</span>
          </div>
        </article>

        <p v-if="localNotifications.length === 0" class="empty-state">
          Aucune notification
        </p>
      </section>

      <footer class="panel-footer">
        <button type="button" class="view-all-btn" @click="openAllNotifications">
          Voir toutes les notifications
        </button>
      </footer>
    </div>
  </transition>
</template>

<script setup>
import { computed, ref, watch, onMounted, onUnmounted } from 'vue';

const props = defineProps({
  open: {
    type: Boolean,
    default: false,
  },
  notifications: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits([
  'update:open',
  'mark-read',
  'mark-all-read',
  'open-all',
]);

const panelRef = ref(null);
const localNotifications = ref([]);

const normalizeType = (type) => {
  const normalized = String(type || '').trim().toLowerCase();

  if (
    normalized === 'reservation_modified' ||
    normalized === 'reservation_modifiee' ||
    normalized === 'reservation_modified'.replace('-', '_')
  ) {
    return 'reservation_modified';
  }

  if (
    normalized === 'reservation_confirmed' ||
    normalized === 'reservation_confirmation' ||
    normalized === 'reservation_confirmee' ||
    normalized === 'reservation_confirmed'.replace('-', '_') ||
    normalized === 'reservation_confirmation'.replace('-', '_')
  ) {
    return 'reservation_confirmed';
  }

  return 'info';
};

const hydrateNotifications = (input = []) => {
  localNotifications.value = input.map((n, index) => ({
    id: n.id ?? `notification-${index}`,
    type: normalizeType(n.type),
    title: n.title || 'Notification',
    description: n.description || n.body || '',
    createdAt: n.createdAt || n.timestamp || new Date().toISOString(),
    read: n.read === true || n.isRead === true,
  }));
};

watch(
  () => props.notifications,
  (value) => {
    hydrateNotifications(value || []);
  },
  { immediate: true, deep: true }
);

const unreadCount = computed(
  () => localNotifications.value.filter((n) => !n.read).length
);

const getTypeMeta = (type) => {
  if (type === 'reservation_modified') {
    return { icon: '✎', color: '#F57C00', bg: '#FFF3E0' };
  }

  if (type === 'reservation_confirmed') {
    return { icon: '✓', color: '#43A047', bg: '#E8F5E9' };
  }

  return { icon: '🔔', color: '#1E88E5', bg: '#E3F2FD' };
};

const formatRelativeTime = (rawDate) => {
  const date = new Date(rawDate);
  if (Number.isNaN(date.getTime())) {
    return 'à l\'instant';
  }

  const diffMs = Date.now() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);

  if (diffMin < 1) return 'à l\'instant';
  if (diffMin < 60) return `il y a ${diffMin} min`;

  const diffHours = Math.floor(diffMin / 60);
  if (diffHours < 24) return `il y a ${diffHours} h`;

  const diffDays = Math.floor(diffHours / 24);
  return `il y a ${diffDays} j`;
};

const markOneAsRead = (item) => {
  if (!item.read) {
    item.read = true;
    emit('mark-read', item);
  }
};

const markAllAsRead = () => {
  if (unreadCount.value === 0) return;

  localNotifications.value = localNotifications.value.map((item) => ({
    ...item,
    read: true,
  }));

  emit('mark-all-read', localNotifications.value);
};

const openAllNotifications = () => {
  emit('open-all');
  emit('update:open', false);
};

const handleClickOutside = (event) => {
  if (panelRef.value && !panelRef.value.contains(event.target)) {
    emit('update:open', false);
  }
};

onMounted(() => {
  document.addEventListener('mousedown', handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener('mousedown', handleClickOutside);
});
</script>

<style scoped>
.notification-panel {
  position: absolute;
  top: 100%;
  right: 0;
  z-index: 9999;
  width: 380px;
  max-height: 480px;
  display: flex;
  flex-direction: column;
  background: #fafafa;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.12);
  border: 1px solid #dcdcdc;
  overflow: hidden;
  margin-top: 8px;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px;
  border-bottom: 1px solid #eeeeee;
  background: #fafafa;
}

.title-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}

.panel-title {
  margin: 0;
  font-size: 15px;
  font-weight: 700;
  color: #242424;
}

.count-badge {
  min-width: 22px;
  height: 22px;
  padding: 0 7px;
  border-radius: 999px;
  background: #1e88e5;
  color: #ffffff;
  font-size: 12px;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.mark-all {
  height: 42px;
  border-radius: 14px;
  border: 1px solid #bdbdbd;
  background: #fafafa;
  color: #303030;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  padding: 0 18px;
}

.mark-all:disabled {
  opacity: 0.5;
  cursor: default;
}

.panel-list {
  overflow-y: auto;
  max-height: 360px;
  background: #f7f7f7;
}

.notification-item {
  padding: 12px 16px;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
  border-bottom: 1px solid #eeeeee;
  cursor: pointer;
  transition: background-color 0.2s ease;
  background: #f7f7f7;
}

.notification-item:hover {
  background: #f5f5f5;
}

.notification-item.unread {
  background: #efefed;
}

.item-left {
  min-width: 0;
  display: flex;
  align-items: flex-start;
  gap: 10px;
  flex: 1;
}

.type-icon-wrap {
  width: 48px;
  height: 48px;
  border-radius: 999px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.type-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
}

.item-content {
  min-width: 0;
}

.item-title {
  margin: 0 0 2px;
  font-size: 14px;
  font-weight: 700;
  color: #444444;
}

.item-description {
  margin: 0;
  font-size: 12px;
  line-height: 1.35;
  color: #757575;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}

.item-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
  flex-shrink: 0;
}

.item-time {
  font-size: 11px;
  color: #9e9e9e;
}

.unread-dot {
  color: #1e88e5;
  font-size: 20px;
  line-height: 1;
}

.empty-state {
  margin: 0;
  padding: 20px;
  text-align: center;
  color: #9e9e9e;
  font-size: 13px;
}

.panel-footer {
  padding: 12px 16px;
  border-top: 1px solid #eeeeee;
  background: #fafafa;
}

.view-all-btn {
  width: 100%;
  height: 40px;
  border-radius: 12px;
  border: 1px solid #1e88e5;
  background: #ffffff;
  color: #1e88e5;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
}

.notif-panel-enter-active,
.notif-panel-leave-active {
  transition: opacity 200ms ease, transform 200ms ease;
}

.notif-panel-enter-from,
.notif-panel-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>
