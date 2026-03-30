const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema({
  participants: [{
    type: String, // Can be user or agent IDs
  }],
  lastMessage: {
    type: String,
    default: '',
  },
  lastMessageTimestamp: {
    type: Date,
    default: Date.now,
  },
  // You can add other fields here, like participant details if you choose to denormalize
  participantDetails: [{
    _id: false,
    id: String,
    name: String,
    avatar: String,
  }],
  unreadCounts: {
    type: Map,
    of: Number,
    default: {},
  },
  tags: {
    type: [String],
    default: [],
  },
}, { timestamps: true });

const Conversation = mongoose.model('Conversation', conversationSchema);

module.exports = Conversation;
