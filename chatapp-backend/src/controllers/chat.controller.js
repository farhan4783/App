const prisma = require('../config/db');
const { v4: uuidv4 } = require('uuid');

const getChats = async (req, res) => {
    try {
        const userId = req.user.userId;

        const chatMemberships = await prisma.chatMember.findMany({
            where: { userId },
            include: {
                chat: {
                    include: {
                        members: {
                            include: {
                                user: {
                                    select: {
                                        id: true,
                                        username: true,
                                        displayName: true,
                                        photoUrl: true,
                                        isOnline: true,
                                        lastSeen: true,
                                    },
                                },
                            },
                        },
                        messages: {
                            orderBy: { sentAt: 'desc' },
                            take: 1,
                        },
                    },
                },
            },
            orderBy: {
                chat: {
                    createdAt: 'desc',
                },
            },
        });

        const chats = chatMemberships.map((m) => {
            const lastMsg = m.chat.messages[0];
            return {
                ...m.chat,
                lastMessage: lastMsg ? { ...lastMsg, seenBy: JSON.parse(lastMsg.seenBy || '[]') } : null,
                messages: undefined,
            };
        });

        res.json({ chats });
    } catch (err) {
        console.error('[getChats]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

const createOrGetDirectChat = async (req, res) => {
    try {
        const { targetUserId } = req.body;
        const userId = req.user.userId;

        if (!targetUserId) {
            return res.status(400).json({ error: 'targetUserId is required' });
        }

        if (targetUserId === userId) {
            return res.status(400).json({ error: 'Cannot create chat with yourself' });
        }

        // Check if direct chat already exists
        const existingChat = await prisma.chat.findFirst({
            where: {
                isGroup: false,
                members: {
                    every: { userId: { in: [userId, targetUserId] } },
                },
                AND: [
                    { members: { some: { userId } } },
                    { members: { some: { userId: targetUserId } } },
                ],
            },
            include: {
                members: {
                    include: {
                        user: {
                            select: {
                                id: true,
                                username: true,
                                displayName: true,
                                photoUrl: true,
                                isOnline: true,
                                lastSeen: true,
                            },
                        },
                    },
                },
                messages: {
                    orderBy: { sentAt: 'desc' },
                    take: 1,
                },
            },
        });

        if (existingChat) {
            const lastMsg = existingChat.messages[0];
            return res.json({
                chat: { 
                    ...existingChat, 
                    lastMessage: lastMsg ? { ...lastMsg, seenBy: JSON.parse(lastMsg.seenBy || '[]') } : null,
                    messages: undefined 
                },
                isNew: false,
            });
        }

        // Create new
        const chat = await prisma.chat.create({
            data: {
                id: uuidv4(),
                isGroup: false,
                members: {
                    create: [
                        { id: uuidv4(), userId, isAdmin: false },
                        { id: uuidv4(), userId: targetUserId, isAdmin: false },
                    ],
                },
            },
            include: {
                members: {
                    include: {
                        user: {
                            select: {
                                id: true,
                                username: true,
                                displayName: true,
                                photoUrl: true,
                                isOnline: true,
                                lastSeen: true,
                            },
                        },
                    },
                },
            },
        });

        res.status(201).json({ chat: { ...chat, lastMessage: null }, isNew: true });
    } catch (err) {
        console.error('[createOrGetDirectChat]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

const createGroupChat = async (req, res) => {
    try {
        const { memberIds, groupName, groupPhoto } = req.body;
        const userId = req.user.userId;

        if (!memberIds || memberIds.length < 2) {
            return res.status(400).json({ error: 'Group chat needs at least 2 other members' });
        }

        if (!groupName) {
            return res.status(400).json({ error: 'Group name is required' });
        }

        const allMembers = [...new Set([userId, ...memberIds])];

        const chat = await prisma.chat.create({
            data: {
                id: uuidv4(),
                isGroup: true,
                groupName,
                groupPhoto: groupPhoto || null,
                members: {
                    create: allMembers.map((uid) => ({
                        id: uuidv4(),
                        userId: uid,
                        isAdmin: uid === userId,
                    })),
                },
            },
            include: {
                members: {
                    include: {
                        user: {
                            select: {
                                id: true,
                                username: true,
                                displayName: true,
                                photoUrl: true,
                                isOnline: true,
                                lastSeen: true,
                            },
                        },
                    },
                },
            },
        });

        res.status(201).json({ chat: { ...chat, lastMessage: null } });
    } catch (err) {
        console.error('[createGroupChat]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

const getMessages = async (req, res) => {
    try {
        const { chatId } = req.params;
        const { cursor, limit = 50 } = req.query;
        const userId = req.user.userId;

        // Verify member access
        const membership = await prisma.chatMember.findUnique({
            where: { userId_chatId: { userId, chatId } },
        });

        if (!membership) {
            return res.status(403).json({ error: 'Not a member of this chat' });
        }

        const messages = await prisma.message.findMany({
            where: {
                chatId,
                ...(cursor && { sentAt: { lt: new Date(cursor) } }),
            },
            include: {
                sender: {
                    select: { id: true, username: true, displayName: true, photoUrl: true },
                },
            },
            orderBy: { sentAt: 'desc' },
            take: parseInt(limit),
        });

        const mappedMessages = messages.map(msg => ({
            ...msg,
            seenBy: JSON.parse(msg.seenBy || '[]')
        }));

        res.json({ messages: mappedMessages.reverse(), hasMore: mappedMessages.length === parseInt(limit) });
    } catch (err) {
        console.error('[getMessages]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

module.exports = { getChats, createOrGetDirectChat, createGroupChat, getMessages };
