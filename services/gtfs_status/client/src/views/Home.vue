<template>
  <div class="app-wrapper">
    <day-table v-if="feeds" :feeds="feeds" />
  </div>
</template>

<script>
import DayTable from '@/components/DayTable.vue'
import { getDay } from '@/store/data'

export default {
  components: { DayTable },
  data() {
    return { feeds: null }
  },
  mounted() {
    const { bucket_name, date } = this.$route.params
    getDay(bucket_name, date).then(({ data }) => this.feeds = console.log(data) || data.feeds)
  }
}
</script>
