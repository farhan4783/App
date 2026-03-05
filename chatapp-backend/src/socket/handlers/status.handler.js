const prisma = require('../../config/db');

const statusHandler = (io, socket) => {
    const setOnline = async (isOnline) => {
        try {
            await prisma.user.update({
                where: { id: socket.userId },
                data: {
                    isOnline,
                    lastSeen: new Date(),
                },
            });

            // Broadcast to all rooms this user is in
            socket.rooms.forEach((room) => {
                if (room !== socket.id) {
                    socket.to(room).emit('user_status', {
                        userId: socket.userId,
                        isOnline,
                        lastSeen: new Date(),
                    });
                }
            });
        } catch (err) {
            console.error('[setOnline]', err);
        }
    };

    // User connected → set online
    setOnline(true);

    // User disconnected → set offline
    socket.on('disconnect', () => {
        setOnline(false);
    });
};

module.exports = statusHandler;
