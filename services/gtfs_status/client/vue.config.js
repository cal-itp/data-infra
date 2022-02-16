// vue.config.js
module.exports = {
    lintOnSave: false,
    devServer: {
        host: 'gtfs-client.localhost',
        proxy: 'http://localhost:4000'
    }
}
