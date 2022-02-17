<template>
  <div>
    <h1>Feeds for {{ $route.params.bucket_name }} on {{ $route.params.date }}</h1>
    <table class="table">
      <thead>
        <tr>
          <th>Key</th>
          <th v-for="hour in hours" :key="hour">{{ hour }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="feed in feeds" :key="feed.key">
          <td>{{ feed.key }}</td>
          <td
            v-for="count, i in feed.counts_by_hour"
            :key="i"
            :class="countClass(count)"
            >
            {{ count }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import { range } from 'lodash'

export default {
  props: {
    feeds: Object,
  },
  computed: {
    hours() {
      return range(24).map(h => `${h}:00`)
    }
  },
  methods: {
    countClass(count) {
      if (count < 180) {
        return count > 170 ? '-yellow' : '-red'
      }
    }
  }
}
</script>
