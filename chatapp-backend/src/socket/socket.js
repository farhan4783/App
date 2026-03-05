const jwt = require('jsonwebtoken');
const prisma = require('../config/db');
const messageHandler = require('./handlers/message.handler');
const typingHandler = require('./handlers/typing.handler');
const statusHandler = require('./handlers/status.handler');

const initSocket = (io) => {
    // Auth middleware for socket connections
    io.use(async (socket, next) => {
        try {
            const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.split(' ')[1];
            if (!token) return next(new Error('Authentication required'));

            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            const user = await prisma.user.findUnique({
                where: { id: decoded.userId },
                select: { id: true, displayName: true, username: true },
            });

            if (!user) return next(new Error('User not found'));

            socket.userId = user.id;
            socket.displayName = user.displayName;
            socket.username = user.username;
            next();
        } catch (err) {
            next(new Error('Invalid token'));
        }
    });

    io.on('connection', async (socket) => {
        console.log(`✅ User connected: ${socket.displayName} (${socket.userId})`);

        // Automatically join all the user's chat rooms
        socket.on('join_chats', async ({ chatIds }) => {
            if (!chatIds || !Array.isArray(chatIds)) return;
            chatIds.forEach((chatId) => {
                socket.join(chatId);
                console.log(`   ${socket.displayName} joined room: ${chatId}`);
            });
        });

        // Attach all event handlers
        messageHandler(io, socket);
        typingHandler(io, socket);
        statusHandler(io, socket);

        socket.on('disconnect', () => {
            console.log(`❌ User disconnected: ${socket.displayName} (${socket.userId})`);
        });
    });
};

module.exports = initSocket;
