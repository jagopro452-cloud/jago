# 🎨 JAGO Design System - Complete Guide for Designers

**Date:** March 24, 2026  
**Status:** Senior Designer Breakdown - Honest & Step-by-Step

---

## 1️⃣ SIZE SYSTEM (Width & Height)

### The SIZE_MAP Pattern - How Sizing Works

```typescript
// File: client/src/components/Logo.tsx

const SIZE_MAP: Record<LogoSize, number> = {
  xs: 16,    // Extra Small - icons, badges
  sm: 24,    // Small - secondary elements
  md: 36,    // Medium - default for most
  lg: 42,    // Large - featured elements
  xl: 56,    // Extra Large - hero sections
  xxl: 84,   // 2X Large - poster/banner
};
```

**How it's used:**
```tsx
// Instead of: width="100px" height="100px" style={{...}}
// Do this:
<Logo size="md" />        // 36px height, auto width
<Logo size="lg" />        // 42px height
<Logo size="xl" />        // 56px height (featured)

// For custom sizes:
<Logo height={48} />      // Override SIZE_MAP, use custom
```

---

## 2️⃣ BORDER-RADIUS SYSTEM (Rounded Corners)

### CSS Border-Radius Values Used

From index.css analysis:

| Radius | Use Case | Example |
|--------|----------|---------|
| **4px** | Scrollbar thumb (micro) | `.aside-body::-webkit-scrollbar-thumb` |
| **8px** | Buttons, cards, inputs | `.aside-nav`, `.aside-section` |
| **10px** | Medium buttons | `.aside-nav-item` icon buttons |
| **16px** | Large cards, modals | Logo card container |
| **50%** | Perfect circles | Avatars, user icons |

**Pattern:**
```css
/* Small radius - subtle rounding */
.button { border-radius: 8px; }

/* Medium radius - noticeable separation */
.card { border-radius: 10px; }

/* Large radius - soft containers */
.modal { border-radius: 16px; }

/* Perfect circle - avatars */
.avatar { 
  width: 28px;
  height: 28px;
  border-radius: 50%;
}
```

---

## 3️⃣ WIDTH & HEIGHT PATTERNS

### Element Sizing Strategy

**Fixed Dimensions:**
```css
/* Icons & small elements */
.icon { width: 36px; height: 36px; }
.avatar { width: 26px; height: 26px; }

/* Navigation/sidebar */
.aside { width: 220px; height: 100%; }
.nav-item { height: 56px; }
```

**Auto Dimensions:**
```css
/* Responsive layouts */
.container { width: 100%; }

/* Images maintain aspect ratio */
img { 
  width: auto;
  height: 42px;
  aspect-ratio: 16 / 9;
  object-fit: contain;
}
```

---

## 4️⃣ DESIGN CLASSES IN CODE

### CSS Classes Used

**From client/src/index.css:**

```css
/* Navigation Classes */
.aside-nav-group
.aside-nav-item
.aside-toggle-btn
  ├─ width: 36px
  ├─ height: 36px
  └─ border-radius: 10px

/* Logo Classes */
.jl-logo-img
.jl-logo-img-card
  ├─ background: white
  ├─ border-radius: 16px
  ├─ padding: 12px 24px
  └─ box-shadow: 0 8px 32px rgba(0,0,0,0.25)

/* Avatar Classes */
.user-avatar
  ├─ width: 28px
  ├─ height: 28px
  └─ border-radius: 50% (circle)

/* Section Classes */
.aside-section
.aside-body
  ├─ border-radius: 8px
  └─ transitional elements
```

---

## 5️⃣ HONEST STEP-BY-STEP WORKFLOW

### How to Design Properly (Senior Designer Way)

### Step 1: Define the Element Type
```
Question: What are you designing?
├─ Icon → use size: 'xs' or 'sm'
├─ Card → use size: 'md' or 'lg'
└─ Hero → use size: 'xl' or 'xxl'
```

### Step 2: Choose Size from SIZE_MAP
```
Decision Tree:
├─ Small visual (16px) → size: 'xs'
├─ Navigation item (24px) → size: 'sm'
├─ Default element (36px) → size: 'md' ✅ START HERE
├─ Featured element (42px) → size: 'lg'
├─ Prominent feature (56px) → size: 'xl'
└─ Large banner (84px) → size: 'xxl'
```

### Step 3: Select Border-Radius
```
Hierarchy:
├─ Micro (4px) → Subtle borders, scrollbars
├─ Small (8px) → Buttons, cards, sections ✅ DEFAULT
├─ Medium (10px) → Icon buttons, inputs
├─ Large (16px) → Large containers, modals
└─ Full (50%) → Circular avatars ONLY
```

### Step 4: Decide Width Behavior
```
Choose:
├─ Fixed width? 
│  └─ Define exact pixel: width: 220px
├─ Responsive (full)?
│  └─ width: 100%
└─ Auto (based on content)?
   └─ width: auto (with images)
```

### Step 5: Apply the Design
```typescript
// GOOD ✅
<Logo 
  size="lg"           // From SIZE_MAP
  style={{
    borderRadius: 10, // Valid value
    width: "auto",    // Responsive
  }}
/>

// BAD ❌ (Don't do this)
<div style={{
  width: "145px",     // Random number
  height: "48px",     // Specific instead of size prop
  borderRadius: "12px" // Not in standard values
}}>
```

---

## 6️⃣ CSS CLASS MAPPING

### Where Classes Are Used

```
Component Tree:
┌─ App
│  ├─ Navigation
│  │  └─ .aside
│  │     ├─ width: 220px
│  │     └─ .aside-nav-item
│  │        ├─ height: 56px
│  │        └─ border-radius: 8px
│  │
│  ├─ Layout
│  │  └─ .aside-body
│  │     ├─ border-radius: 8px
│  │     └─ transition: width 200ms
│  │
│  └─ Components
│     ├─ Logo
│     │  └─ .jl-logo-img
│     │     ├─ height: {SIZE_MAP[size]}
│     │     ├─ width: auto
│     │     └─ object-fit: contain
│     │
│     └─ Avatar
│        └─ .user-avatar
│           ├─ width: 28px
│           ├─ height: 28px
│           └─ border-radius: 50%
```

---

## 7️⃣ SIZING PHILOSOPHY

### Why This System Works

**Consistency:**
- Everyone uses same SIZE_MAP values
- No "random 47px" elements
- Predictable scaling

**Flexibility:**
- Can override with `height` prop
- Can use custom `style` object
- Still respects design language

**Maintainability:**
- Change SIZE_MAP once → updates everywhere
- Easy to add new sizes
- Framework-agnostic

---

## 8️⃣ REAL CODE EXAMPLES

### Example 1: Navigation Item

```tsx
// How it's built:
<div className="aside-nav-item">      // Class from CSS
  <button 
    className="aside-toggle-btn"       // 36x36, radius 10px
    style={{
      width: 36,        // From .aside-nav-item CSS
      height: 36,
      borderRadius: 10,
      ...otherStyles
    }}
  >
    {icon}
  </button>
</div>

// CSS defines:
// .aside-nav-item { width: 36px; height: 36px; border-radius: 10px; }
```

### Example 2: Logo with Card

```tsx
<Logo 
  size="lg"              // 42px height
  cardHeight={64}        // Wraps in container with 64px height
  withBg={true}          // Background: white
  style={{
    borderRadius: 16,    // Large card radius
    boxShadow: "0 8px 32px rgba(0,0,0,0.25)"
  }}
/>

// Renders:
// <div class="jl-logo-img-card" style="...">
//   <img height="42px" width="auto" />
// </div>
```

### Example 3: Avatar (Circle)

```tsx
// In component:
<img 
  className="user-avatar"
  style={{
    width: 28,
    height: 28,
    borderRadius: "50%"   // Perfect circle
  }}
/>

// CSS class:
// .user-avatar { width: 28px; height: 28px; border-radius: 50%; }
```

---

## 9️⃣ DESIGN TOKENS (Quick Reference)

### Copy-Paste Values

**Sizes:**
```
xs: 16,    sm: 24,    md: 36,    lg: 42,    xl: 56,    xxl: 84
```

**Border-Radius:**
```
4px (micro), 8px (default), 10px (medium), 16px (large), 50% (circle)
```

**Widths:**
```
Fixed: 220px (nav), 26px-36px (icons)
Auto: 100% (responsive), auto (content-based)
```

**Heights:**
```
56px (nav items), 28px-36px (icons), 100% (full)
```

---

## 🔟 CHECKLIST FOR DESIGNS

Before adding new element:

- [ ] Is this size in SIZE_MAP? Use it.
- [ ] custom size? Use `height` prop instead of width
- [ ] What border-radius? Choose from: 4px, 8px, 10px, 16px, or 50%
- [ ] Responsive or fixed? Use width: 100% or width: {number}px
- [ ] Does similar element exist? Copy its class pattern
- [ ] Added to CSS class? Define in index.css or component style
- [ ] Works on mobile? Test 320px width

---

## ✅ SENIOR DESIGNER SIGN-OFF

This design system ensures:

✅ **Consistency** - Same values everywhere  
✅ **Scalability** - Easy to update globally  
✅ **Maintainability** - Clean, predictable patterns  
✅ **Flexibility** - Override when needed  
✅ **Performance** - Fixed sizes = better layout calculations  

**Use this honestly, step-by-step, and your designs will be perfect!** 🎨

---

**File Location:** Open this as: `DESIGN_SYSTEM.md`
