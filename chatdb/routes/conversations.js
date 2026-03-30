const express = require('express');
const router = express.Router();
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');

// Get all conversations for a user/agent
router.get('/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const conversations = await Conversation.find({
            participants: userId
        }).sort({ lastMessageTimestamp: -1 });

        // Transform data for frontend
        const formattedConversations = conversations.map(conv => {
            // Find other participant
            const otherParticipantDetails = conv.participantDetails.find(p => p.id !== userId) || {};

            return {
                id: conv._id,
                participants: conv.participants,
                last_message: {
                    message: conv.lastMessage,
                    created_at: conv.lastMessageTimestamp
                },
                unread_count: conv.unreadCounts.get(userId) || 0,
                // Assuming other participant is online? We probably don't know here without checking socket map
                // but we can pass 'false' and let socket update it.
                other_participant: {
                    id: otherParticipantDetails.id || 'unknown',
                    name: otherParticipantDetails.name || 'Unknown',
                    profile_picture_url: otherParticipantDetails.avatar || '',
                    is_online: false // This will be updated by socket events on the client side
                },
                tags: conv.tags
            };
        });

        res.json(formattedConversations);
    } catch (error) {
        console.error('Error fetching conversations:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Find or Create Conversation
router.post('/', async (req, res) => {
    try {
        const { userId, agentId, userName, userAvatar, agentName, agentAvatar, tags } = req.body;

        if (!userId || !agentId) {
            return res.status(400).json({ error: 'Missing participants' });
        }

        // Check if conversation exists
        let conversation = await Conversation.findOne({
            participants: { $all: [userId, agentId] }
        });

        if (conversation) {
            return res.json({ id: conversation._id });
        }

        // Create new
        const participantDetails = [
            { id: userId, name: userName, avatar: userAvatar },
            { id: agentId, name: agentName, avatar: agentAvatar }
        ];

        conversation = new Conversation({
            participants: [userId, agentId],
            participantDetails: participantDetails,
            unreadCounts: {
                [userId]: 0,
                [agentId]: 0
            },
            tags: tags || []
        });

        await conversation.save();
        res.status(201).json({ id: conversation._id });

    } catch (error) {
        console.error('Error creating conversation:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Mark as read
router.put('/:id/read', async (req, res) => {
    try {
        const { id } = req.params;
        const { userId } = req.body;

        if (!userId) {
            return res.status(400).json({ error: 'Missing userId' });
        }

        const conversation = await Conversation.findById(id);
        if (!conversation) {
            return res.status(404).json({ error: 'Conversation not found' });
        }

        conversation.unreadCounts.set(userId, 0);
        await conversation.save();

        res.json({ success: true });

    } catch (error) {
        console.error('Error marking as read:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Delete Conversation
router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        await Conversation.findByIdAndDelete(id);
        // Also delete messages
        await Message.deleteMany({ conversationId: id });

        res.json({ success: true });
    } catch (error) {
        console.error('Error deleting conversation:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Update participant details globally
router.put('/participant/:participantId', async (req, res) => {
    try {
        const { participantId } = req.params;
        const { name, avatar } = req.body;

        if (!name && !avatar) {
            return res.status(400).json({ error: 'Missing name or avatar for update' });
        }

        const updateData = {};
        if (name) updateData['participantDetails.$.name'] = name;
        if (avatar) updateData['participantDetails.$.avatar'] = avatar;

        const result = await Conversation.updateMany(
            { 'participantDetails.id': participantId },
            { $set: updateData }
        );

        res.json({
            success: true,
            matchedCount: result.matchedCount,
            modifiedCount: result.modifiedCount
        });
    } catch (error) {
        console.error('Error updating participant details:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
