<template>
  <div class="app-wrapper">
    <router-view :key="$route.fullPath" />
  </div>
</template>

<script>
export default {
}
</script>
