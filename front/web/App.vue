<template>
  <div class="app">
    <!-- Header with Notification Bell -->
    <header class="app-header">
      <div class="header-content">
        <h1>SUNSPACE</h1>
        <NotificationBell />
      </div>
    </header>

    <!-- Main Content -->
    <main class="app-main">
      <!-- Your page content goes here -->
    </main>
  </div>
</template>

<script setup>
import NotificationBell from './NotificationBell.vue';
</script>

<style scoped>
.app {
  width: 100%;
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-header {
  background: white;
  border-bottom: 1px solid #dcdcdc;
  padding: 0 16px;
  height: 64px;
  display: flex;
  align-items: center;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.header-content {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.app-header h1 {
  margin: 0;
  font-size: 20px;
  font-weight: 700;
  color: #1e88e5;
}

.app-main {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
}
</style>
