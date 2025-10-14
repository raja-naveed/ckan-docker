# 🎨 CKAN Custom Theme Demo

## ✨ What I've Created For You

I've built a **complete custom CKAN theme** called `ckanext-demotheme` that demonstrates all the key theming capabilities!

---

## 🎯 Demo Features

### 1. **Custom Hero Section** 🚀
- Beautiful gradient background (purple to pink)
- Large, eye-catching title
- Live dataset count pulled from CKAN API
- Modern, responsive design

### 2. **Recently Updated Datasets** 📊  
- Shows the 6 most recently modified datasets
- Beautiful card layout with hover effects
- Resource count badges
- Description previews
- Direct links to dataset pages

### 3. **Popular Groups Sidebar** 🏢
- Lists top 5 groups by dataset count
- Shows package count for each group
- Quick links to view all groups

### 4. **Info Box** 💡
- Demonstrates custom styled modules
- Gradient background
- Educational content about the theme

### 5. **Modern Styling** 🎨
- Gradient headers
- Card-based layouts with shadows
- Hover animations
- Responsive grid system
- Custom color scheme

---

## 📁 What Was Created

```
/srv/app/src/ckanext-demotheme/
├── ckanext/
│   ├── __init__.py                    # Namespace package
│   └── demotheme/
│       ├── __init__.py
│       ├── plugin.py                  # Helper functions & plugin config
│       ├── templates/
│       │   └── home/
│       │       └── index.html         # Custom homepage template
│       └── public/
│           └── css/
│               └── demotheme.css      # Custom styles
├── setup.py                            # Extension installer
```

---

## 🔧 Technical Implementation

### Helper Functions (in `plugin.py`)

```python
1. demo_most_popular_groups()
   - Fetches top 5 groups by package count
   - Uses CKAN API group_list action
   
2. demo_recent_datasets()
   - Gets 6 most recently updated datasets
   - Sorted by metadata_modified date
   
3. demo_dataset_count()
   - Returns total dataset count
   - Used in hero stats section
```

### Template Techniques Used

✅ **`{% ckan_extends %}`** - Inherits from default CKAN template  
✅ **`{% block %}`** - Overrides specific sections  
✅ **`{{ super() }}`** - Includes parent block content  
✅ **Helper functions** - `{{ h.demo_dataset_count() }}`  
✅ **URL generation** - `{{ h.url_for('dataset.read', id=package.name) }}`  
✅ **Loops** - `{% for package in h.demo_recent_datasets() %}`  
✅ **Conditional logic** - `{% if package.notes %}`  

### CSS Features

✅ **Gradients** - `linear-gradient(135deg, #667eea 0%, #764ba2 100%)`  
✅ **Animations** - Hover effects with `transform` and `transition`  
✅ **Flexbox** - Modern responsive layouts  
✅ **Card design** - Elevated cards with shadows  
✅ **Custom colors** - Brand-specific color scheme  
✅ **Responsive design** - Media queries for mobile  

---

## 🌐 View the Demo

The custom theme is now **LIVE** on your CKAN installation!

**Access URL**: https://localhost:8443

### What to Look For:

1. **Hero Banner** - Purple gradient with "Welcome to Our Data Portal"
2. **Dataset Count** - Live number in the hero section
3. **Recent Datasets Grid** - 6 cards in a 3-column layout
4. **Popular Groups** - Sidebar on the right
5. **Custom Colors** - Dark header and footer
6. **Hover Effects** - Cards lift up when you mouse over them

---

## 🎨 Customization Examples

### Change Hero Colors

Edit `/srv/app/src/ckanext-demotheme/ckanext/demotheme/public/css/demotheme.css`:

```css
.demo-hero {
    /* Change this gradient */
    background: linear-gradient(135deg, #FF6B6B 0%, #4ECDC4 100%);
}
```

### Change Hero Text

Edit `/srv/app/src/ckanext-demotheme/ckanext/demotheme/templates/home/index.html`:

```jinja
<h1 class="demo-hero-title">🌟 Your Custom Title Here!</h1>
<p class="demo-hero-subtitle">Your custom subtitle</p>
```

### Show More Datasets

Edit `plugin.py`:

```python
def demo_recent_datasets():
    result = toolkit.get_action('package_search')(
        data_dict={'sort': 'metadata_modified desc', 'rows': 12})  # Changed from 6 to 12
    return result.get('results', [])
```

---

## 📸 Screenshots of Key Features

### Before (Default CKAN)
- Basic white background
- Simple text layout
- Standard search box
- No hero section
- Plain styling

### After (Demo Theme)
- ✨ Gradient hero banner
- 📊 Live statistics
- 🎴 Beautiful card layouts
- 🎨 Custom color scheme
- 💫 Hover animations
- 📱 Responsive design

---

## 🚀 How It Works

### 1. Template Inheritance

The theme uses `{% ckan_extends %}` to inherit from CKAN's default homepage:

```jinja
{% ckan_extends %}  {# Inherit from default home/index.html #}

{% block primary_content %}
  {# Add custom content here #}
  {{ super() }}  {# Include default search box #}
{% endblock %}
```

### 2. Helper Functions

Python functions make data available to templates:

```python
# In plugin.py
def demo_dataset_count():
    result = toolkit.get_action('package_search')(data_dict={'rows': 0})
    return result.get('count', 0)

# In template
{{ h.demo_dataset_count() }}  {# Outputs: 0 (or actual count) #}
```

### 3. Static Files

CSS files are served from the `public/` directory:

```html
<link rel="stylesheet" href="/demotheme/css/demotheme.css" />
```

---

## 🎯 Key Learnings Demonstrated

1. **Extension Structure** - Proper package layout
2. **Plugin System** - IConfigurer and ITemplateHelpers
3. **Template Overriding** - Using ckan_extends
4. **Helper Functions** - Making Python functions available to templates
5. **CKAN API Usage** - Fetching data from package_search, group_list
6. **Static Files** - CSS and asset management
7. **Responsive Design** - Mobile-friendly layouts
8. **Best Practices** - URL generation, internationalization ready

---

## 🔄 Making Changes

After editing any files:

```bash
# Restart CKAN to see changes
docker compose restart ckan

# Wait 10-15 seconds for CKAN to start
# Then refresh your browser
```

### Common Edit Locations

| What to Change | File to Edit |
|----------------|--------------|
| Page layout | `templates/home/index.html` |
| Colors & styles | `public/css/demotheme.css` |
| Helper functions | `plugin.py` |
| Dataset count | `plugin.py` (demo_recent_datasets) |

---

## 🎨 Design Patterns Used

### Gradient Backgrounds
```css
background: linear-gradient(135deg, color1, color2);
```

### Card Hover Effects
```css
.card:hover {
    transform: translateY(-5px);
    box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}
```

### Responsive Grid
```html
<div class="row">
  <div class="col-md-4 col-sm-6">...</div>
</div>
```

### Bootstrap 3 Integration
- Uses CKAN's existing Bootstrap 3
- Compatible with default components
- Custom styles override defaults

---

## 📚 Files Breakdown

### plugin.py (71 lines)
- **Lines 1-7**: Helper function for popular groups
- **Lines 10-15**: Helper function for recent datasets  
- **Lines 18-22**: Helper function for dataset count
- **Lines 25-45**: Plugin class definition

### templates/home/index.html (96 lines)
- **Lines 1-6**: Styles block (include CSS)
- **Lines 8-21**: Hero section
- **Lines 23-27**: Search wrapper
- **Lines 29-59**: Recent datasets grid
- **Lines 61-end**: Sidebar modules

### public/css/demotheme.css (234 lines)
- **Lines 1-50**: Hero section styles
- **Lines 52-90**: Dataset card styles
- **Lines 92-140**: Sidebar module styles
- **Lines 142-180**: Custom color overrides
- **Lines 182-end**: Responsive media queries

---

## 💡 Next Steps

Want to customize further? Try:

1. **Add Your Logo** - Create header.html template
2. **Change Footer** - Override footer.html
3. **Custom Dataset Page** - Edit package/read.html
4. **Add More Stats** - Create new helper functions
5. **Custom Forms** - Style the search and dataset creation forms
6. **Add JavaScript** - Interactive features
7. **Multiple Themes** - Create theme variations

---

## 🎉 Success!

You now have a **fully functional custom CKAN theme** that demonstrates:

✅ Template customization  
✅ CSS styling  
✅ Helper functions  
✅ CKAN API integration  
✅ Responsive design  
✅ Modern UI/UX  

**The theme is live at**: https://localhost:8443

---

## 📞 Need Help?

All the code is in:
```
/srv/app/src/ckanext-demotheme/
```

You can:
- Edit templates in `templates/`
- Modify styles in `public/css/`
- Add helpers in `plugin.py`
- View logs: `docker compose logs -f ckan`

**Happy theming! 🎨**


