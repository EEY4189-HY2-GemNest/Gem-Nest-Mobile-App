/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,jsx}",
    ],
    theme: {
        extend: {
            colors: {
                primary: '#D4AF37',
                dark: '#1a1a1a',
            }
        },
    },
    plugins: [],
}
