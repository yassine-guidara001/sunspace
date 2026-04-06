<template>
  <div class="notification-container">
    <!-- Notification Bell Icon -->
    <div class="notification-bell" @click="togglePanel">
      <svg
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        class="bell-icon"
      >
        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
        <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
      </svg>
      <span v-if="unreadCount > 0" class="unread-badge">{{ unreadCount }}</span>
    </div>

    <!-- Notification Panel -->
    <NotificationPanel
      :open="panelOpen"
      :notifications="notifications"
      @update:open="panelOpen = $event"
      @mark-read="markAsRead"
      @mark-all-read="markAllAsRead"
      @open-all="openAllNotifications"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import NotificationPanel from './NotificationPanel.vue';

const panelOpen = ref(false);
const notifications = ref([]);
const unreadCount = ref(0);
let refreshInterval = null;

const togglePanel = () => {
  panelOpen.value = !panelOpen.value;
};

const getAuthHeader = () => {
  const token = localStorage.getItem('token');
  if (!token) return {};
  return { 'Authorization': `Bearer ${token}` };
};

const fetchNotifications = async () => {
  try {
    const response = await fetch('/api/notifications?skip=0&take=50', {
      headers: getAuthHeader(),
    });

    if (!response.ok) {
      console.error('Failed to fetch notifications:', response.status);
      return;
    }

    const data = await response.json();
    notifications.value = data?.items || data || [];
    unreadCount.value = data?.total_unread || notifications.value.filter(n => !n.read).length;
  } catch (error) {
    console.error('Error fetching notifications:', error);
  }
};

const markAsRead = async (notification) => {
  try {
    const response = await fetch(`/api/notifications/${notification.id}/read`, {
      method: 'PATCH',
      headers: {
        ...getAuthHeader(),
        'Content-Type': 'application/json',
      },
    });

    if (response.ok) {
      await fetchNotifications();
    }
  } catch (error) {
    console.error('Error marking notification as read:', error);
  }
};

const markAllAsRead = async () => {
  try {
    const response = await fetch('/api/notifications/read-all', {
      method: 'PATCH',
      headers: {
        ...getAuthHeader(),
        'Content-Type': 'application/json',
      },
    });

    if (response.ok) {
      await fetchNotifications();
    }
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
  }
};

const openAllNotifications = () => {
  panelOpen.value = false;
  // Navigate to full notifications page (adjust route as needed)
  window.location.href = '/notifications';
};

onMounted(() => {
  fetchNotifications();
  refreshInterval = setInterval(fetchNotifications, 10000); // Refresh every 10 seconds
});

onUnmounted(() => {
  if (refreshInterval) {
    clearInterval(refreshInterval);
  }
});
</script>

<style scoped>
.notification-container {
  position: relative;
  display: inline-block;
}

.notification-bell {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background-color 0.2s ease;
  border-radius: 50%;
  color: #303030;
  position: relative;
}

.notification-bell:hover {
  background-color: #f5f5f5;
}

.bell-icon {
  width: 24px;
  height: 24px;
}

.unread-badge {
  position: absolute;
  top: 0;
  right: 0;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #d32f2f;
  color: white;
  font-size: 11px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid white;
}
</style>
