<template>
  <div>
    <table class="table">
      <thead>
        <tr>
          <th>Key</th>
          <td>Total for day</td>
          <th v-for="hour in hours" :key="hour">{{ hour }}</th>
        </tr>
      </thead>
      <tbody>
        <template v-for="feeds, ig in feed_groups" :key="ig">
          <tr v-if="ig !== 0">
            <td colspan="25">
              <hr/>
            </td>
          </tr>
          <tr v-for="feed in feeds" :key="feed.key" :class="rowClass(ig)">
            <td @click="$emit('click-feed', feed)" class="cursor-pointer">{{ feed.key }}</td>
            <td>{{ sum(feed.counts_by_hour) }}</td>
            <td
              v-for="count, i in feed.counts_by_hour"
              :key="i"
              :class="countClass(count)"
              >
              {{ count }}
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>

<script>
import { range, sum } from 'lodash'
import config from '@/store/config'

export default {
  emits: ['click-feed'],
  props: {
    feed_groups: Object,
  },
  computed: {
    hours() {
      const { tz } = config
      return range(24).map(h => `${(h+tz)%24}:00`)
    }
  },
  methods: {
    countClass(count) {
      if (count < 180) {
        return count > 170 ? '-yellow' : '-red'
      }
    },
    rowClass(ig) {
      return ig == 0 && '-selected'
    },
    sum(numbers) {
      return sum(numbers)
    },
  }
}
</script>
