##############################################################################
#
# Copyright (c) 2002, 2003 Zope Foundation and Contributors.
# All Rights Reserved.
#
# This software is subject to the provisions of the Zope Public License,
# Version 2.1 (ZPL).  A copy of the ZPL should accompany this distribution.
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY AND ALL EXPRESS OR IMPLIED
# WARRANTIES ARE DISCLAIMED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF TITLE, MERCHANTABILITY, AGAINST INFRINGEMENT, AND FITNESS
# FOR A PARTICULAR PURPOSE.
#
##############################################################################
"""Structured, schema-driven configuration library.

ZConfig is a configuration library intended for general use.  It
supports a hierarchical schema-driven configuration model that allows
a schema to specify data conversion routines written in Python.
ZConfig's model is very different from the model supported by the
ConfigParser module found in Python's standard library, and is more
suitable to configuration-intensive applications.

ZConfig schema are written in an XML-based language and are able to
``import`` schema components provided by Python packages.  Since
components are able to bind to conversion functions provided by Python
code in the package (or elsewhere), configuration objects can be
arbitrarily complex, with values that have been verified against
arbitrary constraints.  This makes it easy for applications to
separate configuration support from configuration loading even with
configuration data being defined and consumed by a wide range of
separate packages.


$Id: __init__.py,v 1.18 2004/04/15 20:33:32 fdrake Exp $
"""
__docformat__ = "reStructuredText"

version_info = (3, 0)
__version__ = ".".join([str(n) for n in version_info])

from ZConfig.loader import loadConfig, loadConfigFile
from ZConfig.loader import loadSchema, loadSchemaFile

try:
    import StringIO as StringIO
except ImportError:
    # Python 3 support.
    import io as StringIO


class ConfigurationError(Exception):
    """Base class for ZConfig exceptions."""

    # The 'message' attribute was deprecated for BaseException with
    # Python 2.6; here we create descriptor properties to continue using it
    def __set_message(self, v):
        self.__dict__['message'] = v

    def __get_message(self):
        return self.__dict__['message']

    def __del_message(self):
        del self.__dict__['message']

    message = property(__get_message, __set_message, __del_message)

    def __init__(self, msg, url=None):
        self.message = msg
        self.url = url
        Exception.__init__(self, msg)

    def __str__(self):
        return self.message


class _ParseError(ConfigurationError):
    def __init__(self, msg, url, lineno, colno=None):
        self.lineno = lineno
        self.colno = colno
        ConfigurationError.__init__(self, msg, url)

    def __str__(self):
        s = self.message
        if self.url:
            s += "\n("
        elif (self.lineno, self.colno) != (None, None):
            s += " ("
        if self.lineno:
            s += "line %d" % self.lineno
            if self.colno is not None:
                s += ", column %d" % self.colno
            if self.url:
                s += " in %s)" % self.url
            else:
                s += ")"
        elif self.url:
            s += self.url + ")"
        return s


class SchemaError(_ParseError):
    """Raised when there's an error in the schema itself."""

    def __init__(self, msg, url=None, lineno=None, colno=None):
        _ParseError.__init__(self, msg, url, lineno, colno)


class SchemaResourceError(SchemaError):
    """Raised when there's an error locating a resource required by the schema.
    """

    def __init__(self, msg, url=None, lineno=None, colno=None,
                 path=None, package=None, filename=None):
        self.filename = filename
        self.package = package
        if path is not None:
            path = path[:]
        self.path = path
        SchemaError.__init__(self, msg, url, lineno, colno)

    def __str__(self):
        s = SchemaError.__str__(self)
        if self.package is not None:
            s += "\n  Package name: " + repr(self.package)
        if self.filename is not None:
            s += "\n  File name: " + repr(self.filename)
        if self.package is not None:
            s += "\n  Package path: " + repr(self.path)
        return s


class ConfigurationSyntaxError(_ParseError):
    """Raised when there's a syntax error in a configuration file."""


class DataConversionError(ConfigurationError, ValueError):
    """Raised when a data type conversion function raises ValueError."""

    def __init__(self, exception, value, position):
        ConfigurationError.__init__(self, str(exception))
        self.exception = exception
        self.value = value
        self.lineno, self.colno, self.url = position

    def __str__(self):
        s = "%s (line %s" % (self.message, self.lineno)
        if self.colno is not None:
            s += ", %s" % self.colno
        if self.url:
            s += ", in %s)" % self.url
        else:
            s += ")"
        return s


class SubstitutionSyntaxError(ConfigurationError):
    """Raised when interpolation source text contains syntactical errors."""


class SubstitutionReplacementError(ConfigurationSyntaxError, LookupError):
    """Raised when no replacement is available for a reference."""

    def __init__(self, source, name, url=None, lineno=None):
        self.source = source
        self.name = name
        ConfigurationSyntaxError.__init__(
            self, "no replacement for " + repr(name), url, lineno)


def configureLoggers(text):
    """Configure one or more loggers from configuration text."""
    schema = loadSchemaFile(StringIO.StringIO("""
    <schema>
    <import package='ZConfig.components.logger'/>
    <multisection type='logger' name='*' attribute='loggers'/>
    </schema>
    """))
    for factory in loadConfigFile(schema, StringIO.StringIO(text))[0].loggers:
        factory()
