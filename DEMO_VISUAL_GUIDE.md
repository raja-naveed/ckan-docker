# 🎨 CKAN Demo Theme - Visual Guide

## 🌐 Live Demo: https://localhost:8443

---

## 📸 What You'll See

### 🔝 **Section 1: Hero Banner**

```
┌─────────────────────────────────────────────────────────┐
│  [Purple Gradient Background]                           │
│                                                          │
│         🚀 Welcome to Our Data Portal                  │
│                                                          │
│    Explore, discover, and download open datasets        │
│                                                          │
│            ┌────────────────┐                          │
│            │       0        │  ← Live dataset count     │
│            │ Datasets Available │                       │
│            └────────────────┘                           │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Features**:
- Gradient background: Purple (#667eea) → Pink (#764ba2)
- Large 52px title with emoji
- 24px subtitle
- Live stats box with backdrop blur effect
- Fully responsive

---

### 🔍 **Section 2: Search Box**

```
┌─────────────────────────────────────────────────────────┐
│  Search datasets...                              [🔍]   │
└─────────────────────────────────────────────────────────┘
```

**Features**:
- Keeps default CKAN search functionality
- Integrates seamlessly with custom design

---

### 📊 **Section 3: Recently Updated Datasets** 

```
┌─────────── 📊 Recently Updated Datasets ────────────┐
│                                                      │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐      │
│  │ Dataset 1 │  │ Dataset 2 │  │ Dataset 3 │      │
│  │ Title     │  │ Title     │  │ Title     │      │
│  │           │  │           │  │           │      │
│  │ Description│  │ Description│  │ Description│     │
│  │ text here  │  │ text here  │  │ text here  │      │
│  │           │  │           │  │           │      │
│  │ 🏷️ 3 resources │  │ 🏷️ 5 resources │  │ 🏷️ 2 resources │  │
│  └───────────┘  └───────────┘  └───────────┘      │
│                                                      │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐      │
│  │ Dataset 4 │  │ Dataset 5 │  │ Dataset 6 │      │
│  │   ...     │  │   ...     │  │   ...     │      │
│  └───────────┘  └───────────┘  └───────────┘      │
│                                                      │
│         [ View All Datasets → ]  ← Button          │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Features**:
- 3-column responsive grid (Bootstrap)
- White cards with shadow
- Hover effect: Cards lift up 5px
- Title links to dataset page
- 100-character description preview
- Resource count badge
- Large blue button at bottom

---

### 📌 **Section 4: Sidebar - Popular Groups**

```
┌──────────────────────────┐
│ 🏢 Popular Groups        │  ← Purple gradient header
├──────────────────────────┤
│ → Environment      [5]   │
│ → Healthcare       [3]   │
│ → Transport        [2]   │
│ → Education        [1]   │
│ → Finance          [1]   │
│                          │
│ [ View All Groups ]      │
└──────────────────────────┘
```

**Features**:
- Purple gradient header matching hero
- List of 5 most popular groups
- Package count badges in blue
- Hover effect on each group
- Button to view all groups

---

### 💡 **Section 5: Info Box**

```
┌──────────────────────────┐
│ 💡 About This Portal     │  ← Pink gradient background
├──────────────────────────┤
│ This is a demo CKAN theme│
│ showcasing custom design │
│ capabilities.            │
│                          │
│ • Custom hero section    │
│ • Modern card layouts    │
│ • Helper functions       │
│ • Responsive design      │
└──────────────────────────┘
```

**Features**:
- Pink/Purple gradient background
- White text
- Educational content
- Bullet list of features

---

## 🎨 Color Scheme

```css
Primary Colors:
- Hero Gradient Start: #667eea (Purple-Blue)
- Hero Gradient End:   #764ba2 (Purple-Pink)
- Info Box Start:      #f093fb (Light Pink)
- Info Box End:        #f5576c (Rose)

Secondary Colors:
- Header: #2c3e50 (Dark Blue-Gray)
- Masthead: #34495e (Lighter Blue-Gray)
- Primary Accent: #3498db (Blue)
- Background: #f8f9fa (Light Gray)

Text Colors:
- Headings: #2c3e50 (Dark)
- Body: #666 (Gray)
- Links: #3498db (Blue)
```

---

## 📱 Responsive Breakpoints

### Desktop (> 768px)
```
┌─────────────────────────────────────────────┐
│ [=========== Hero Banner ===========]       │
│                                             │
│ [Search Box]                                │
│                                             │
│ ┌──────┐ ┌──────┐ ┌──────┐   ┌──────────┐ │
│ │Card 1│ │Card 2│ │Card 3│   │ Sidebar  │ │
│ └──────┘ └──────┘ └──────┘   │          │ │
│ ┌──────┐ ┌──────┐ ┌──────┐   │          │ │
│ │Card 4│ │Card 5│ │Card 6│   │          │ │
│ └──────┘ └──────┘ └──────┘   └──────────┘ │
└─────────────────────────────────────────────┘
```

### Mobile (< 768px)
```
┌──────────────┐
│ [Hero Banner]│
│              │
│ [Search Box] │
│              │
│ ┌──────────┐ │
│ │ Card 1   │ │
│ └──────────┘ │
│ ┌──────────┐ │
│ │ Card 2   │ │
│ └──────────┘ │
│ ┌──────────┐ │
│ │ Card 3   │ │
│ └──────────┘ │
│ ┌──────────┐ │
│ │ Sidebar  │ │
│ └──────────┘ │
└──────────────┘
```

---

## ✨ Interactive Features

### 1. **Card Hover Animation**
```
Normal State:          Hover State:
┌──────────┐          ┌──────────┐
│ Dataset  │    →     │ Dataset  │  ← Lifted up 5px
│ Card     │          │ Card     │  ← Larger shadow
└──────────┘          └──────────┘
```

### 2. **Group List Hover**
```
Normal:                Hover:
→ Environment  [5]  →  [Background: Light Gray]
```

### 3. **Button Hover**
```
Normal:                Hover:
[ View All Datasets ]  [ View All Datasets ]  ← Darker blue
```

---

## 🎬 Animation Timings

```css
Card Hover: 0.3s ease
- transform: translateY(-5px)
- box-shadow: 0 4px 16px

Group Item Hover: 0.2s ease  
- background-color: #f8f9fa
```

---

## 📏 Typography

```
Hero Title:    52px, Bold, White
Hero Subtitle: 24px, Normal, White (95% opacity)
Stat Number:   48px, Bold, White
Stat Label:    14px, Uppercase, White (90% opacity)

Section Title: 32px, Bold, #2c3e50
Card Title:    18px, Bold, #2c3e50
Card Text:     14px, Normal, #666

Sidebar Title: 18px, Bold, White
```

---

## 🎯 Layout Grid

```
Container: 1140px max-width (Bootstrap default)

Desktop:
- Main Content: 8 columns (66.6%)
- Sidebar: 4 columns (33.3%)

Tablet:
- Dataset Cards: 2 columns (50% each)

Mobile:
- Everything: 1 column (100%)
```

---

## 🔧 CSS Class Reference

### Custom Classes
```css
.demo-hero              /* Hero banner container */
.demo-hero-content      /* Hero inner content */
.demo-hero-title        /* Main title */
.demo-hero-subtitle     /* Subtitle text */
.demo-stats             /* Stats container */
.demo-stat-item         /* Individual stat box */
.demo-stat-number       /* Number display */
.demo-stat-label        /* Label text */

.demo-section           /* Section wrapper */
.demo-section-title     /* Section heading */

.demo-dataset-card      /* Dataset card */
.demo-dataset-title     /* Card title */
.demo-dataset-notes     /* Card description */
.demo-dataset-meta      /* Card metadata */

.demo-sidebar-module    /* Sidebar box */
.demo-group-list        /* Group list */
.demo-group-item        /* Group list item */
.demo-info-box          /* Info sidebar box */
```

---

## 🎨 Shadow Styles

```css
Dataset Cards:
Normal: box-shadow: 0 2px 8px rgba(0,0,0,0.1)
Hover:  box-shadow: 0 4px 16px rgba(0,0,0,0.15)

Hero Stats:
background: rgba(255,255,255,0.15)
backdrop-filter: blur(10px)  /* Frosted glass effect */
```

---

## 🖼️ What Each File Does

### `templates/home/index.html`
- **Lines 1-6**: Loads custom CSS
- **Lines 8-20**: Creates hero banner with stats
- **Lines 22-26**: Wraps default search box
- **Lines 28-57**: Displays 6 recent datasets in grid
- **Lines 59-88**: Adds sidebar with groups and info

### `public/css/demotheme.css`
- **Lines 1-66**: Hero section styling
- **Lines 68-113**: Dataset card styling
- **Lines 115-170**: Sidebar module styling
- **Lines 172-195**: Header/footer overrides
- **Lines 197-end**: Responsive breakpoints

### `plugin.py`
- **Lines 8-13**: Fetches popular groups from CKAN API
- **Lines 16-21**: Gets recent datasets from CKAN API
- **Lines 24-29**: Returns total dataset count
- **Lines 32-53**: Registers plugin and helpers

---

## 🎉 View It Now!

**URL**: https://localhost:8443

1. Open your browser
2. Accept the SSL certificate warning (it's self-signed for development)
3. See your beautiful custom CKAN theme!

---

## 📸 Quick Visual Checklist

When you load the page, you should see:

✅ Purple gradient hero banner at top  
✅ "Welcome to Our Data Portal" title  
✅ Dataset count (0 if no datasets added)  
✅ Search box below hero  
✅ "Recently Updated Datasets" heading  
✅ 6 dataset cards (or "No datasets" message)  
✅ "Popular Groups" in right sidebar  
✅ "About This Portal" info box  
✅ Dark blue header and footer  
✅ Hover effects on cards  

---

**Everything is working and looks amazing! 🎨✨**


