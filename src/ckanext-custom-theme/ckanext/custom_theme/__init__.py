# Custom theme for CKAN
import ckan.plugins as ckan_plugins
import ckan.plugins.toolkit as toolkit
from .plugins.saml2_redirect import Saml2RedirectPlugin

class CustomThemePlugin(ckan_plugins.SingletonPlugin):
    """Custom theme plugin with SAML2 redirect"""
    
    ckan_plugins.implements(ckan_plugins.IConfigurer)
    ckan_plugins.implements(ckan_plugins.ITemplateHelpers)
    
    def update_config(self, config):
        """Update CKAN config"""
        toolkit.add_template_directory(config, 'templates')
        toolkit.add_public_directory(config, 'public')
        toolkit.add_resource('fanstatic', 'custom_theme')
    
    def get_helpers(self):
        """Return custom template helpers"""
        return {}