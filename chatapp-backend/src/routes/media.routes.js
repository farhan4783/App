const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const { upload, uploadMedia } = require('../controllers/media.controller');

router.post('/upload', auth, upload.single('file'), uploadMedia);

module.exports = router;
