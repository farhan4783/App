const typingHandler = (io, socket) => {
    socket.on('typing_start', ({ chatId }) => {
        if (!chatId) return;
        socket.to(chatId).emit('user_typing', {
            chatId,
            userId: socket.userId,
            displayName: socket.displayName,
        });
    });

    socket.on('typing_stop', ({ chatId }) => {
        if (!chatId) return;
        socket.to(chatId).emit('user_stop_typing', {
            chatId,
            userId: socket.userId,
        });
    });
};

module.exports = typingHandler;
