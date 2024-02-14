# Configuration file for the Sphinx documentation builder.

# -- Project information

project = 'annoSnake'
copyright = '2024, Bastian Heimburger'
author = 'Bastian Heimburger'

release = '0.1'
version = '0.1.0'

# -- General configuration

extensions = [
    'sphinx.ext.duration',
    'sphinx.ext.doctest',
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    'sphinx.ext.intersphinx',
    'sphinxcontrib.youtube',
    'sphinx_tabs.tabs',
    'sphinx_copybutton',
    'sphinx.ext.autodoc',
    'sphinxcontrib.images'
]

intersphinx_mapping = {
    'python': ('https://docs.python.org/3/', None),
    'sphinx': ('https://www.sphinx-doc.org/en/master/', None),
}
intersphinx_disabled_domains = ['std']

templates_path = ['_templates']

# -- Options for HTML output

html_theme = 'sphinx_rtd_theme'

#html_theme = 'furo'

# -- Options for EPUB output
epub_show_urls = 'footnote'

latex_engine = "xelatex"
