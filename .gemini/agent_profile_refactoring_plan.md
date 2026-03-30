# Agent Profile Bottom Sheet - Refactoring Plan

## File: agent_profile_bottom_sheet.dart
**Current Size:** 1,234 lines, 37KB  
**Priority:** 🔴 HIGH (Phase 1 - Largest file in agents directory)

---

## 🔍 Refactoring Opportunities Identified

### 1. Hardcoded EdgeInsets (20+ instances)
- Line 308: `const EdgeInsets.symmetric(horizontal: kSizedBoxW20, vertical: kSizedBoxH10)`
- Line 394: `const EdgeInsets.all(20)` → `kPaddingAll20`
- Line 561: `const EdgeInsets.symmetric(vertical: 8)` → `kPaddingV8`
- Line 585: `const EdgeInsets.symmetric(vertical: 8)` → `kPaddingV8`
- Line 694: `const EdgeInsets.symmetric(vertical: 12)` → `kPaddingV12`
- Line 734: `const EdgeInsets.all(8)` → `kPaddingAll8`
- Line 775: `const EdgeInsets.all(20)` → `kPaddingAll20`
- Line 1031: `const EdgeInsets.all(16)` → `kPaddingAll16`
- Line 1149: `const EdgeInsets.symmetric(horizontal: 16, vertical: 10)` → `kPaddingH16V10`
- Line 1178: `EdgeInsets.all(20.0)` → `kPaddingAll20`
- Line 1187: `const EdgeInsets.all(20.0)` → `kPaddingAll20`
- Line 1208: `EdgeInsets.all(20.0)` → `kPaddingAll20`
- Line 1221: `const EdgeInsets.symmetric(vertical: 8)` → `kPaddingV8`

**Estimated Reduction:** 0 lines (same code, better maintainability)

---

### 2. Profile Image with Status (Lines 419-464)
**Current:** Custom Stack with CircleAvatar + online indicator (45 lines)  
**Can Use:** `AvatarWithStatus` widget

**Before:**
```dart
class _ProfileImage extends StatelessWidget {
  final String? profilePic;
  final bool isOnline;
  // ... 45 lines of code
}
```

**After:**
```dart
AvatarWithStatus(
  imageProvider: NetworkImage(profilePic ?? kDefaultProfileImage),
  isOnline: isOnline,
  radius: 35,
  statusSize: 15,
)
```

**Estimated Reduction:** ~40 lines

---

### 3. Location Info Row (Lines 500-513)
**Current:** Custom Row with Icon + Text (14 lines)  
**Can Use:** `InfoRow` widget

**Before:**
```dart
Row(
  children: [
    const Icon(Icons.location_on, color: kPrimaryColor, size: kIconSize16),
    const SizedBox(width: kSizedBoxW6),
    Flexible(
      child: Text(
        agent.area ?? 'Location not specified',
        style: const TextStyle(color: kPrimaryColor, fontSize: kFontSize10),
      ),
    ),
  ],
)
```

**After:**
```dart
InfoRow(
  icon: Icons.location_on,
  text: agent.area ?? 'Location not specified',
  iconColor: kPrimaryColor,
  textColor: kPrimaryColor,
  iconSize: kIconSize16,
  spacing: kSizedBoxW6,
)
```

**Estimated Reduction:** ~8 lines

---

### 4. Info Container (Lines 768-785)
**Current:** Custom Container with padding and border (17 lines)  
**Can Use:** `SectionCard` widget (with customization)

**Estimated Reduction:** ~5 lines

---

### 5. Section Title (Lines 646-680)
**Current:** Custom Row with Text + TextButton (34 lines)  
**Can Use:** `SectionHeader` widget (with trailing button)

**Estimated Reduction:** ~10 lines

---

## 📊 Estimated Impact

| Change | Lines Reduced | Complexity |
|--------|---------------|------------|
| Hardcoded EdgeInsets | 0 | Low |
| AvatarWithStatus | ~40 | Medium |
| InfoRow | ~8 | Low |
| SectionCard | ~5 | Low |
| SectionHeader | ~10 | Low |
| **TOTAL** | **~63 lines** | **Medium** |

**Expected Result:** 1,234 → ~1,171 lines (5% reduction)

---

## 🎯 Refactoring Strategy

### Phase 1: Quick Wins (Low Risk)
1. ✅ Replace all hardcoded EdgeInsets with constants
2. ✅ Add widgets.dart import

### Phase 2: Widget Replacements (Medium Risk)
3. ✅ Replace _ProfileImage with AvatarWithStatus
4. ✅ Replace location Row with InfoRow
5. ✅ Replace _InfoContainer with SectionCard

### Phase 3: Complex Replacements (Higher Risk)
6. ⚠️ Consider replacing _SectionTitle with SectionHeader (may need customization)
7. ⚠️ Review other repeated patterns

---

## ⚠️ Considerations

### Keep As-Is:
- `_InfoChip` - Specific to this screen's design
- `_Stat` - Custom layout for stats display
- `_ActionButtons` - Complex button group with specific logic
- ViewModel pattern - Well-structured, don't change

### Why This File is Large:
1. **ViewModel** (265 lines) - Business logic, should stay
2. **Multiple custom widgets** - Specific to agent profile
3. **Complex UI** - Profile header, stats, reviews, properties
4. **Good structure** - Already well-organized

### Realistic Expectation:
- **Target reduction:** 50-80 lines (4-6%)
- **Main benefit:** Better maintainability, not just line count
- **Focus:** Use reusable widgets where they fit naturally

---

**Status:** Ready to refactor - Starting with Phase 1
