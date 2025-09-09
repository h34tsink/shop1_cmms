// See the Tailwind CSS docs at https://tailwindcss.com/docs/configuration
// for details on customizing your config.
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/shop1_cmms_web.ex',
    '../lib/shop1_cmms_web/**/*.*ex'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms')
  ]
}
