const prisma = require('../../config/db');
const { v4: uuidv4 } = require('uuid');

const messageHandler = (io, socket) => {
    // Send a new message
    socket.on('send_message', async (data) => {
        try {
            const { chatId, text, type = 'TEXT', mediaUrl, fileName } = data;
            const senderId = socket.userId;

            if (!chatId || (!text && !mediaUrl)) return;

            // Verify sender is member
            const membership = await prisma.chatMember.findUnique({
                where: { userId_chatId: { userId: senderId, chatId } },
            });

            if (!membership) {
                socket.emit('error', { message: 'Not a member of this chat' });
                return;
            }

            // Save message
            const message = await prisma.message.create({
                data: {
                    id: uuidv4(),
                    chatId,
                    senderId,
                    text: text || null,
                    type,
                    mediaUrl: mediaUrl || null,
                    fileName: fileName || null,
                    status: 'SENT',
                },
                include: {
                    sender: {
                        select: { id: true, username: true, displayName: true, photoUrl: true },
                    },
                },
            });

            // Broadcast to all members in the chat room
            io.to(chatId).emit('new_message', message);

            // Update status to DELIVERED for online members (excluding sender)
            const roomSockets = await io.in(chatId).fetchSockets();
            const onlineUserIds = roomSockets
                .map((s) => s.userId)
                .filter((id) => id && id !== senderId);

            if (onlineUserIds.length > 0) {
                await prisma.message.update({
                    where: { id: message.id },
                    data: { status: 'DELIVERED' },
                });
                io.to(chatId).emit('message_status', {
                    messageId: message.id,
                    status: 'DELIVERED',
                });
            }
        } catch (err) {
            console.error('[send_message]', err);
            socket.emit('error', { message: 'Failed to send message' });
        }
    });

    // Mark message as read
    socket.on('message_read', async (data) => {
        try {
            const { chatId, messageId } = data;
            const userId = socket.userId;

            const message = await prisma.message.findUnique({ where: { id: messageId } });
            if (!message || message.senderId === userId) return;

            if (!message.seenBy.includes(userId)) {
                const updated = await prisma.message.update({
                    where: { id: messageId },
                    data: {
                        seenBy: { push: userId },
                        status: 'READ',
                    },
                });

                // Notify the chat about read status
                io.to(chatId).emit('message_status', {
                    messageId,
                    status: 'READ',
                    seenBy: updated.seenBy,
                });
            }
        } catch (err) {
            console.error('[message_read]', err);
        }
    });
};

module.exports = messageHandler;
