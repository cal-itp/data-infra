import {sveltekit} from "@sveltejs/kit/vite";
import { defineConfig, loadEnv } from "vite";

export default defineConfig(({ mode }) => {
    process.env = { ...process.env, ...loadEnv(mode, process.cwd()) };

    return {
        plugins: [sveltekit()],

        css: {
            preprocessorOptions: {
                scss: {
                    additionalData: '@use "src/variables.scss" as *;',
                },
            },
        },

        server: {
            port: parseInt(process.env?.VITE_PORT ?? '') || undefined,
        }
    };
});
