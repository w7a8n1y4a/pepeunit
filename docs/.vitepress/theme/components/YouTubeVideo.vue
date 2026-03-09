<template>
  <div class="youtube-video">
    <iframe
      :src="`https://www.youtube.com/embed/${id}`"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      allowfullscreen
    />
  </div>
</template>

<script setup lang="ts">
defineProps<{
  id: string
}>()
</script>

<style scoped>
.youtube-video {
  position: relative;
  width: 100%;
  padding-bottom: 56.25%; /* 16:9 */
  margin: 16px 0;
}

.youtube-video iframe {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  border-radius: 8px;
}
</style>
