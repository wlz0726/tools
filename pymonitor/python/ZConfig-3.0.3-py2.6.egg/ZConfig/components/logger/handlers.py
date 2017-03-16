##############################################################################
#
# Copyright (c) 2003 Zope Foundation and Contributors.
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
"""ZConfig factory datatypes for log handlers."""

import sys

from ZConfig.components.logger.factory import Factory

try:
    import urlparse
except ImportError:
    # Python 3 support.
    import urllib.parse as urlparse

_log_format_variables = {
    'name': '',
    'levelno': '3',
    'levelname': 'DEBUG',
    'pathname': 'apath',
    'filename': 'afile',
    'module': 'amodule',
    'lineno': 1,
    'created': 1.1,
    'asctime': 'atime',
    'msecs': 1,
    'relativeCreated': 1,
    'thread': 1,
    'message': 'amessage',
    'process': 1,
    }

def log_format(value):
    value = ctrl_char_insert(value)
    try:
        # Make sure the format string uses only names that will be
        # provided, and has reasonable type flags for each, and does
        # not expect positional args.
        value % _log_format_variables
    except (ValueError, KeyError):
        raise ValueError('Invalid log format string %s' % value)
    return value

_control_char_rewrites = {r'\n': '\n', r'\t': '\t', r'\b': '\b',
                          r'\f': '\f', r'\r': '\r'}.items()

def ctrl_char_insert(value):
    for pattern, replacement in _control_char_rewrites:
        value = value.replace(pattern, replacement)
    return value

def resolve(name):
    """Given a dotted name, returns an object imported from a Python module."""
    name = name.split('.')
    used = name.pop(0)
    found = __import__(used)
    for n in name:
        used += '.' + n
        try:
            found = getattr(found, n)
        except AttributeError:
            __import__(used)
            found = getattr(found, n)
    return found

class HandlerFactory(Factory):
    def __init__(self, section):
        Factory.__init__(self)
        self.section = section

    def create_loghandler(self):
        raise NotImplementedError(
            "subclasses must override create_loghandler()")

    def create(self):
        import logging
        logger = self.create_loghandler()
        if self.section.formatter:
            f = resolve(self.section.formatter)
        else:
            f = logging.Formatter
        logger.setFormatter(f(self.section.format, self.section.dateformat))
        logger.setLevel(self.section.level)
        return logger

    def getLevel(self):
        return self.section.level

class FileHandlerFactory(HandlerFactory):
    def create_loghandler(self):
        from ZConfig.components.logger import loghandler
        path = self.section.path
        max_bytes = self.section.max_size
        old_files = self.section.old_files
        when = self.section.when
        interval = self.section.interval
        if path == "STDERR":
            if max_bytes or old_files:
                raise ValueError("cannot rotate STDERR")
            handler = loghandler.StreamHandler(sys.stderr)
        elif path == "STDOUT":
            if max_bytes or old_files:
                raise ValueError("cannot rotate STDOUT")
            handler = loghandler.StreamHandler(sys.stdout)
        elif when or max_bytes or old_files or interval:
            if not old_files:
                raise ValueError("old-files must be set for log rotation")
            if when:
                if max_bytes:
                    raise ValueError("can't set *both* max_bytes and when")
                if not interval:
                    interval = 1
                handler = loghandler.TimedRotatingFileHandler(
                    path, when=when, interval=interval,
                    backupCount=old_files)
            elif max_bytes:
                handler = loghandler.RotatingFileHandler(
                    path, maxBytes=max_bytes, backupCount=old_files)
            else:
                raise ValueError(
                    "max-bytes or when must be set for log rotation")
        else:
            handler = loghandler.FileHandler(path)
        return handler

_syslog_facilities = {
    "auth": 1,
    "authpriv": 1,
    "cron": 1,
    "daemon": 1,
    "kern": 1,
    "lpr": 1,
    "mail": 1,
    "news": 1,
    "security": 1,
    "syslog": 1,
    "user": 1,
    "uucp": 1,
    "local0": 1,
    "local1": 1,
    "local2": 1,
    "local3": 1,
    "local4": 1,
    "local5": 1,
    "local6": 1,
    "local7": 1,
    }

def syslog_facility(value):
    value = value.lower()
    if value not in _syslog_facilities:
        L = sorted(_syslog_facilities.keys())
        raise ValueError("Syslog facility must be one of " + ", ".join(L))
    return value

class SyslogHandlerFactory(HandlerFactory):
    def create_loghandler(self):
        from ZConfig.components.logger import loghandler
        return loghandler.SysLogHandler(self.section.address.address,
                                        self.section.facility)

class Win32EventLogFactory(HandlerFactory):
    def create_loghandler(self):
        from ZConfig.components.logger import loghandler
        return loghandler.Win32EventLogHandler(self.section.appname)

def http_handler_url(value):
    scheme, netloc, path, param, query, fragment = urlparse.urlparse(value)
    if scheme != 'http':
        raise ValueError('url must be an http url')
    if not netloc:
        raise ValueError('url must specify a location')
    if not path:
        raise ValueError('url must specify a path')
    q = []
    if param:
        q.append(';')
        q.append(param)
    if query:
        q.append('?')
        q.append(query)
    if fragment:
        q.append('#')
        q.append(fragment)
    return (netloc, path + ''.join(q))

def get_or_post(value):
    value = value.upper()
    if value not in ('GET', 'POST'):
        raise ValueError('method must be "GET" or "POST", instead received: '
                         + repr(value))
    return value

class HTTPHandlerFactory(HandlerFactory):
    def create_loghandler(self):
        from ZConfig.components.logger import loghandler
        host, selector = self.section.url
        return loghandler.HTTPHandler(host, selector, self.section.method)

class SMTPHandlerFactory(HandlerFactory):
    def create_loghandler(self):
        from ZConfig.components.logger import loghandler
        host, port = self.section.smtp_server
        if not port:
            mailhost = host
        else:
            mailhost = host, port
        kwargs = {}
        if self.section.smtp_username and self.section.smtp_password:
            # Since credentials were only added in py2.6 we use a kwarg to not
            # break compatibility with older py
            if sys.version_info < (2, 6):
                raise ValueError('SMTP auth requires at least Python 2.6.')
            kwargs['credentials'] = (self.section.smtp_username,
                                     self.section.smtp_password)
        elif (self.section.smtp_username or self.section.smtp_password):
            raise ValueError(
                'Either both smtp-username and smtp-password or none must be '
                'given')
        return loghandler.SMTPHandler(mailhost,
                                      self.section.fromaddr,
                                      self.section.toaddrs,
                                      self.section.subject,
                                      **kwargs)
