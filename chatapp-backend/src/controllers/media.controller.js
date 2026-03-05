const cloudinary = require('../config/cloudinary');
const multer = require('multer');

const storage = multer.memoryStorage();
const upload = multer({
    storage,
    limits: { fileSize: 25 * 1024 * 1024 }, // 25MB
});

const uploadMedia = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file provided' });
        }

        const fileType = req.file.mimetype.startsWith('image/') ? 'image' : 'raw';

        // Convert buffer to base64 for cloudinary upload
        const b64 = Buffer.from(req.file.buffer).toString('base64');
        const dataURI = `data:${req.file.mimetype};base64,${b64}`;

        const result = await cloudinary.uploader.upload(dataURI, {
            resource_type: fileType === 'image' ? 'image' : 'raw',
            folder: 'chatapp',
        });

        res.json({
            url: result.secure_url,
            publicId: result.public_id,
            type: fileType,
            fileName: req.file.originalname,
        });
    } catch (err) {
        console.error('[uploadMedia]', err);
        res.status(500).json({ error: 'Upload failed' });
    }
};

module.exports = { upload, uploadMedia };
