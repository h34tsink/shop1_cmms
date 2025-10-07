// See the Tailwind CSS docs at https://tailwindcss.com/docs/configuration
// for details on customizing your config.
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/shop1_cmms_web.ex',
    '../lib/shop1_cmms_web/**/*.*ex'
  ],
  darkMode: 'class', // Enable class-based dark mode
  theme: {
    extend: {
      fontFamily: {
        sans: ['-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'Helvetica Neue', 'Arial', 'sans-serif'],
      },
      colors: {
        // Professional Business Palette
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
        sidebar: {
          DEFAULT: '#1f2937',
          hover: '#374151',
          active: '#4b5563',
          text: '#d1d5db',
        },
        toolbar: {
          DEFAULT: '#f9fafb',
          border: '#e5e7eb',
        },
      },
      spacing: {
        '0.5': '2px',
        '1.5': '6px',
        '2.5': '10px',
      },
      fontSize: {
        'xxs': '0.625rem',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms')({
      strategy: 'class',
    })
  ]
}
