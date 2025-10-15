# 🎨 CKAN Theming & Customization Guide

A comprehensive guide to customizing your CKAN installation based on the official [CKAN Theming Documentation](https://docs.ckan.org/en/2.9/theming/).

---

## 📚 Table of Contents

1. [Overview](#overview)
2. [Creating a CKAN Extension](#creating-a-ckan-extension)
3. [Customizing Templates](#customizing-templates)
4. [Adding Static Files](#adding-static-files)
5. [Customizing CSS](#customizing-css)
6. [Customizing JavaScript](#customizing-javascript)
7. [Template Helper Functions](#template-helper-functions)
8. [Best Practices](#best-practices)
9. [Complete Example](#complete-example)

---

## Overview

CKAN theming is achieved by creating a **CKAN extension** that contains:
- Custom **Jinja2 templates** to override default pages
- **CSS files** to customize styling
- **JavaScript files** for custom functionality
- **Static assets** (images, fonts, etc.)

### Key Technologies Used:
- **Jinja2** - Template engine
- **Bootstrap 3** - CSS framework (as of CKAN 2.8+)
- **jQuery** - JavaScript library
- **Webassets** - Asset management

> **Note**: Your CKAN 2.10.5 uses Bootstrap 3 by default.

---

## Creating a CKAN Extension

### Step 1: Generate Extension

From inside the CKAN container:

```bash
# Enter the CKAN container
docker compose exec ckan bash

# Activate virtual environment (already active in container)
cd /srv/app

# Generate extension
ckan generate extension --name ckanext-mytheme
```

### Step 2: Basic Plugin Structure

Create `plugin.py`:

```python
# encoding: utf-8
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit


class MyThemePlugin(plugins.SingletonPlugin):
    '''A custom CKAN theme plugin.'''
    
    # Implement IConfigurer to register templates and assets
    plugins.implements(plugins.IConfigurer)
    
    def update_config(self, config):
        # Add template directory
        toolkit.add_template_directory(config, 'templates')
        
        # Add public directory for static files
        toolkit.add_public_directory(config, 'public')
        
        # Add resource directory for CSS/JS
        toolkit.add_resource('assets', 'mytheme')
```

### Step 3: Directory Structure

```
ckanext-mytheme/
├── ckanext/
│   └── mytheme/
│       ├── __init__.py
│       ├── plugin.py
│       ├── templates/          # Jinja2 templates
│       │   ├── home/
│       │   │   └── index.html
│       │   ├── header.html
│       │   └── footer.html
│       ├── public/             # Static files
│       │   ├── images/
│       │   │   └── logo.png
│       │   └── fonts/
│       └── assets/             # CSS/JS managed by Webassets
│           ├── css/
│           │   └── mytheme.css
│           └── js/
│               └── mytheme.js
├── setup.py
└── README.md
```

### Step 4: Install and Enable

```bash
# Inside container
cd /srv/app/src/ckanext-mytheme
pip install -e .

# On host - edit .env file
# Add to CKAN__PLUGINS:
CKAN__PLUGINS="... mytheme"

# Restart CKAN
docker compose restart ckan
```

---

## Customizing Templates

### Understanding Template Inheritance

CKAN uses **Jinja2 template inheritance** with a special tag `{% ckan_extends %}`:

```jinja
{# templates/home/index.html #}
{% ckan_extends %}

{% block primary_content %}
  <h1>Welcome to My Custom CKAN!</h1>
  <p>This overrides the default home page content.</p>
{% endblock %}
```

### Finding Templates to Override

1. **Enable Debug Mode**: Set `debug = true` in your CKAN config
2. **Check Footer**: Debug toolbar shows which templates are used
3. **Core Templates Location**: `/srv/app/src/ckan/ckan/templates/`

### Common Templates to Customize

| Template | Page | Purpose |
|----------|------|---------|
| `home/index.html` | `/` | Homepage |
| `header.html` | All pages | Site header/navigation |
| `footer.html` | All pages | Site footer |
| `package/search.html` | `/dataset` | Dataset search page |
| `package/read.html` | `/dataset/{id}` | Dataset detail page |
| `organization/index.html` | `/organization` | Organizations list |
| `group/index.html` | `/group` | Groups list |
| `user/login.html` | `/user/login` | Login page |

### Template Blocks Reference

According to the [CKAN template documentation](https://docs.ckan.org/en/2.9/theming/templates.html), common blocks include:

```jinja
{% block page %}
  {% block skip %}{% endblock %}
  
  {% block header %}
    {% block header_account %}{% endblock %}
    {% block header_site_navigation %}{% endblock %}
  {% endblock %}
  
  {% block content %}
    {% block toolbar %}{% endblock %}
    {% block primary_content %}{% endblock %}
    {% block secondary_content %}{% endblock %}
  {% endblock %}
  
  {% block footer %}{% endblock %}
{% endblock %}
```

### Example: Custom Homepage

```jinja
{# templates/home/index.html #}
{% ckan_extends %}

{% block primary_content %}
  <div class="hero">
    <h1>{{ _('Welcome to Our Snap4IDTCity Data Portal') }}</h1>
    <p>{{ _('Discover and explore open datasets') }}</p>
  </div>
  
  {# Keep the default search box #}
  {{ super() }}
{% endblock %}

{% block secondary_content %}
  <div class="module">
    <div class="module-content">
      <h2>{{ _('Featured Datasets') }}</h2>
      {% snippet 'snippets/package_list.html', packages=h.recently_changed_packages_activity_list() %}
    </div>
  </div>
{% endblock %}
```

### Using `{{ super() }}`

Include parent block content:

```jinja
{% block primary_content %}
  <div class="custom-banner">Custom content here</div>
  {{ super() }}  {# Include original content #}
{% endblock %}
```

---

## Adding Static Files

### Step 1: Create Public Directory

```bash
mkdir -p ckanext-mytheme/ckanext/mytheme/public/images
mkdir -p ckanext-mytheme/ckanext/mytheme/public/css
```

### Step 2: Register in Plugin

```python
def update_config(self, config):
    toolkit.add_public_directory(config, 'public')
```

### Step 3: Reference in Templates

```jinja
{# Direct URL #}
<img src="/mytheme/images/logo.png" alt="Logo">

{# Or use url_for #}
<img src="{{ h.url_for_static('/mytheme/images/logo.png') }}" alt="Logo">
```

---

## Customizing CSS

### Method 1: Simple CSS Override

**Create**: `public/css/mytheme.css`

```css
/* Override CKAN default styles */
.account-masthead {
    background-color: #2c3e50;
}

.masthead {
    background-color: #34495e;
}

.site-footer {
    background-color: #2c3e50;
}

/* Custom styles */
.hero {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 60px 20px;
    text-align: center;
    color: white;
    margin-bottom: 30px;
}

.hero h1 {
    font-size: 48px;
    margin-bottom: 20px;
}
```

**Include in template**:

```jinja
{% block styles %}
  {{ super() }}
  <link rel="stylesheet" href="/mytheme/css/mytheme.css" />
{% endblock %}
```

### Method 2: Using Webassets (Recommended)

**Create**: `assets/css/mytheme.css`

**Register in plugin.py**:

```python
def update_config(self, config):
    toolkit.add_resource('assets', 'mytheme')
```

**Include in template**:

```jinja
{% block styles %}
  {{ super() }}
  {% asset 'mytheme/mytheme.css' %}
{% endblock %}
```

### Bootstrap 3 Customization

CKAN uses Bootstrap 3. You can override Bootstrap variables:

```css
/* Custom Bootstrap theme */
:root {
    --primary-color: #3498db;
    --secondary-color: #2ecc71;
}

.btn-primary {
    background-color: var(--primary-color);
    border-color: var(--primary-color);
}

.btn-primary:hover {
    background-color: #2980b9;
}
```

---

## Customizing JavaScript

### Creating a JavaScript Module

**Create**: `assets/js/mytheme.js`

```javascript
/* CKAN JavaScript module pattern */
this.ckan.module('mytheme-custom', function ($) {
  return {
    initialize: function () {
      console.log('My theme initialized!');
      
      // Access options passed from template
      console.log('Config:', this.options);
      
      // Bind events
      this.el.on('click', '.custom-button', this._onClick.bind(this));
    },
    
    _onClick: function(event) {
      event.preventDefault();
      alert('Custom button clicked!');
    }
  };
});
```

**Include in template**:

```jinja
{% block scripts %}
  {{ super() }}
  {% asset 'mytheme/mytheme.js' %}
{% endblock %}

{# Activate module on element #}
<div data-module="mytheme-custom" data-module-config='{"key": "value"}'>
  <button class="custom-button">Click Me</button>
</div>
```

---

## Template Helper Functions

Helper functions make data and utilities available to templates.

### Creating Helper Functions

**In plugin.py**:

```python
from ckan.plugins import toolkit

def get_featured_datasets(limit=5):
    '''Get most recently updated datasets.'''
    context = {'ignore_auth': True}
    data_dict = {
        'sort': 'metadata_modified desc',
        'rows': limit
    }
    result = toolkit.get_action('package_search')(context, data_dict)
    return result['results']

def get_total_datasets():
    '''Get total number of datasets.'''
    context = {'ignore_auth': True}
    result = toolkit.get_action('package_search')(context, {'rows': 0})
    return result['count']


class MyThemePlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)
    plugins.implements(plugins.ITemplateHelpers)
    
    def update_config(self, config):
        toolkit.add_template_directory(config, 'templates')
    
    def get_helpers(self):
        '''Register helper functions.'''
        return {
            'mytheme_featured_datasets': get_featured_datasets,
            'mytheme_total_datasets': get_total_datasets,
        }
```

**Using in templates**:

```jinja
<div class="stats">
  <h3>{{ h.mytheme_total_datasets() }} datasets available</h3>
</div>

<div class="featured">
  {% for package in h.mytheme_featured_datasets(limit=3) %}
    <div class="dataset-item">
      <h4>{{ package.title }}</h4>
      <p>{{ h.markdown_extract(package.notes, 150) }}</p>
    </div>
  {% endfor %}
</div>
```

### Built-in Helper Functions

CKAN provides many helpers (access via `h.*`):

- `h.url_for()` - Generate URLs
- `h.markdown_extract()` - Extract markdown text
- `h.datetime_to_date_str()` - Format dates
- `h.humanize_entity_type()` - Humanize entity names
- `h.SI_number_span()` - Format large numbers

Full reference: [Template Helper Functions](https://docs.ckan.org/en/2.9/theming/template-helper-functions.html)

---

## Best Practices

Based on [CKAN Best Practices](https://docs.ckan.org/en/2.9/theming/best-practices.html):

### 1. Don't Use `c` (Template Context)

❌ **Wrong:**
```jinja
{{ c.user }}
```

✅ **Correct:**
```jinja
{{ g.user }}
{# or pass explicitly from controller #}
```

### 2. Always Use `url_for()`

❌ **Wrong:**
```jinja
<a href="/dataset">Datasets</a>
```

✅ **Correct:**
```jinja
<a href="{{ h.url_for('dataset.search') }}">Datasets</a>
```

### 3. Internationalize Strings

❌ **Wrong:**
```jinja
<h1>Welcome</h1>
```

✅ **Correct:**
```jinja
<h1>{{ _('Welcome') }}</h1>

{# For pluralization #}
{{ ungettext(
    '{num} dataset',
    '{num} datasets',
    count
).format(num=count) }}
```

### 4. Avoid Name Clashes

Prefix your helpers and CSS classes:

```python
# Good: mytheme_get_featured
# Bad: get_featured

return {
    'mytheme_get_featured': get_featured,
}
```

```css
/* Good */
.mytheme-hero { }

/* Bad */
.hero { }
```

### 5. Use `{% snippet %}` Not `{% include %}`

❌ **Wrong:**
```jinja
{% include 'snippets/social_links.html' %}
```

✅ **Correct:**
```jinja
{% snippet 'snippets/social_links.html', param1='value' %}
```

### 6. Document Your Snippets

```jinja
{#
Display social media links.

param1 - Description of param1
param2 - Description of param2

Example:
  {% snippet 'snippets/social_links.html', site_name='MyOrg' %}
#}
<div class="social-links">
  ...
</div>
```

---

## Complete Example

Let's create a complete custom theme:

### 1. Generate Extension

```bash
docker compose exec ckan bash
ckan generate extension --name ckanext-portaltheme
cd /srv/app/src/ckanext-portaltheme
```

### 2. Create `plugin.py`

```python
# encoding: utf-8
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit


def most_popular_tags(limit=10):
    '''Return most used tags.'''
    context = {'ignore_auth': True}
    data_dict = {'all_fields': True}
    tags = toolkit.get_action('tag_list')(context, data_dict)
    # Sort by package_count if available
    return sorted(tags, key=lambda x: x.get('package_count', 0), reverse=True)[:limit]


class PortalThemePlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)
    plugins.implements(plugins.ITemplateHelpers)
    
    def update_config(self, config):
        toolkit.add_template_directory(config, 'templates')
        toolkit.add_public_directory(config, 'public')
        toolkit.add_resource('assets', 'portaltheme')
    
    def get_helpers(self):
        return {
            'portaltheme_most_popular_tags': most_popular_tags,
        }
```

### 3. Create Custom Homepage

**File**: `templates/home/index.html`

```jinja
{% ckan_extends %}

{% block styles %}
  {{ super() }}
  {% asset 'portaltheme/style.css' %}
{% endblock %}

{% block primary_content %}
  <div class="hero-banner">
    <div class="container">
      <h1>{{ _('Welcome to Our Snap4IDTCity Data Portal') }}</h1>
      <p class="lead">{{ _('Explore, download, and share open data') }}</p>
    </div>
  </div>
  
  <div class="container">
    <div class="row">
      <div class="col-md-8">
        {{ super() }}
      </div>
      <div class="col-md-4">
        <div class="module">
          <div class="module-heading">
            <h3>{{ _('Popular Tags') }}</h3>
          </div>
          <div class="module-content">
            <ul class="tag-list">
              {% for tag in h.portaltheme_most_popular_tags(limit=15) %}
                <li>
                  <a href="{{ h.url_for('dataset.search', tags=tag.name) }}">
                    {{ tag.display_name }}
                  </a>
                </li>
              {% endfor %}
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
{% endblock %}
```

### 4. Create Custom CSS

**File**: `assets/css/style.css`

```css
/* Hero Banner */
.hero-banner {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 80px 0;
    margin-bottom: 40px;
    text-align: center;
}

.hero-banner h1 {
    font-size: 48px;
    font-weight: bold;
    margin-bottom: 20px;
}

.hero-banner .lead {
    font-size: 24px;
    opacity: 0.9;
}

/* Custom Header */
.account-masthead {
    background-color: #2c3e50;
}

.masthead {
    background-color: #34495e;
}

/* Tag List */
.tag-list {
    list-style: none;
    padding: 0;
    margin: 0;
}

.tag-list li {
    display: inline-block;
    margin: 5px;
}

.tag-list a {
    background-color: #3498db;
    color: white;
    padding: 5px 12px;
    border-radius: 3px;
    text-decoration: none;
    font-size: 13px;
}

.tag-list a:hover {
    background-color: #2980b9;
}

/* Footer */
.site-footer {
    background-color: #2c3e50;
    color: white;
}
```

### 5. Custom Header Logo

**File**: `templates/header.html`

```jinja
{% ckan_extends %}

{% block header_logo %}
  <a class="logo" href="{{ h.url_for('home.index') }}">
    <img src="{{ h.url_for_static('/portaltheme/images/logo.png') }}" 
         alt="{{ g.site_title }}" 
         title="{{ g.site_title }}">
  </a>
{% endblock %}
```

### 6. Install and Enable

```bash
# Inside container
pip install -e .
exit

# On host - edit .env
# Add to CKAN__PLUGINS
CKAN__PLUGINS="... portaltheme"

# Restart
docker compose restart ckan
```

---

## 🔗 Additional Resources

- **Official Theming Guide**: https://docs.ckan.org/en/2.9/theming/
- **Template Customization**: https://docs.ckan.org/en/2.9/theming/templates.html
- **CSS Customization**: https://docs.ckan.org/en/2.9/theming/css.html
- **JavaScript Guide**: https://docs.ckan.org/en/2.9/theming/javascript.html
- **Best Practices**: https://docs.ckan.org/en/2.9/theming/best-practices.html
- **Template Helpers Reference**: https://docs.ckan.org/en/2.9/theming/template-helper-functions.html
- **Extension Tutorial**: https://docs.ckan.org/en/2.9/extensions/tutorial.html

---

## 🎯 Quick Tips

1. **Debug Mode**: Set `debug = true` to see template paths
2. **Cache**: Clear cache after template changes: `docker compose restart ckan`
3. **Logs**: Check logs if something breaks: `docker compose logs -f ckan`
4. **Inspect**: Use browser DevTools to inspect CKAN's CSS classes
5. **Examples**: Check existing CKAN extensions on GitHub for inspiration

---

**Happy Theming! 🎨**


