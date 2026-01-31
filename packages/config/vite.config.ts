import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  envDir: '../..',  // Read .env from monorepo root
  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'SurfingkeysConfig',
      formats: ['iife'],
      fileName: () => 'bundle.js'
    },
    outDir: 'dist',
    emptyOutDir: true,
    minify: 'terser',
    rollupOptions: {
      output: {
        // Single file bundle
        inlineDynamicImports: true
      }
    }
  }
});
