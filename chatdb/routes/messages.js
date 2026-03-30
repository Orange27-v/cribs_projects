const express = require('express');
const router = express.Router();
const Message = require('../models/Message');

// Get messages for a conversation
router.get('/:conversationId', async (req, res) => {
    try {
        const { conversationId } = req.params;
        const messages = await Message.find({ conversationId })
            .sort({ timestamp: 1 }); // Oldest first for chat history

        res.json(messages);
    } catch (error) {
        console.error('Error fetching messages:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Delete batch messages
router.delete('/batch', async (req, res) => {
    try {
        const { messageIds } = req.body;

        if (!Array.isArray(messageIds) || messageIds.length === 0) {
            return res.status(400).json({ error: 'Invalid message IDs' });
        }

        await Message.deleteMany({ _id: { $in: messageIds } });

        res.json({ success: true });
    } catch (error) {
        console.error('Error deleting messages:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
