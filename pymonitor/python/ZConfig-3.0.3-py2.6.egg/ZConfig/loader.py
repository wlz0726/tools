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
"""Schema loader utility."""

import os.path
import re
import sys
import urllib

import ZConfig
import ZConfig.cfgparser
import ZConfig.datatypes
import ZConfig.info
import ZConfig.matcher
import ZConfig.schema
import ZConfig.url

try:
    import StringIO as StringIO
except ImportError:
    # Python 3 support.
    import io as StringIO

try:
    import urllib2
except ImportError:
    # Python 3 support
    import urllib.request as urllib2

try:
    from urllib import pathname2url
except ImportError:
    # Python 3 support
    from urllib.request import pathname2url


def loadSchema(url):
    return SchemaLoader().loadURL(url)

def loadSchemaFile(file, url=None):
    return SchemaLoader().loadFile(file, url)

def loadConfig(schema, url, overrides=()):
    return _get_config_loader(schema, overrides).loadURL(url)

def loadConfigFile(schema, file, url=None, overrides=()):
    return _get_config_loader(schema, overrides).loadFile(file, url)


def _get_config_loader(schema, overrides):
    if overrides:
        from ZConfig import cmdline
        loader = cmdline.ExtendedConfigLoader(schema)
        for opt in overrides:
            loader.addOption(opt)
    else:
        loader = ConfigLoader(schema)
    return loader


class BaseLoader:
    def __init__(self):
        pass

    def createResource(self, file, url):
        return Resource(file, url)

    def loadURL(self, url):
        url = self.normalizeURL(url)
        r = self.openResource(url)
        try:
            return self.loadResource(r)
        finally:
            r.close()

    def loadFile(self, file, url=None):
        if not url:
            url = _url_from_file(file)
        r = self.createResource(file, url)
        try:
            return self.loadResource(r)
        finally:
            r.close()

    # utilities

    def loadResource(self, resource):
        raise NotImplementedError(
            "BaseLoader.loadResource() must be overridden by a subclass")

    def openResource(self, url):
        # ConfigurationError exceptions raised here should be
        # str()able to generate a message for an end user.
        #
        # XXX This should be replaced to use a local cache for remote
        # resources.  The policy needs to support both re-retrieve on
        # change and provide the cached resource when the remote
        # resource is not accessible.
        url = str(url)
        if url.startswith("package:"):
            _, package, filename = url.split(":", 2)
            file = openPackageResource(package, filename)
        else:
            try:
                file = urllib2.urlopen(url)
            except urllib2.URLError as e:
                # urllib2.URLError has a particularly hostile str(), so we
                # generally don't want to pass it along to the user.
                self._raise_open_error(url, e.reason)
            except (IOError, OSError) as e:
                # Python 2.1 raises a different error from Python 2.2+,
                # so we catch both to make sure we detect the situation.
                self._raise_open_error(url, str(e))
            if sys.version_info[0] >= 3:
                # Python 3 support: file.read() returns bytes, so we convert it
                # to an StringIO.  (Can't use io.TextIOWrapper because of
                # http://bugs.python.org/issue16723 and probably other bugs)
                try:
                    data = file.read().decode()
                finally:
                    file.close()
                file = StringIO.StringIO(data)
        return self.createResource(file, url)

    def _raise_open_error(self, url, message):
        if url[:7].lower() == "file://":
            what = "file"
            ident = urllib2.url2pathname(url[7:])
        else:
            what = "URL"
            ident = url
        raise ZConfig.ConfigurationError(
            "error opening %s %s: %s" % (what, ident, message),
            url)

    def normalizeURL(self, url):
        if self.isPath(url):
            url = "file://" + pathname2url(os.path.abspath(url))
        newurl, fragment = ZConfig.url.urldefrag(url)
        if fragment:
            raise ZConfig.ConfigurationError(
                "fragment identifiers are not supported",
                url)
        return newurl

    # from RFC 3986:
    # schema = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    _pathsep_rx = re.compile(r"[a-zA-Z][-+.a-zA-Z0-9]*:")

    def isPath(self, s):
        """Return True iff 's' should be handled as a filesystem path."""
        if ":" in s:
            # XXX This assumes that one-character scheme identifiers
            # are always Windows drive letters; I don't know of any
            # one-character scheme identifiers.
            m = self._pathsep_rx.match(s)
            if m is None:
                return True
            # Does it look like a drive letter?
            return len(m.group(0)) == 2
        else:
            return True


def openPackageResource(package, path):
    __import__(package)
    pkg = sys.modules[package]
    try:
        loader = pkg.__loader__
    except AttributeError:
        relpath = os.path.join(*path.split("/"))
        for dir in pkg.__path__:
            filename = os.path.join(dir, relpath)
            if os.path.exists(filename):
                break
        else:
            raise ZConfig.SchemaResourceError("schema component not found",
                                              filename=path,
                                              package=package,
                                              path=pkg.__path__)
        url = "file:" + pathname2url(filename)
        url = ZConfig.url.urlnormalize(url)
        return urllib2.urlopen(url)
    else:
        for dir in pkg.__path__:
            loadpath = os.path.join(dir, path)
            try:
                return StringIO.StringIO(
                    loader.get_data(loadpath).decode('utf-8'))
            except Exception:
                pass
        raise ZConfig.SchemaResourceError("schema component not found",
                                          filename=path,
                                          package=package,
                                          path=pkg.__path__)


def _url_from_file(file):
    name = getattr(file, "name", None)
    if name and name[0] != "<" and name[-1] != ">":
        return "file://" + pathname2url(os.path.abspath(name))
    else:
        return None


class SchemaLoader(BaseLoader):
    def __init__(self, registry=None):
        if registry is None:
            registry = ZConfig.datatypes.Registry()
        BaseLoader.__init__(self)
        self.registry = registry
        self._cache = {}

    def loadResource(self, resource):
        if resource.url and resource.url in self._cache:
            schema = self._cache[resource.url]
        else:
            schema = ZConfig.schema.parseResource(resource, self)
            self._cache[resource.url] = schema
        return schema

    # schema parser support API

    def schemaComponentSource(self, package, file):
        parts = package.split(".")
        if not parts:
            raise ZConfig.SchemaError(
                "illegal schema component name: " + repr(package))
        if "" in parts:
            # '' somewhere in the package spec; still illegal
            raise ZConfig.SchemaError(
                "illegal schema component name: " + repr(package))
        file = file or "component.xml"
        try:
            __import__(package)
        except ImportError as e:
            raise ZConfig.SchemaResourceError(
                "could not load package %s: %s" % (package, str(e)),
                filename=file,
                package=package)
        pkg = sys.modules[package]
        if not hasattr(pkg, "__path__"):
            raise ZConfig.SchemaResourceError(
                "import name does not refer to a package",
                filename=file, package=package)
        return "package:%s:%s" % (package, file)


class ConfigLoader(BaseLoader):
    def __init__(self, schema):
        if schema.isabstract():
            raise ZConfig.SchemaError(
                "cannot check a configuration an abstract type")
        BaseLoader.__init__(self)
        self.schema = schema
        self._private_schema = False

    def loadResource(self, resource):
        sm = self.createSchemaMatcher()
        self._parse_resource(sm, resource)
        result = sm.finish(), CompositeHandler(sm.handlers, self.schema)
        return result

    def createSchemaMatcher(self):
        return ZConfig.matcher.SchemaMatcher(self.schema)

    # config parser support API

    def startSection(self, parent, type, name):
        t = self.schema.gettype(type)
        if t.isabstract():
            raise ZConfig.ConfigurationError(
                "concrete sections cannot match abstract section types;"
                " found abstract type " + repr(type))
        return parent.createChildMatcher(t, name)

    def endSection(self, parent, type, name, matcher):
        sectvalue = matcher.finish()
        parent.addSection(type, name, sectvalue)

    def importSchemaComponent(self, pkgname):
        schema = self.schema
        if not self._private_schema:
            # replace the schema with an extended schema on the first %import
            self._loader = SchemaLoader(self.schema.registry)
            schema = ZConfig.info.createDerivedSchema(self.schema)
            self._private_schema = True
            self.schema = schema
        url = self._loader.schemaComponentSource(pkgname, '')
        if schema.hasComponent(url):
            return
        resource = self.openResource(url)
        schema.addComponent(url)
        try:
            ZConfig.schema.parseComponent(resource, self._loader, schema)
        finally:
            resource.close()

    def includeConfiguration(self, section, url, defines):
        url = self.normalizeURL(url)
        r = self.openResource(url)
        try:
            self._parse_resource(section, r, defines)
        finally:
            r.close()

    # internal helper

    def _parse_resource(self, matcher, resource, defines=None):
        parser = ZConfig.cfgparser.ZConfigParser(resource, self, defines)
        parser.parse(matcher)


class CompositeHandler:

    def __init__(self, handlers, schema):
        self._handlers = handlers
        self._convert = schema.registry.get("basic-key")

    def __call__(self, handlermap):
        d = {}
        for name, callback in handlermap.items():
            n = self._convert(name)
            if n in d:
                raise ZConfig.ConfigurationError(
                    "handler name not unique when converted to a basic-key: "
                    + repr(name))
            d[n] = callback
        L = []
        for handler, value in self._handlers:
            if handler not in d:
                L.append(handler)
        if L:
            raise ZConfig.ConfigurationError(
                "undefined handlers: " + ", ".join(L))
        for handler, value in self._handlers:
            f = d[handler]
            if f is not None:
                f(value)

    def __len__(self):
        return len(self._handlers)


class Resource:
    def __init__(self, file, url):
        self.file = file
        self.url = url

    def close(self):
        if self.file is not None:
            self.file.close()
            self.file = None
            self.closed = True

    def __getattr__(self, name):
        return getattr(self.file, name)
