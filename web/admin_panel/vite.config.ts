import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5174,
    // In dev, proxy /api to the deployed backend so features like cover
    // upload work without running the server locally.
    proxy: {
      '/api': {
        target: process.env.VITE_API_TARGET || 'http://188.244.115.167',
        changeOrigin: true,
      },
    },
  },
});
