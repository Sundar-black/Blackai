const app = require('./app');
const fetch = (...args) => import('node-fetch').then(({ default: fetch }) => fetch(...args));

const PORT = process.env.PORT || 5000;

const server = app.listen(PORT, () => {
    console.log(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);

    // Self-ping to keep server alive (Heroku/Render)
    const keepAlive = async () => {
        const url = process.env.RENDER_EXTERNAL_URL || process.env.SERVER_URL;
        if (url) {
            try {
                const res = await fetch(`${url}/health`);
                console.log(`Keep-alive ping: ${res.status}`);
            } catch (err) {
                console.log(`Keep-alive error: ${err.message}`);
            }
        }
    };

    // Ping every 10 minutes
    setInterval(keepAlive, 600000);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err, promise) => {
    console.error(`Error: ${err.message}`);
    // Close server & exit process
    server.close(() => process.exit(1));
});
