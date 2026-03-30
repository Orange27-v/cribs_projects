const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  conversationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Conversation',
    required: true,
  },
  senderId: {
    type: String,
    required: true,
  },
  receiverId: {
    type: String,
    required: true,
  },
  text: {
    type: String,
    required: false,
    default: '',
  },
  // Message type: 'text', 'location', 'property', 'card', 'image', 'system'
  messageType: {
    type: String,
    enum: ['text', 'location', 'property', 'card', 'image', 'system'],
    default: 'text',
  },
  // Flexible data containers
  propertyData: { type: mongoose.Schema.Types.Mixed },
  locationData: { type: mongoose.Schema.Types.Mixed },
  cardData: { type: mongoose.Schema.Types.Mixed },
  payload: { type: mongoose.Schema.Types.Mixed },
  timestamp: {
    type: Date,
    default: Date.now,
  },
}, { timestamps: true });

const Message = mongoose.model('Message', messageSchema);

module.exports = Message;
