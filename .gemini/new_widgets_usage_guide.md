# New Reusable Widgets - Usage Guide

## Overview
10 new reusable widgets have been added to `widgets.dart` to reduce code duplication and improve maintainability across the Cribs Arena app.

---

## 1. SectionCard

**Purpose:** Reusable card with shadow and padding for content sections

**Usage:**
```dart
SectionCard(
  child: Column(
    children: [
      Text('Content here'),
    ],
  ),
)

// With custom styling
SectionCard(
  padding: kPaddingAll16,
  margin: const EdgeInsets.only(bottom: 12),
  backgroundColor: kGrey100,
  child: YourWidget(),
)
```

**Replaces:**
```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: kWhite,
    borderRadius: kRadius12,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: YourWidget(),
)
```

---

## 2. ListItemCard

**Purpose:** Standard list item container with consistent spacing

**Usage:**
```dart
ListItemCard(
  onTap: () => print('Tapped'),
  child: Row(
    children: [
      Icon(Icons.person),
      Text('List Item'),
    ],
  ),
)

// Without tap
ListItemCard(
  padding: kPaddingAll20,
  child: YourWidget(),
)
```

**Replaces:**
```dart
Container(
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: kWhite,
    borderRadius: kRadius12,
  ),
  child: YourWidget(),
)
```

---

## 3. CircularIconButton

**Purpose:** Circular button with icon for FABs and icon buttons

**Usage:**
```dart
CircularIconButton(
  icon: Icons.my_location,
  onPressed: () => print('Pressed'),
)

// With custom styling
CircularIconButton(
  icon: Icons.add,
  onPressed: () {},
  backgroundColor: kPrimaryColor,
  iconColor: kWhite,
  iconSize: kIconSize24,
  elevation: 5,
)
```

**Replaces:**
```dart
Material(
  color: kWhite,
  shape: const CircleBorder(),
  elevation: 3,
  child: InkWell(
    customBorder: const CircleBorder(),
    onTap: onPressed,
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: Icon(icon, color: kPrimaryColor, size: 18),
    ),
  ),
)
```

---

## 4. SectionHeader

**Purpose:** Section title with consistent styling

**Usage:**
```dart
SectionHeader(
  title: 'Account Settings',
)

// With trailing widget
SectionHeader(
  title: 'Recent Activity',
  trailing: TextButton(
    onPressed: () {},
    child: Text('See All'),
  ),
)

// Custom styling
SectionHeader(
  title: 'Profile',
  padding: kPaddingH20V12,
  textStyle: GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  ),
)
```

**Replaces:**
```dart
Padding(
  padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
  child: Text(
    'SECTION TITLE',
    style: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: kGrey600,
      letterSpacing: 1.2,
    ),
  ),
)
```

---

## 5. ProfileAvatarWithBadge

**Purpose:** Avatar with edit/camera badge for profile pictures

**Usage:**
```dart
ProfileAvatarWithBadge(
  imageProvider: NetworkImage(imageUrl),
  onBadgeTap: () => pickImage(),
)

// Custom styling
ProfileAvatarWithBadge(
  imageProvider: AssetImage('assets/images/profile.jpg'),
  radius: 50,
  badgeIcon: Icons.edit,
  badgeColor: kGreen,
  onBadgeTap: () {},
)
```

**Replaces:**
```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    CircleAvatar(
      radius: 35,
      backgroundImage: NetworkImage(imageUrl),
    ),
    Positioned(
      bottom: -5,
      right: -5,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.camera_alt, color: kWhite, size: 16),
      ),
    ),
  ],
)
```

---

## 6. AvatarWithStatus

**Purpose:** Avatar with online/offline status indicator

**Usage:**
```dart
AvatarWithStatus(
  imageProvider: NetworkImage(agentImageUrl),
  isOnline: agent.isOnline,
)

// Custom size
AvatarWithStatus(
  imageProvider: NetworkImage(userImageUrl),
  isOnline: true,
  radius: 30,
  statusSize: 14,
)
```

**Replaces:**
```dart
Stack(
  children: [
    CircleAvatar(
      radius: 20,
      backgroundImage: NetworkImage(imageUrl),
    ),
    Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: isOnline ? Colors.green : Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    ),
  ],
)
```

---

## 7. CustomDivider

**Purpose:** Styled divider with spacing for separating content

**Usage:**
```dart
CustomDivider()

// Custom styling
CustomDivider(
  thickness: 2,
  color: kPrimaryColor,
  margin: const EdgeInsets.symmetric(vertical: 16),
)
```

**Replaces:**
```dart
Container(
  height: 1,
  color: kGrey300,
  margin: const EdgeInsets.symmetric(vertical: 8),
)
```

---

## 8. StatusChip

**Purpose:** Colored chip for status badges and tags

**Usage:**
```dart
StatusChip(
  label: 'Active',
)

// With icon
StatusChip(
  label: 'Verified',
  icon: Icons.check_circle,
  backgroundColor: kGreen50,
  textColor: kGreen600,
)

// Custom styling
StatusChip(
  label: 'Premium',
  backgroundColor: kPrimaryColor,
  textColor: kWhite,
  padding: kPaddingH16V8,
  borderRadius: kRadius20,
)
```

**Replaces:**
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: kPrimaryColor.withOpacity(0.1),
    borderRadius: kRadius16,
  ),
  child: Text(
    'TAG',
    style: GoogleFonts.roboto(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: kPrimaryColor,
    ),
  ),
)
```

---

## 9. SettingsListTile

**Purpose:** Consistent settings and profile menu items

**Usage:**
```dart
SettingsListTile(
  icon: Icons.person,
  title: 'Edit Profile',
  onTap: () => navigateToEditProfile(),
)

// With subtitle
SettingsListTile(
  icon: Icons.notifications,
  title: 'Notifications',
  subtitle: 'Manage your notification preferences',
  onTap: () {},
)

// Custom colors
SettingsListTile(
  icon: Icons.logout,
  title: 'Sign Out',
  iconColor: kRed,
  iconBackgroundColor: kRed50,
  onTap: () => signOut(),
)
```

**Replaces:**
```dart
ListTile(
  leading: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: kPrimaryColor.withOpacity(0.1),
      borderRadius: kRadius8,
    ),
    child: Icon(Icons.person, color: kPrimaryColor),
  ),
  title: Text('Edit Profile'),
  trailing: Icon(Icons.chevron_right),
  onTap: () {},
)
```

---

## 10. InfoRow

**Purpose:** Icon + text row for displaying information

**Usage:**
```dart
InfoRow(
  icon: Icons.location_on,
  text: 'Lagos, Nigeria',
)

// Custom styling
InfoRow(
  icon: Icons.phone,
  text: '+234 123 456 7890',
  iconColor: kPrimaryColor,
  textColor: kBlack87,
  iconSize: kIconSize20,
  spacing: 8,
)

// With custom text style
InfoRow(
  icon: Icons.email,
  text: 'user@example.com',
  textStyle: GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  ),
)
```

**Replaces:**
```dart
Row(
  children: [
    Icon(Icons.location_on, size: 16, color: kGrey),
    SizedBox(width: 5),
    Text(
      'Lagos, Nigeria',
      style: GoogleFonts.roboto(
        fontSize: 12,
        color: kBlack54,
      ),
    ),
  ],
)
```

---

## Migration Examples

### Before (profile_screen.dart):
```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: kWhite,
    borderRadius: kRadius12,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
        child: Text(
          'ACCOUNT',
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: kGrey600,
            letterSpacing: 1.2,
          ),
        ),
      ),
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.1),
            borderRadius: kRadius8,
          ),
          child: Icon(Icons.person, color: kPrimaryColor),
        ),
        title: Text('Edit Profile'),
        trailing: Icon(Icons.chevron_right),
        onTap: () {},
      ),
    ],
  ),
)
```

### After (using new widgets):
```dart
SectionCard(
  child: Column(
    children: [
      SectionHeader(title: 'Account'),
      SettingsListTile(
        icon: Icons.person,
        title: 'Edit Profile',
        onTap: () {},
      ),
    ],
  ),
)
```

**Lines saved:** 35 lines → 11 lines (68% reduction!)

---

## Best Practices

1. **Always prefer widgets over manual containers** when the pattern matches
2. **Use default values** unless customization is needed
3. **Combine widgets** for complex layouts
4. **Keep widgets focused** - don't try to make one widget do everything
5. **Document custom usage** when deviating from defaults

---

## Next Steps

Now that these widgets are created, the next phase is to:
1. Refactor existing screens to use these widgets
2. Measure code reduction
3. Test thoroughly
4. Document any issues or improvements needed

**Ready to start refactoring screens!** 🚀
