const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const {
    getChats,
    createOrGetDirectChat,
    createGroupChat,
    getMessages,
} = require('../controllers/chat.controller');

router.get('/', auth, getChats);
router.post('/direct', auth, createOrGetDirectChat);
router.post('/group', auth, createGroupChat);
router.get('/:chatId/messages', auth, getMessages);

module.exports = router;
