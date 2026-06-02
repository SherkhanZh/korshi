/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Brand greens (mirrors apps/client AppColors)
        primary: {
          DEFAULT: '#1E6B4F',
          dark: '#15573E',
          light: '#2E8463',
        },
        // Backgrounds / surfaces
        cream: '#F6F5F0',
        surface: '#FFFFFF',
        muted: '#F1F0EA',
        greentint: '#EDF2EC',
        // Text
        ink: '#1C1C1E',
        ink2: '#6E6E73',
        ink3: '#9A9A9F',
        line: '#E6E5DF',
        // Category accents
        cat: {
          water: '#3B9BE0',
          roads: '#4A4A4F',
          lights: '#F5B81E',
          garbage: '#3FA45F',
          safety: '#6C63C7',
          other: '#B07A4A',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
        serif: ['Georgia', 'serif'],
      },
      boxShadow: {
        card: '0 6px 16px rgba(0,0,0,0.06)',
      },
    },
  },
  plugins: [],
};
