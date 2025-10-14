from setuptools import setup, find_packages

setup(
    name='ckanext-demotheme',
    version='0.1',
    packages=find_packages(),
    description='Demo theme for CKAN',
    long_description='',
    author='Your Name',
    author_email='your.email@example.com',
    license='MIT',
    url='https://github.com/yourusername/ckanext-demotheme',
    include_package_data=True,
    zip_safe=False,
    entry_points='''
        [ckan.plugins]
        demotheme=ckanext.demotheme.plugin:DemoThemePlugin
    ''',
)

