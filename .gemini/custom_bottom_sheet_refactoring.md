# Custom Bottom Sheet Refactoring

## Overview
Created a reusable `CustomBottomSheet` widget in `widgets.dart` that provides consistent styling across all bottom sheets in the app, following the design pattern from `signup_screen.dart`.

## New Widget: CustomBottomSheet

### Location
`/Applications/XAMPP/xamppfiles/htdocs/project/cribs_arena/lib/widgets/widgets.dart`

### Features
- ✅ **Consistent Styling**: Rounded top corners (20px radius)
- ✅ **Drag Handle**: Optional horizontal bar at the top for visual feedback
- ✅ **Draggable**: Uses `DraggableScrollableSheet` for smooth UX
- ✅ **Customizable Sizes**: Configurable initial, max, and min sizes
- ✅ **Clean Design**: White background with proper padding (24px)
- ✅ **Scrollable Content**: Automatically handles overflow

### Usage

#### Basic Usage
```dart
await CustomBottomSheet.show(
  context: context,
  child: YourContentWidget(),
);
```

#### Advanced Usage
```dart
await CustomBottomSheet.show<String>(
  context: context,
  child: YourContentWidget(),
  initialChildSize: 0.6,  // 60% of screen height
  maxChildSize: 0.9,      // Can expand to 90%
  minChildSize: 0.3,      // Can shrink to 30%
  showDragHandle: true,   // Show the drag indicator
  isDismissible: true,    // Can dismiss by tapping outside
  enableDrag: true,       // Can drag to resize/dismiss
);
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `context` | `BuildContext` | required | Build context |
| `child` | `Widget` | required | Content to display |
| `initialChildSize` | `double` | `0.6` | Initial height (0.0 - 1.0) |
| `maxChildSize` | `double` | `0.9` | Maximum height (0.0 - 1.0) |
| `minChildSize` | `double` | `0.3` | Minimum height (0.0 - 1.0) |
| `expand` | `bool` | `false` | Whether to expand to fill available space |
| `showDragHandle` | `bool` | `true` | Show drag handle at top |
| `isDismissible` | `bool` | `true` | Can dismiss by tapping outside |
| `enableDrag` | `bool` | `true` | Enable drag gestures |

## Design Specifications

### Visual Elements
1. **Border Radius**: 20px on top-left and top-right corners
2. **Background Color**: White (`kWhite`)
3. **Padding**: 24px all around (`kPaddingAll24`)
4. **Drag Handle**: 
   - Width: 40px
   - Height: 5px
   - Color: Grey 300 (`kGrey.shade300`)
   - Border Radius: 10px (`kRadius10`)
   - Bottom Margin: 20px

### Layout Structure
```
┌─────────────────────────────┐
│     ═══ (Drag Handle)       │  ← Optional
│                             │
│                             │
│     Your Content Here       │
│                             │
│                             │
└─────────────────────────────┘
```

## Bottom Sheets Found in Project

The following files contain bottom sheet implementations that can be refactored:

1. ✅ **signup_screen.dart** - Already using the pattern (reference implementation)
2. **profile_screen.dart** (Line 197) - Image picker options
3. **map_home_screen.dart** (Line 239) - Map-related bottom sheet
4. **my_feed_screen.dart** (Line 633) - Feed-related actions
5. **agent_card.dart** (Line 122) - Agent actions
6. **agent_profile_bottom_sheet.dart** (Line 906) - Nested bottom sheet
7. **searchbar.dart** (Line 88) - Search filters
8. **search_screen.dart** (Line 264) - Filter bottom sheet
9. **chat_list_screen.dart** (Line 514) - Tag management
10. **schedule_card.dart** (Lines 309, 661, 734, 846) - Multiple schedule actions

## Next Steps

To refactor existing bottom sheets:

1. **Import the widget** (if not already imported):
   ```dart
   import 'package:cribs_arena/widgets/widgets.dart';
   ```

2. **Replace `showModalBottomSheet` with `CustomBottomSheet.show`**:
   
   **Before:**
   ```dart
   showModalBottomSheet(
     context: context,
     builder: (context) {
       return Container(
         child: YourContent(),
       );
     },
   );
   ```

   **After:**
   ```dart
   CustomBottomSheet.show(
     context: context,
     child: YourContent(),
   );
   ```

3. **Remove custom styling** from content widgets (padding, decoration, etc.) as it's handled by `CustomBottomSheet`

## Benefits

- 🎨 **Consistent Design**: All bottom sheets look and feel the same
- 🔧 **Easy Maintenance**: Update styling in one place
- 📱 **Better UX**: Draggable sheets with proper sizing
- 🚀 **Less Code**: Reduce boilerplate in each implementation
- ♿ **Accessibility**: Consistent interaction patterns

## Example Refactoring

### Before (profile_screen.dart)
```dart
showModalBottomSheet(
  context: context,
  builder: (context) {
    return SafeArea(
      child: Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Photo Library'),
            onTap: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Camera'),
            onTap: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  },
);
```

### After (with CustomBottomSheet)
```dart
CustomBottomSheet.show(
  context: context,
  initialChildSize: 0.3,
  maxChildSize: 0.4,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: const Icon(Icons.photo_library),
        title: const Text('Photo Library'),
        onTap: () {
          Navigator.of(context).pop();
          _pickImage(ImageSource.gallery);
        },
      ),
      ListTile(
        leading: const Icon(Icons.photo_camera),
        title: const Text('Camera'),
        onTap: () {
          Navigator.of(context).pop();
          _pickImage(ImageSource.camera);
        },
      ),
    ],
  ),
);
```

## Notes

- The widget automatically handles scrolling for content that exceeds the available space
- The drag handle provides visual feedback that the sheet is draggable
- All sizing parameters use fractions (0.0 to 1.0) of the screen height
- The widget is fully typed and supports generic return types
