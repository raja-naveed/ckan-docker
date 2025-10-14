# encoding: utf-8
from setuptools import setup, find_packages

version = '0.1'

setup(
    name='ckanext-demotheme',
    version=version,
    description="Demo theme for CKAN",
    long_description='',
    classifiers=[],
    keywords='',
    author='Demo Author',
    author_email='demo@example.com',
    url='',
    license='MIT',
    packages=find_packages(exclude=['ez_setup', 'examples', 'tests']),
    namespace_packages=['ckanext'],
    include_package_data=True,
    zip_safe=False,
    install_requires=[],
    entry_points='''
        [ckan.plugins]
        demotheme=ckanext.demotheme.plugin:DemoThemePlugin
    ''',
)


