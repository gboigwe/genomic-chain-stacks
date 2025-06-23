/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'genomic-teal': '#2DD4BF',
        'genomic-blue': '#5594E0',
        'genomic-dark': '#121F40',
        'genomic-cyan': '#20A7BD',
        'genomic-bg': '#0F192D',
      },
      animation: {
        'dna-spin': 'spin 20s linear infinite',
        'float': 'float 6s ease-in-out infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' },
        }
      }
    },
  },
  plugins: [],
}
