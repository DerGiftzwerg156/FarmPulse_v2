/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{html,ts}'],
  theme: {
    extend: {
      colors: {
        'fp-bg': '#0B0F0D',
        'fp-panel': '#141A17',
        'fp-border': '#222E28',
        'fp-accent': '#38B000',
        'fp-warn': '#FF9F1C',
        'fp-text': '#E2ECE9',
        'fp-muted': '#7C9088',
      },
      fontFamily: {
        display: ['"Chakra Petch"', 'sans-serif'],
        body: ['Barlow', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
