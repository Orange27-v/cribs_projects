# Unread Message Count Badge Implementation

## Overview
Added unread message count badges to the bottom navigation bars in both `cribs_agents` and `cribs_arena` applications. The badge displays a small red circle with the count of unread messages on the Messages/Chat tab icon.

## Changes Made

### 1. ChatService Updates (Both Apps)

#### Files Modified:
- `/Applications/XAMPP/xamppfiles/htdocs/project/cribs_agents/lib/services/chat_service.dart`
- `/Applications/XAMPP/xamppfiles/htdocs/project/cribs_arena/lib/services/chat_service.dart`

#### Changes:
- Added `_unreadCountController` StreamController to broadcast unread count updates
- Added `_emitUnreadCount()` helper method to calculate and emit total unread messages
- Added `getUnreadCountStream(String userId)` method to expose unread count stream
- Updated all conversation emission points to also emit unread count:
  - `_fetchAndEmitConversations()`
  - `_handleNewMessage()`
  - `markAsRead()`
  - `deleteConversation()`

**How it works:**
- The service maintains a local cache of conversations that includes `unread_count` for each conversation
- Whenever conversations are updated (new message, mark as read, delete, etc.), the total unread count is recalculated and emitted
- UI components can subscribe to `getUnreadCountStream()` to receive real-time updates

### 2. Bottom Navigation Bar Updates

#### cribs_agents
**File:** `/Applications/XAMPP/xamppfiles/htdocs/project/cribs_agents/lib/screens/components/bottom_navigation_bar.dart`

**Changes:**
- Added import for `ChatService`
- Wrapped Messages tab icon with `Consumer<AgentProvider>` and `StreamBuilder<int>`
- Badge listens to `ChatService().getUnreadCountStream('agent_$agentId')`
- Added `_buildIconWithBadge()` helper method to display icon with optional badge

**Agent ID Format:** `'agent_${agentId}'` where `agentId` is an integer from `AgentProvider`

#### cribs_arena
**File:** `/Applications/XAMPP/xamppfiles/htdocs/project/cribs_arena/lib/screens/components/bottom_navigation_bar.dart`

**Changes:**
- Added import for `ChatService`
- Wrapped Chat tab icon with `Consumer<UserProvider>` and `StreamBuilder<int>`
- Badge listens to `ChatService().getUnreadCountStream('user_$rawUserId')`
- Added `_buildIconWithBadge()` helper method to display icon with optional badge

**User ID Format:** `'user_${rawUserId}'` where `rawUserId` is extracted from `UserProvider`

### 3. Badge Design

The badge implementation features:
- **Position:** Top-right corner of the icon (-6px offset)
- **Color:** Red background with white text
- **Size:** Minimum 16x16px circular container
- **Font:** 8px, bold, white text
- **Display Logic:**
  - Shows only when `unreadCount > 0`
  - Displays `99+` for counts over 99
  - Updates in real-time via stream subscription

### 4. Real-time Updates

The badge count updates automatically when:
- New messages are received via WebSocket
- User/Agent marks messages as read in conversation screen
- Conversations are deleted
- App returns from background (conversation list refreshes)

## User Experience

### For Agents (cribs_agents):
- Badge appears on "Messages" tab icon when there are unread messages from users
- Count decreases when agent opens and views the conversation
- Works seamlessly with the existing chat functionality

### For Users (cribs_arena):
- Badge appears on "Chat" tab icon when there are unread messages from agents
- Count decreases when user opens and views the conversation
- Works seamlessly with the existing chat functionality

## Technical Details

### Stream Architecture:
```dart
// Subscribe to unread count stream
ChatService().getUnreadCountStream(userId)
  ↓
// Service calculates total from all conversations
_emitUnreadCount()
  ↓
// Sum up unread_count from each conversation
conversations.forEach((conv) => total += conv['unread_count'])
  ↓
// Emit to StreamController
_unreadCountController.add(totalUnread)
  ↓
// UI receives update via StreamBuilder
```

### Performance Considerations:
- Stream uses `.broadcast()` to allow multiple listeners
- Unread count is calculated from cached conversations (no extra API calls)
- Updates are only emitted when conversation data changes
- StreamBuilder in UI rebuilds only the badge widget, not entire navigation bar

## Testing Recommendations

1. **New Message Flow:**
   - Send message from User → Agent should see badge increase
   - Send message from Agent → User should see badge increase

2. **Read Receipt Flow:**
   - Open conversation → badge should decrease/disappear
   - Verify count persists across app restarts

3. **Multiple Conversations:**
   - Create multiple unread conversations
   - Verify badge shows total count from all conversations

4. **Edge Cases:**
   - Test with count > 99 (should show "99+")
   - Test with no unread messages (badge should hide)
   - Test with app in background/foreground transitions

## Future Enhancements

Potential improvements for future iterations:
- Add animation when count changes
- Different badge colors for different message types
- Sound/vibration notification when count increases
- Badge on app icon (platform-specific implementation)
