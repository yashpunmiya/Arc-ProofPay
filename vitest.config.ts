import { defineConfig } from "vitest/config";
export default defineConfig({test:{environment:"jsdom",include:["**/*.test.ts"],pool:"threads",maxWorkers:1,minWorkers:1}});
