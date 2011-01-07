# Setup file for tape

from setuptools import setup

description = """\
A simple Web server which serves static files and do simple proxying"""
long_description = """\
Tape is a simple Web server which will serve up a directory of files and do
simple proxying. It is quite handy when developing Web applications that do not
depend on application servers."""

setup(name = "tape",
      description = description,
      long_description = long_description,
      license = "GNU General Public License v3",
      url = "http://github.com/metajack/tape",

      author = "Jack Moffitt",
      author_email = "jack@metajack.im",

      version = "1.0",
      scripts = ['tape'],
      data_files = [('', ['README.markdown', 'LICENSE.txt', 'taperc.example'])],
      install_requires = ['twisted'],

      classifiers = ["Development Status :: 5 - Production/Stable",
                     "License :: OSI Approved :: GNU General Public License v3",
                     "Operating System :: OS Independent",
                     "Programming Language :: Python :: 2.6",
                     "Topic :: Utilities"])

