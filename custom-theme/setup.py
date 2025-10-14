from setuptools import setup, find_packages

setup(
    name='ckanext-custom-theme',
    version='0.1',
    packages=find_packages(),
    description='Custom theme for CKAN',
    long_description='',
    author='Your Name',
    author_email='your.email@example.com',
    license='MIT',
    url='https://github.com/yourusername/ckanext-custom-theme',
    include_package_data=True,
    zip_safe=False,
    entry_points='''
        [ckan.plugins]
        custom_theme=ckanext.custom_theme.plugin:CustomThemePlugin
    ''',
)

