import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
from ckan.lib import helpers as h
import datetime

class CustomThemePlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)
    plugins.implements(plugins.ITemplateHelpers)

    def update_config(self, config):
        toolkit.add_template_directory(config, 'templates')
        toolkit.add_public_directory(config, 'public')

    def get_helpers(self):
        return {
            'custom_get_total_datasets': self._get_total_datasets,
            'custom_get_featured_datasets': self._get_featured_datasets,
            'custom_get_recent_datasets': self._get_recent_datasets,
            'custom_get_organization_count': self._get_organization_count,
            'custom_get_group_count': self._get_group_count,
            'custom_get_groups_with_counts': self._get_groups_with_counts,
            'custom_get_popular_datasets': self._get_popular_datasets,
            'custom_get_total_resources': self._get_total_resources,
            'get_current_year': self._get_current_year,
        }

    def _get_total_datasets(self):
        """Get total number of datasets"""
        try:
            result = toolkit.get_action('package_search')({}, {})
            return result.get('count', 0)
        except Exception:
            return 0

    def _get_featured_datasets(self, limit=3):
        """Get featured datasets for homepage"""
        try:
            result = toolkit.get_action('package_search')({}, {
                'rows': limit,
                'sort': 'score desc, metadata_modified desc'
            })
            return result.get('results', [])
        except Exception:
            return []

    def _get_recent_datasets(self, limit=6):
        """Get recently updated datasets"""
        try:
            result = toolkit.get_action('package_search')({}, {
                'rows': limit,
                'sort': 'metadata_modified desc'
            })
            return result.get('results', [])
        except Exception:
            return []

    def _get_organization_count(self):
        """Get total number of organizations"""
        try:
            result = toolkit.get_action('organization_list')({}, {})
            return len(result)
        except Exception:
            return 0

    def _get_group_count(self):
        """Get total number of groups"""
        try:
            result = toolkit.get_action('group_list')({}, {})
            return len(result)
        except Exception:
            return 0

    def _get_current_year(self):
        """Get current year for copyright"""
        return datetime.datetime.now().year

    def _get_groups_with_counts(self, limit=9):
        """Get groups with their dataset counts for homepage"""
        try:
            groups = toolkit.get_action('group_list')({}, {
                'all_fields': True,
                'sort': 'package_count desc',
                'limit': limit
            })
            
            # Get dataset count for each group
            result = []
            for group in groups:
                try:
                    group_detail = toolkit.get_action('group_show')({}, {
                        'id': group['id'],
                        'include_datasets': False
                    })
                    result.append({
                        'id': group['id'],
                        'name': group['name'],
                        'title': group.get('title', group['name']),
                        'description': group.get('description', ''),
                        'package_count': group_detail.get('package_count', 0),
                        'image_url': group_detail.get('image_url', '')
                    })
                except Exception:
                    result.append({
                        'id': group['id'],
                        'name': group['name'],
                        'title': group.get('title', group['name']),
                        'description': group.get('description', ''),
                        'package_count': 0,
                        'image_url': ''
                    })
            
            return result
        except Exception:
            return []

    def _get_popular_datasets(self, limit=6):
        """Get popular datasets based on views/downloads"""
        try:
            result = toolkit.get_action('package_search')({}, {
                'rows': limit,
                'sort': 'views_recent desc, metadata_modified desc'
            })
            return result.get('results', [])
        except Exception:
            # Fallback to recently modified
            return self._get_recent_datasets(limit)

    def _get_total_resources(self):
        """Get total number of resources"""
        try:
            result = toolkit.get_action('package_search')({}, {
                'include_private': False
            })
            total = 0
            for dataset in result.get('results', []):
                total += dataset.get('num_resources', 0)
            return total
        except Exception:
            return 0

