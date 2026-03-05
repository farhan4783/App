const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const { searchUsers, getUserById, updateProfile, getMe } = require('../controllers/user.controller');

router.get('/me', auth, getMe);
router.get('/search', auth, searchUsers);
router.get('/:id', auth, getUserById);
router.patch('/me', auth, updateProfile);

module.exports = router;
