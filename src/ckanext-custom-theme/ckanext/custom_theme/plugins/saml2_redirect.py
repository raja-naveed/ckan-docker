"""
Custom plugin to redirect /user/login to /user/saml2login
"""
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
from flask import Blueprint, redirect, url_for

class Saml2RedirectPlugin(plugins.SingletonPlugin):
    """Plugin to redirect standard login to SAML2 login"""
    
    plugins.implements(plugins.IBlueprint)
    
    def get_blueprint(self):
        """Create blueprint for SAML2 redirect"""
        blueprint = Blueprint('saml2_redirect', __name__)
        
        @blueprint.route('/user/login')
        def redirect_to_saml2():
            """Redirect /user/login to SAML2 login"""
            return redirect(url_for('user.saml2login'))
        
        return blueprint
