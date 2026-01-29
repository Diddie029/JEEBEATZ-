// routes/download.js
const express = require('express');
const router = express.Router();
const { verifyAccessToken } = require('../middleware/auth'); // verify JWT and attach req.user
const db = require('../db'); // your DB client
const AWS = require('aws-sdk');
const s3 = new AWS.S3({ region: process.env.AWS_REGION });

router.get('/purchases/:purchaseId/download', verifyAccessToken, async (req, res) => {
  const { purchaseId } = req.params;
  const userId = req.user.id;

  // verify purchase exists and belongs to user and is succeeded
  const purchase = await db.query(
    'SELECT p.*, b.audio_url FROM purchases p JOIN beats b ON b.id = p.beat_id WHERE p.id = $1',
    [purchaseId]
  );
  if (!purchase.rowCount) return res.status(404).json({ error: 'Purchase not found' });

  const p = purchase.rows[0];
  if (p.user_id !== userId) return res.status(403).json({ error: 'Not authorized' });
  if (p.status !== 'succeeded') return res.status(400).json({ error: 'Payment not completed' });

  const audioKey = p.audio_url.replace(`https://${process.env.S3_BUCKET}.s3.amazonaws.com/`, '');

  const signedUrl = s3.getSignedUrl('getObject', {
    Bucket: process.env.S3_BUCKET,
    Key: audioKey,
    Expires: 60 * 10 // 10 minutes
  });

  // record download (optional)
  await db.query(
    'INSERT INTO downloads (purchase_id, user_id, beat_id) VALUES ($1, $2, $3)',
    [purchaseId, userId, p.beat_id]
  );

  // increment download counter and earnings tracking could be done via transaction
  await db.query('UPDATE beats SET downloads_count = downloads_count + 1 WHERE id = $1', [p.beat_id]);

  res.json({ url: signedUrl });
});

module.exports = router;
