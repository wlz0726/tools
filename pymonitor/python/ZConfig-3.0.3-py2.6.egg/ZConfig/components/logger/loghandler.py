##############################################################################
#
# Copyright (c) 2001 Zope Foundation and Contributors.
#
# This software is subject to the provisions of the Zope Public License,
# Version 2.1 (ZPL).  A copy of the ZPL should accompany this distribution.
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY AND ALL EXPRESS OR IMPLIED
# WARRANTIES ARE DISCLAIMED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF TITLE, MERCHANTABILITY, AGAINST INFRINGEMENT, AND FITNESS
# FOR A PARTICULAR PURPOSE.
#
##############################################################################

"""Handlers which can plug into a PEP 282 logger."""

import os
import sys
import weakref

from logging import Handler, StreamHandler
from logging.handlers import RotatingFileHandler as _RotatingFileHandler
from logging.handlers import TimedRotatingFileHandler \
     as _TimedRotatingFileHandler
from logging.handlers import SysLogHandler, BufferingHandler
from logging.handlers import HTTPHandler, SMTPHandler
from logging.handlers import NTEventLogHandler as Win32EventLogHandler



_reopenable_handlers = []

def closeFiles():
    """Reopen all logfiles managed by ZConfig configuration."""
    while _reopenable_handlers:
        wr = _reopenable_handlers.pop()
        h = wr()
        if h is not None:
            h.close()

def reopenFiles():
    """Reopen all logfiles managed by ZConfig configuration."""
    for wr in _reopenable_handlers[:]:
        h = wr()
        if h is None:
            try:
                _reopenable_handlers.remove(wr)
            except ValueError:
                continue
        else:
            h.reopen()

def _remove_from_reopenable(wr):
    try:
        _reopenable_handlers.remove(wr)
    except ValueError:
        pass


class FileHandler(StreamHandler):
    """File handler which supports reopening of logs.

    Re-opening should be used instead of the 'rollover' feature of
    the FileHandler from the standard library's logging package.
    """

    def __init__(self, filename, mode="a"):
        filename = os.path.abspath(filename)
        StreamHandler.__init__(self, open(filename, mode))
        self.baseFilename = filename
        self.mode = mode
        self._wr = weakref.ref(self, _remove_from_reopenable)
        _reopenable_handlers.append(self._wr)

    def close(self):
        self.stream.close()
        # This can raise a KeyError if the handler has already been
        # removed, but a later error can be raised if
        # StreamHandler.close() isn't called.  This seems the best
        # compromise.  :-(
        try:
            StreamHandler.close(self)
        except KeyError:
            pass
        _remove_from_reopenable(self._wr)

    def reopen(self):
        self.acquire()
        try:
            self.stream.close()
            self.stream = open(self.baseFilename, self.mode)
        finally:
            self.release()


class Win32FileHandler(FileHandler):
    """File-based log handler for Windows that supports an additional 'rotate'
    method.  reopen() is generally useless since Windows cannot do a move on
    an open file.
    """
    def rotate(self, rotateFilename=None):
        if not rotateFilename:
            rotateFilename = self.baseFilename + ".last"
        error = None
        self.close()
        try:
            os.rename(self.baseFilename, rotateFilename)
        except OSError:
            pass

        self.stream = open(self.baseFilename, self.mode)

if os.name == "nt":
    # Make it the default for Windows - we install a 'reopen' handler that
    # tries to rotate the logfile.
    FileHandler = Win32FileHandler


class RotatingFileHandler(_RotatingFileHandler):

    def __init__(self, *args, **kw):
        _RotatingFileHandler.__init__(self, *args, **kw)
        self._wr = weakref.ref(self, _remove_from_reopenable)
        _reopenable_handlers.append(self._wr)

    def close(self):
        _RotatingFileHandler.close(self)
        _remove_from_reopenable(self._wr)

    def reopen(self):
        self.doRollover()

class TimedRotatingFileHandler(_TimedRotatingFileHandler):

    def __init__(self, *args, **kw):
        _TimedRotatingFileHandler.__init__(self, *args, **kw)
        self._wr = weakref.ref(self, _remove_from_reopenable)
        _reopenable_handlers.append(self._wr)

    def close(self):
        _TimedRotatingFileHandler.close(self)
        _remove_from_reopenable(self._wr)

    def reopen(self):
        self.doRollover()


class NullHandler(Handler):
    """Handler that does nothing."""

    def emit(self, record):
        pass

    def handle(self, record):
        pass


class StartupHandler(BufferingHandler):
    """Handler which stores messages in a buffer until later.

    This is useful at startup before we can know that we can safely
    write to a configuration-specified handler.
    """

    def __init__(self):
        BufferingHandler.__init__(self, sys.maxint)

    def shouldFlush(self, record):
        return False

    def flushBufferTo(self, target):
        while self.buffer:
            target.handle(self.buffer.pop(0))
