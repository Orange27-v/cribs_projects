const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const connectDB = require('./config/db');
const conversationRoutes = require('./routes/conversations');
const messageRoutes = require('./routes/messages');
const { initializeSocket } = require('./socket/socketHandler');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST', 'PUT', 'DELETE'],
    },
});

// Middleware
app.use(cors());
app.use(express.json());

// Connect to MongoDB and start server
connectDB().then(() => {
    // Initialize Socket.IO
    initializeSocket(io);

    // Routes
    app.use('/conversations', conversationRoutes);
    app.use('/messages', messageRoutes);

    // Health check
    app.get('/', (req, res) => {
        res.json({
            status: 'ok',
            message: 'Chat API Server Running',
            timestamp: new Date().toISOString()
        });
    });

    // Start server
    const PORT = process.env.PORT || 5001;
    server.listen(PORT, () => {
        console.log(`🚀 Server running on port ${PORT}`);
        console.log(`📡 Socket.IO ready for connections`);
    });
}).catch(err => {
    console.error('❌ Failed to start server due to DB connection error:', err);
    process.exit(1);
});

module.exports = { app, server, io };
