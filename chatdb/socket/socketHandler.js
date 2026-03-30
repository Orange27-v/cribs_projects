const axios = require('axios');
const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
require('dotenv').config();

const onlineUsers = new Map();

function initializeSocket(io) {
    io.on('connection', (socket) => {
        console.log(`🔌 Client connected: ${socket.id}`);

        // Register user
        socket.on('register', (userId) => {
            if (!userId) return;
            socket.userId = userId;
            onlineUsers.set(userId, socket.id);
            console.log(`✅ User registered: ${userId}`);

            // Broadcast online status
            io.emit('user_online_status', { userId, isOnline: true });
        });

        // Handle send message
        socket.on('send_message', async (rawData) => {
            try {
                // Parse JSON string if the client sent the entire message as JSON
                let data = rawData;
                if (typeof rawData === 'string') {
                    try {
                        data = JSON.parse(rawData);
                        console.log('📦 Parsed JSON message from client');
                    } catch (e) {
                        console.error('❌ Failed to parse message JSON:', e.message);
                        socket.emit('message_error', { error: 'Invalid JSON message format' });
                        return;
                    }
                }

                const {
                    conversationId, fromId, toId, text,
                    messageType, propertyData, locationData, cardData, payload
                } = data;

                console.log(`📨 Incoming message - From: ${fromId}, To: ${toId}, ConvID: ${conversationId}, Type: ${messageType || 'text'}`);

                if (!conversationId || !fromId || !toId) {
                    console.error('❌ Invalid message data: Missing IDs');
                    socket.emit('message_error', { error: 'Missing required conversation or participant IDs' });
                    return;
                }

                // Create message base object
                const messageData = {
                    conversationId,
                    senderId: fromId,
                    receiverId: toId,
                    text: text || '',
                    messageType: messageType || 'text',
                    timestamp: new Date(),
                };

                // Helper to sanitize and parse data that might come as strings
                const processIncomingData = (inputData) => {
                    if (!inputData) return null;
                    let parsed = inputData;

                    // If it's a string, try to parse it as JSON
                    if (typeof inputData === 'string') {
                        try {
                            // First attempt: standard JSON
                            parsed = JSON.parse(inputData);
                        } catch (e) {
                            try {
                                // Second attempt: handle single quotes (common in Dart's toString())
                                // This is a naive attempt but works for simple property maps
                                const fixJson = inputData
                                    .replace(/'/g, '"')
                                    .replace(/(\w+):/g, '"$1":');
                                parsed = JSON.parse(fixJson);
                                console.log('🩹 Patched single-quoted string to JSON');
                            } catch (e2) {
                                console.warn('⚠️ Could not parse data string into object, saving as raw string');
                                parsed = inputData;
                            }
                        }
                    }

                    // Remove undefined values if it's an object
                    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
                        const clean = { ...parsed };
                        Object.keys(clean).forEach(key => {
                            if (clean[key] === undefined) delete clean[key];
                        });
                        return clean;
                    }
                    return parsed;
                };

                // Populate flexible data containers
                if (propertyData) {
                    messageData.propertyData = processIncomingData(propertyData);
                    // Special handling for property backward compatibility
                    if (messageData.propertyData && typeof messageData.propertyData === 'object') {
                        if (!messageData.propertyData.image && messageData.propertyData.images?.length > 0) {
                            messageData.propertyData.image = messageData.propertyData.images[0];
                        }
                    }
                }
                if (locationData) messageData.locationData = processIncomingData(locationData);
                if (cardData) messageData.cardData = processIncomingData(cardData);
                if (payload) messageData.payload = processIncomingData(payload);

                const message = new Message(messageData);
                await message.save();
                console.log(`✅ Message saved: ${message._id}`);

                // Update conversation
                const conversation = await Conversation.findById(conversationId);
                let senderName = 'Someone';

                // Determine display text for the conversation list
                let lastMessageText = text || '';
                if (messageType === 'property') {
                    lastMessageText = `🏠 Property: ${messageData.propertyData?.title || 'Shared'}`;
                } else if (messageType === 'location') {
                    lastMessageText = '📍 Shared a location';
                } else if (!text && (cardData || payload)) {
                    lastMessageText = '📦 Shared an item';
                }

                if (conversation) {
                    conversation.lastMessage = lastMessageText;
                    conversation.lastMessageTimestamp = message.timestamp;

                    const currentUnread = conversation.unreadCounts.get(toId) || 0;
                    conversation.unreadCounts.set(toId, currentUnread + 1);

                    const senderDetails = conversation.participantDetails.find(p => p.id === fromId);
                    if (senderDetails) senderName = senderDetails.name;

                    await conversation.save();
                    console.log(`📝 Conversation updated: ${conversationId}`);
                }

                // Prepare broadcast packet
                const broadcastData = {
                    ...message.toObject(),
                    id: message._id.toString(),
                    senderId: fromId,
                    receiverId: toId,
                    timestamp: message.timestamp.toISOString(),
                };

                // Send to sender (acknowledgment)
                socket.emit('message_sent', broadcastData);
                console.log(`✉️ Acknowledgment sent to sender: ${fromId}`);

                // Send to receiver if online
                const receiverSocketId = onlineUsers.get(toId);
                if (receiverSocketId) {
                    io.to(receiverSocketId).emit('new_message', broadcastData);
                    console.log(`📬 Message delivered to receiver: ${toId} (socket: ${receiverSocketId})`);
                }

                // ALWAYS trigger push notification via Laravel (handles foreground/background/offline)
                console.log(`🔔 Triggering push notification for ${toId}`);
                sendPushNotification(toId, senderName, lastMessageText, conversationId);

                // Broadcast to all clients for conversation list update
                const senderSocketId = onlineUsers.get(fromId);
                if (senderSocketId && senderSocketId !== socket.id) {
                    io.to(senderSocketId).emit('conversation_updated', { conversationId });
                }
                if (receiverSocketId) {
                    io.to(receiverSocketId).emit('conversation_updated', { conversationId });
                }

            } catch (error) {
                console.error('❌ Error sending message:', error);
                socket.emit('message_error', { error: error.message });
            }
        });

        // Handle disconnect
        socket.on('disconnect', () => {
            if (socket.userId) {
                onlineUsers.delete(socket.userId);
                io.emit('user_online_status', { userId: socket.userId, isOnline: false });
                console.log(`👋 User disconnected: ${socket.userId}`);
            }
            console.log(`🔌 Client disconnected: ${socket.id}`);
        });
    });
}

// Function to send push notification via Laravel
async function sendPushNotification(receiverId, senderName, messageText, conversationId) {
    try {
        const url = process.env.LARAVEL_NOTIFICATION_API_URL;
        const apiKey = process.env.LARAVEL_API_KEY;

        if (!url || !apiKey) {
            console.warn('⚠️ Laravel notification config missing.');
            return;
        }

        // Determine receiver type and raw ID
        let receiverType = 'agent';
        let rawReceiverId = receiverId;

        if (receiverId.toString().startsWith('user_')) {
            receiverType = 'user';
            rawReceiverId = receiverId.replace('user_', '');
        }

        // The PHP controller validation:
        // 'receiver_id' => 'required',
        // 'receiver_type' => 'required|in:user,agent',
        // 'sender_name' => 'required|string',
        // 'message' => 'required|string',
        // 'conversation_id' => 'required|string',

        const payload = {
            receiver_id: rawReceiverId,
            receiver_type: receiverType,
            sender_name: senderName,
            message: messageText,
            conversation_id: conversationId
        };

        if (receiverType === 'agent') {
            // For agents, our logic might differ or we might need to handle prefixes better.
            // Assuming agents don't have 'agent_' prefix in the DB ID passed here, 
            // or the PHP side handles it. 
            // Based on frontend 'agent.id', it's usually just an int/string.
        }

        await axios.post(url, payload, {
            headers: {
                'Content-Type': 'application/json',
                'X-API-Key': apiKey
            }
        });

        console.log(`🔔 Notification sent to ${receiverType} ${rawReceiverId}`);

    } catch (error) {
        console.error('❌ Failed to trigger notification:', error.message);
        if (error.response) {
            console.error('Response data:', error.response.data);
        }
    }
}

module.exports = { initializeSocket };
