import { createRouter, createWebHistory } from 'vue-router'

import Home from '@/views/Home.vue'

const routes = [
  {
    path: '/health/:bucket_name/:date/',
    component: Home,
  },
]

export default createRouter({
  history: createWebHistory(),
  routes,
})
