# User Markers Not Visible - Debug Guide

## Debug Logging Added

I've added comprehensive debug logging to track the complete flow of marker display. When you run the app and click "Find Nearby Clients", look for these logs in order:

### Expected Log Sequence:

1. **MAP_HOME: Found X users**
   - From `map_home_screen.dart`
   - Shows how many users were fetched from the backend
   
2. **MAP_SCREEN: _refreshAgents called with X agents**
   - From `map_screen.dart`
   - Confirms the agents were passed to the map screen
   
3. **USER_MARKER: setUsers called with X users**
   - From `user_marker.dart`
   - Confirms the marker widget received the users
   
4. **MAP_SCREEN: Scheduling marker display**
   - From `map_screen.dart`
   - Markers display scheduled with 300ms delay
   
5. **MAP_SCREEN: Markers set to visible, calling setVisibility(true)**
   - After 300ms delay
   - Setting markers to visible state
   
6. **USER_MARKER: Visibility changed to true**
   - Marker widget visibility toggled
   
7. **MAP_SCREEN: Calling updatePositions on UserMarker**
   - After centering on location
   - Calculating screen positions
   
8. **USER_MARKER: Positions updated. Total: X, Positioned: true, Visible: true**
   - Positions calculated successfully
   
9. **USER_MARKER: build() - positioned: true, visible: true, mounted: true, users: X, positions: X**
   - Build called with correct state
   
10. **USER_MARKER: Rendering X markers**
    - Markers are being rendered!

## Common Issues to Check:

### Issue 1: No users fetched
**Symptoms:** "MAP_HOME: Found 0 users"
**Cause:** Backend returned no users within radius
**Solutions:**
- Check backend default radius (currently 10km)
- Verify users exist in database with valid lat/long
- Try increasing radius in `map_service.dart`

### Issue 2: Users not passed to map
**Symptoms:** Log 1 shows users, but log 2 shows 0
**Cause:** Data not reaching map screen
**Check:** `map_home_screen.dart` line 181-186

### Issue 3: Positioning never happens
**Symptoms:** Logs stop after visibility change
**Cause:** `updatePositions()` not being called
**Check:**
- Map controller initialized?
- Camera movement completed?
- `_scheduleInitialPositioning()` called?

### Issue 4: Positions calculated but not visible
**Symptoms:** "Positioned: true" but no markers on screen
**Cause:** Could be z-index or opacity issue
**Check:**
- `AnimatedOpacity` opacity value
- Widget tree stacking order
- Map overlaying markers

## Quick Test Commands:

```bash
# Watch logs in real-time
flutter logs --device-id emulator-5554 2>&1 | grep -E "(MAP_HOME|MAP_SCREEN|USER_MARKER)"

# Check backend radius
grep "radius.*??" backend/app/Http/Controllers/Agent/AgentMapController.php

# Count users with coordinates
# (Run this in MySQL/phpMyAdmin)
SELECT COUNT(*) FROM cribs_users 
WHERE latitude IS NOT NULL 
AND longitude IS NOT NULL 
AND latitude != '' 
AND longitude != '';
```

## Backend Configuration

Current backend settings:
- Default radius: **10km** (was 50km)
- Haversine formula: ✅ Fixed
- Input validation: ✅ Latitude (-90 to 90), Longitude (-180 to 180)
- Image URLs: ✅ Full URLs returned

## What to Share with Me:

1. The complete log sequence showing where it stops
2. Number of users the backend returns
3. Whether markers appear after hot restart
4. Any error messages
5. Screenshot of the map screen

This will help me identify exactly where the flow is breaking!
