import axios from 'axios'

export const getDay = (bucket_name, day) => {
  const url = `/api/health/${bucket_name}/${day}/`
  return axios.get(url)
}
