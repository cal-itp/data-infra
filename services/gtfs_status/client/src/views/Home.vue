<template>
  <div class="app-wrapper">
    <day-table v-if="raw_feeds" :feed_groups="feed_groups" @click-feed="clickFeed" />
  </div>
</template>

<script>
import { sortBy } from 'lodash'

import DayTable from '@/components/DayTable.vue'
import { getDay } from '@/store/data'

export default {
  components: { DayTable },
  data() {
    return { raw_feeds: null }
  },
  computed: {
    selected_ids() {
      const {selected_ids} = this.$route.query
      return selected_ids ? selected_ids.split(',').map(i => Number(i)) : []
    },
    feed_groups() {
      const all_feeds = sortBy(this.raw_feeds, 'itp_id')
      const top = all_feeds.filter(f => this.selected_ids.includes(f.id))
      const bottom = all_feeds.filter(f => !this.selected_ids.includes(f.id))
      return [top, bottom]
    }
  },
  mounted() {
    const { bucket_name, date } = this.$route.params
    getDay(bucket_name, date).then(({ data }) => this.raw_feeds = data.feeds)
  },
  methods: {
    clickFeed(feed) {
      let { selected_ids } = this
      if (selected_ids.includes(feed.id)) {
        selected_ids = selected_ids.filter(id => id !== feed.id)
      } else {
        selected_ids.push(feed.id)
      }
      const route = this.$route.path + '?selected_ids='+selected_ids.join(',')
      this.$router.push(route)

    }
  }
}
</script>
