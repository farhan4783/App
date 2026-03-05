const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const prisma = require('../config/db');

const generateTokens = (userId) => {
    const accessToken = jwt.sign({ userId }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    });
    const refreshToken = jwt.sign({ userId }, process.env.JWT_REFRESH_SECRET, {
        expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
    });
    return { accessToken, refreshToken };
};

const register = async (req, res) => {
    try {
        const { username, email, password, displayName } = req.body;

        if (!username || !email || !password || !displayName) {
            return res.status(400).json({ error: 'All fields are required' });
        }

        // Check uniqueness
        const existingUser = await prisma.user.findFirst({
            where: { OR: [{ email }, { username }] },
        });

        if (existingUser) {
            const field = existingUser.email === email ? 'email' : 'username';
            return res.status(409).json({ error: `This ${field} is already taken` });
        }

        const passwordHash = await bcrypt.hash(password, 12);

        const user = await prisma.user.create({
            data: {
                id: uuidv4(),
                username: username.toLowerCase().trim(),
                email: email.toLowerCase().trim(),
                displayName,
                passwordHash,
            },
        });

        const { accessToken, refreshToken } = generateTokens(user.id);

        res.status(201).json({
            accessToken,
            refreshToken,
            user: {
                id: user.id,
                username: user.username,
                email: user.email,
                displayName: user.displayName,
                photoUrl: user.photoUrl,
                bio: user.bio,
                isOnline: user.isOnline,
                lastSeen: user.lastSeen,
                createdAt: user.createdAt,
            },
        });
    } catch (err) {
        console.error('[register]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        const user = await prisma.user.findUnique({
            where: { email: email.toLowerCase().trim() },
        });

        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const validPassword = await bcrypt.compare(password, user.passwordHash);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const { accessToken, refreshToken } = generateTokens(user.id);

        res.json({
            accessToken,
            refreshToken,
            user: {
                id: user.id,
                username: user.username,
                email: user.email,
                displayName: user.displayName,
                photoUrl: user.photoUrl,
                bio: user.bio,
                isOnline: user.isOnline,
                lastSeen: user.lastSeen,
                createdAt: user.createdAt,
            },
        });
    } catch (err) {
        console.error('[login]', err);
        res.status(500).json({ error: 'Server error' });
    }
};

const refresh = async (req, res) => {
    try {
        const { refreshToken } = req.body;
        if (!refreshToken) {
            return res.status(401).json({ error: 'Refresh token required' });
        }

        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        const { accessToken, refreshToken: newRefresh } = generateTokens(decoded.userId);

        res.json({ accessToken, refreshToken: newRefresh });
    } catch (err) {
        return res.status(401).json({ error: 'Invalid refresh token' });
    }
};

module.exports = { register, login, refresh };
