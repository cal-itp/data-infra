import { reactive } from 'vue'
import ls from 'local-storage-json'

const LS_KEY = 'APP_CONFIG'
const initial = ls.get(LS_KEY)

const store = reactive({
  tz: 0,
  ...initial,
})

export default {
  get tz() {
    return store.tz
  },
  set tz(value) {
    store.tz = value
    ls.set(LS_KEY, store)
  },
}
