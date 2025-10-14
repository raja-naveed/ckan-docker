import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit

class CustomThemePlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)
    plugins.implements(plugins.ITemplateHelpers)

    def update_config(self, config):
        toolkit.add_template_directory(config, 'templates')
        toolkit.add_public_directory(config, 'public')

    def get_helpers(self):
        return {
            'custom_get_total_datasets': self._get_total_datasets,
        }

    def _get_total_datasets(self):
        try:
            result = toolkit.get_action('package_search')({}, {})
            return result.get('count', 0)
        except Exception:
            return 0

