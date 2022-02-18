import axios from 'axios'
import { reactive } from 'vue'

const state = reactive({})
const _loading = {}

export const getDay = (bucket_name, day) => {
  const url = `/api/health/${bucket_name}/${day}/`
  if (!state[url] && !_loading[url]) {
    _loading[url] = true
    axios.get(url)
      .then(({data}) => state[url] = data)
      .catch(() => {
        state[url] = { error: "An unknown error occurred" }
      })
  }
  return state[url]
}
