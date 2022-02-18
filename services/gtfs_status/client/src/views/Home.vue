<template>
  <div class="app-wrapper">
    <day-table v-if="raw_feeds" :feed_groups="feed_groups" @click-feed="clickFeed" />
    <div class="health-nav">
      <select v-model="bucket_name">
        <option v-for="name in bucket_names" :key="name">{{ name }}</option>
      </select>
      <div class="health-nav__date">
        <i class="fa fa-angle-double-left" @click="gotoDate(-1)" />
        {{ date }}
        <i class="fa fa-angle-double-right" @click="gotoDate(1)" />
      </div>
    </div>
  </div>
</template>

<script>
import * as df from 'date-fns'
import { sortBy } from 'lodash'

import DayTable from '@/components/DayTable.vue'
import { getDay } from '@/store/data'

const routeParam = (param_name) => ({
  get() {
    return this.$route.params[param_name]
  },
  set(value) {
    const { name, params, hash, query } = this.$route
    this.$router.replace({
      name,
      hash,
      query,
      params: { ...params, [param_name]: value },
    })
  }
})


export default {
  components: { DayTable },
  data() {
    return { bucket_names: ['gtfs-data', 'gtfs-data-test'] }
  },
  computed: {
    selected_ids() {
      const {selected_ids} = this.$route.query
      return selected_ids ? selected_ids.split(',').map(i => Number(i)) : []
    },
    raw_feeds() {
      const { bucket_name, date } = this.$route.params
      return getDay(bucket_name, date)?.feeds
    },
    feed_groups() {
      const all_feeds = sortBy(this.raw_feeds, 'itp_id')
      const top = all_feeds.filter(f => this.selected_ids.includes(f.itp_id))
      const bottom = all_feeds.filter(f => !this.selected_ids.includes(f.itp_id))
      return [top, bottom]
    },
    bucket_name: routeParam('bucket_name'),
    date: routeParam('date'),
  },
  methods: {
    clickFeed(feed) {
      let { selected_ids } = this
      if (selected_ids.includes(feed.id)) {
        selected_ids = selected_ids.filter(id => id !== feed.itp_id)
      } else {
        selected_ids.push(feed.itp_id)
      }
      const route = this.$route.path + '?selected_ids='+selected_ids.join(',')
      this.$router.push(route)
    },
    gotoDate(delta) {
      const now = df.addDays(df.parseISO(this.date), delta)
      this.date = df.format(now, 'yyyy-MM-dd')
    }
  }
}
</script>
