# Configuration file for the Sphinx documentation builder.

# -- Project information

project = 'annoSnake'
date = datetime.now()
copyright = "2024-{year}, Bastian Heimburger".format(year=date.timetuple()[0])

import sys
import os
from datetime import datetime
from sphinxawesome_theme.postprocess import Icons

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
    'sphinxcontrib.images',
    "sphinx.ext.mathjax",
    "sphinx.ext.viewcode",
    "sphinx.ext.napoleon",
    "sphinxarg.ext",
    "sphinx.ext.autosectionlabel",
    "myst_parser",
    "sphinxawesome_theme.highlighting",
]

intersphinx_mapping = {
    'python': ('https://docs.python.org/3/', None),
    'sphinx': ('https://www.sphinx-doc.org/en/master/', None),
}
intersphinx_disabled_domains = ['std']

templates_path = ['_templates']

version = snakemake.__version__

if os.environ.get("READTHEDOCS") == "True":
    # Because Read The Docs modifies conf.py, versioneer gives a "dirty"
    # version like "5.10.0+0.g28674b1.dirty" that is cleaned here.
    version = version.partition("+0.g")[0]

release = version
# -- Options for HTML output
exclude_patterns = ["_build", "apidocs"]

html_theme = "sphinxawesome_theme"
html_theme_options = {
    "logo_light": "",
    "logo_dark": "",
    "main_nav_links": {
        "Github": "https://github.com/bheimbu/annoSnake",
    },
    "awesome_external_links": True,
    "awesome_headerlinks": True,
    "show_prev_next": False,
}
html_permalinks_icon = Icons.permalinks_icon

#html_theme = 'furo'

# -- Options for EPUB output
epub_show_urls = 'footnote'

latex_engine = "xelatex"

def setup(app):
    app.add_css_file("sphinx-argparse.css")
