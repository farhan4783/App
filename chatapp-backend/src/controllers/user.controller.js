const prisma = require('../config/db');

const searchUsers = async (req, res) => {
    try {
        const { q } = req.query;
        const currentUserId = req.user.userId;

        if (!q || q.trim().length < 2) {
            return res.status(400).json({ error: 'Search query must be at least 2 characters' });
        }

        const query = q.toLowerCase().trim();

        const users = await prisma.user.findMany({
            where: {
                AND: [
                    { id: { not: currentUserId } },
                    {
                        OR: [
                            { username: { contains: query } },
                            { email: { contains: query } },
                            { displayName: { contains: query } },
                        ],
                    },
                ],
            },
            select: {
                id: true,
                username: true,
                email: true,
                displayName: true,
                photoUrl: true,
                bio: true,
                isOnline: true,
                lastSeen: true,
            },
            take: 20,
        });

        res.json({ users });
    } catch (err) {
        console.error('[searchUsers]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

const getUserById = async (req, res) => {
    try {
        const { id } = req.params;

        const user = await prisma.user.findUnique({
            where: { id },
            select: {
                id: true,
                username: true,
                email: true,
                displayName: true,
                photoUrl: true,
                bio: true,
                isOnline: true,
                lastSeen: true,
                createdAt: true,
            },
        });

        if (!user) return res.status(404).json({ error: 'User not found' });

        res.json({ user });
    } catch (err) {
        console.error('[getUserById]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

const updateProfile = async (req, res) => {
    try {
        const { displayName, bio, photoUrl, oneSignalId } = req.body;
        const userId = req.user.userId;

        const updated = await prisma.user.update({
            where: { id: userId },
            data: {
                ...(displayName && { displayName }),
                ...(bio !== undefined && { bio }),
                ...(photoUrl && { photoUrl }),
                ...(oneSignalId && { oneSignalId }),
            },
            select: {
                id: true,
                username: true,
                email: true,
                displayName: true,
                photoUrl: true,
                bio: true,
                isOnline: true,
                lastSeen: true,
            },
        });

        res.json({ user: updated });
    } catch (err) {
        console.error('[updateProfile]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

const getMe = async (req, res) => {
    try {
        const userId = req.user.userId;

        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: {
                id: true,
                username: true,
                email: true,
                displayName: true,
                photoUrl: true,
                bio: true,
                isOnline: true,
                lastSeen: true,
                createdAt: true,
            },
        });

        if (!user) return res.status(404).json({ error: 'User not found' });

        res.json({ user });
    } catch (err) {
        console.error('[getMe]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

module.exports = { searchUsers, getUserById, updateProfile, getMe };
