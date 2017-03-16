##############################################################################
#
# Copyright (c) 2002 Zope Foundation and Contributors.
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

"""Tests for logging configuration via ZConfig."""

import doctest
import logging
import os
import sys
import tempfile
import unittest

import ZConfig

from ZConfig.components.logger import datatypes
from ZConfig.components.logger import handlers
from ZConfig.components.logger import loghandler

try:
    import StringIO as StringIO
except ImportError:
    # Python 3 support.
    import io as StringIO

class CustomFormatter(logging.Formatter):
    def formatException(self, ei):
        """Format and return the exception information as a string.

        This adds helpful advice to the end of the traceback.
        """
        import traceback
        sio = StringIO.StringIO()
        traceback.print_exception(ei[0], ei[1], ei[2], file=sio)
        return sio.getvalue() + "... Don't panic!"


def read_file(filename):
    with open(filename) as f:
        return f.read()


class LoggingTestHelper:

    # Not derived from unittest.TestCase; some test runners seem to
    # think that means this class contains tests.

    # XXX This tries to save and restore the state of logging around
    # the test.  Somewhat surgical; there may be a better way.

    def setUp(self):
        self._created = []
        self._old_logger = logging.getLogger()
        self._old_level = self._old_logger.level
        self._old_handlers = self._old_logger.handlers[:]
        self._old_logger.handlers[:] = []
        self._old_logger.setLevel(logging.WARN)

        self._old_logger_dict = logging.root.manager.loggerDict.copy()
        logging.root.manager.loggerDict.clear()

    def tearDown(self):
        logging.root.manager.loggerDict.clear()
        logging.root.manager.loggerDict.update(self._old_logger_dict)

        for h in self._old_logger.handlers:
            self._old_logger.removeHandler(h)
        for h in self._old_handlers:
            self._old_logger.addHandler(h)
        self._old_logger.setLevel(self._old_level)

        while self._created:
            os.unlink(self._created.pop())

        self.assertEqual(loghandler._reopenable_handlers, [])
        loghandler.closeFiles()
        loghandler._reopenable_handlers == []

    def mktemp(self):
        fd, fn = tempfile.mkstemp()
        os.close(fd)
        self._created.append(fn)
        return fn

    def move(self, fn):
        nfn = self.mktemp()
        os.rename(fn, nfn)
        return nfn

    _schema = None

    def get_schema(self):
        if self._schema is None:
            sio = StringIO.StringIO(self._schematext)
            self.__class__._schema = ZConfig.loadSchemaFile(sio)
        return self._schema

    def get_config(self, text):
        conf, handler = ZConfig.loadConfigFile(self.get_schema(),
                                               StringIO.StringIO(text))
        self.assertTrue(not handler)
        return conf


class TestConfig(LoggingTestHelper, unittest.TestCase):

    _schematext = """
      <schema>
        <import package='ZConfig.components.logger'/>
        <section type='eventlog' name='*' attribute='eventlog'/>
      </schema>
    """

    def test_logging_level(self):
        # Make sure the expected names are supported; it's not clear
        # how to check the values in a meaningful way.
        # Just make sure they're case-insensitive.
        convert = datatypes.logging_level
        for name in ["notset", "all", "trace", "debug", "blather",
                     "info", "warn", "warning", "error", "fatal",
                     "critical"]:
            self.assertEqual(convert(name), convert(name.upper()))
        self.assertRaises(ValueError, convert, "hopefully-not-a-valid-value")
        self.assertEqual(convert('10'), 10)
        self.assertRaises(ValueError, convert, '100')

    def test_http_method(self):
        convert = handlers.get_or_post
        self.assertEqual(convert("get"), "GET")
        self.assertEqual(convert("GET"), "GET")
        self.assertEqual(convert("post"), "POST")
        self.assertEqual(convert("POST"), "POST")
        self.assertRaises(ValueError, convert, "")
        self.assertRaises(ValueError, convert, "foo")

    def test_syslog_facility(self):
        convert = handlers.syslog_facility
        for name in ["auth", "authpriv", "cron", "daemon", "kern",
                     "lpr", "mail", "news", "security", "syslog",
                     "user", "uucp", "local0", "local1", "local2",
                     "local3", "local4", "local5", "local6", "local7"]:
            self.assertEqual(convert(name), name)
            self.assertEqual(convert(name.upper()), name)
        self.assertRaises(ValueError, convert, "hopefully-never-a-valid-value")

    def test_config_without_logger(self):
        conf = self.get_config("")
        self.assertTrue(conf.eventlog is None)

    def test_config_without_handlers(self):
        logger = self.check_simple_logger("<eventlog/>")
        # Make sure there's a NullHandler, since a warning gets
        # printed if there are no handlers:
        self.assertEqual(len(logger.handlers), 1)
        self.assertTrue(isinstance(logger.handlers[0], loghandler.NullHandler))

    def test_with_logfile(self):
        fn = self.mktemp()
        logger = self.check_simple_logger("<eventlog>\n"
                                          "  <logfile>\n"
                                          "    path %s\n"
                                          "    level debug\n"
                                          "  </logfile>\n"
                                          "</eventlog>" % fn)
        logfile = logger.handlers[0]
        self.assertEqual(logfile.level, logging.DEBUG)
        self.assertTrue(isinstance(logfile, loghandler.FileHandler))
        logger.removeHandler(logfile)
        logfile.close()

    def test_with_stderr(self):
        self.check_standard_stream("stderr")

    def test_with_stdout(self):
        self.check_standard_stream("stdout")

    def test_with_rotating_logfile(self):
        fn = self.mktemp()
        logger = self.check_simple_logger("<eventlog>\n"
                                          "  <logfile>\n"
                                          "    path %s\n"
                                          "    level debug\n"
                                          "    max-size 5mb\n"
                                          "    old-files 10\n"
                                          "  </logfile>\n"
                                          "</eventlog>" % fn)
        logfile = logger.handlers[0]
        self.assertEqual(logfile.level, logging.DEBUG)
        self.assertEqual(logfile.backupCount, 10)
        self.assertEqual(logfile.maxBytes, 5*1024*1024)
        self.assertTrue(isinstance(logfile, loghandler.RotatingFileHandler))
        logger.removeHandler(logfile)
        logfile.close()

    def test_with_timed_rotating_logfile(self):
        fn = self.mktemp()
        logger = self.check_simple_logger("<eventlog>\n"
                                          "  <logfile>\n"
                                          "    path %s\n"
                                          "    level debug\n"
                                          "    when D\n"
                                          "    old-files 11\n"
                                          "  </logfile>\n"
                                          "</eventlog>" % fn)
        logfile = logger.handlers[0]
        self.assertEqual(logfile.level, logging.DEBUG)
        self.assertEqual(logfile.backupCount, 11)
        self.assertEqual(logfile.interval, 86400)
        self.assertTrue(isinstance(logfile, loghandler.TimedRotatingFileHandler))
        logger.removeHandler(logfile)
        logfile.close()

    def test_with_timed_rotating_logfile(self):
        fn = self.mktemp()
        logger = self.check_simple_logger("<eventlog>\n"
                                          "  <logfile>\n"
                                          "    path %s\n"
                                          "    level debug\n"
                                          "    when D\n"
                                          "    interval 3\n"
                                          "    old-files 11\n"
                                          "  </logfile>\n"
                                          "</eventlog>" % fn)
        logfile = logger.handlers[0]
        self.assertEqual(logfile.level, logging.DEBUG)
        self.assertEqual(logfile.backupCount, 11)
        self.assertEqual(logfile.interval, 86400*3)
        self.assertTrue(isinstance(logfile, loghandler.TimedRotatingFileHandler))
        logger.removeHandler(logfile)
        logfile.close()

    def test_with_timed_rotating_logfile_and_size_should_fail(self):
        fn = self.mktemp()
        self.assertRaises(
            ValueError,
            self.check_simple_logger, "<eventlog>\n"
                                          "  <logfile>\n"
                                          "    path %s\n"
                                          "    level debug\n"
                                          "    max-size 5mb\n"
                                          "    when D\n"
                                          "    old-files 10\n"
                                          "  </logfile>\n"
                                          "</eventlog>" % fn)


    def check_standard_stream(self, name):
        old_stream = getattr(sys, name)
        conf = self.get_config("""
            <eventlog>
              <logfile>
                level info
                path %s
              </logfile>
            </eventlog>
            """ % name.upper())
        self.assertTrue(conf.eventlog is not None)
        # The factory has already been created; make sure it picks up
        # the stderr we set here when we create the logger and
        # handlers:
        sio = StringIO.StringIO()
        setattr(sys, name, sio)
        try:
            logger = conf.eventlog()
        finally:
            setattr(sys, name, old_stream)
        logger.warning("woohoo!")
        self.assertTrue(sio.getvalue().find("woohoo!") >= 0)

    def test_custom_formatter(self):
        old_stream = sys.stdout
        conf = self.get_config("""
        <eventlog>
        <logfile>
        formatter ZConfig.components.logger.tests.test_logger.CustomFormatter
        level info
        path STDOUT
        </logfile>
        </eventlog>
        """)
        sio = StringIO.StringIO()
        sys.stdout = sio
        try:
            logger = conf.eventlog()
        finally:
            sys.stdout = old_stream
        try:
            raise KeyError
        except KeyError:
            logger.exception("testing a KeyError")
        self.assertTrue(sio.getvalue().find("KeyError") >= 0)
        self.assertTrue(sio.getvalue().find("Don't panic") >= 0)

    def test_with_syslog(self):
        import socket
        logger = self.check_simple_logger("<eventlog>\n"
                                          "  <syslog>\n"
                                          "    level error\n"
                                          "    facility local3\n"
                                          "  </syslog>\n"
                                          "</eventlog>")
        syslog = logger.handlers[0]
        self.assertEqual(syslog.level, logging.ERROR)
        self.assertTrue(isinstance(syslog, loghandler.SysLogHandler))
        syslog.close() # avoid ResourceWarning
        try:
            syslog.socket.close() # ResourceWarning under 3.2
        except socket.SocketError:
            pass

    def test_with_http_logger_localhost(self):
        logger = self.check_simple_logger("<eventlog>\n"
                                          "  <http-logger>\n"
                                          "    level error\n"
                                          "    method post\n"
                                          "  </http-logger>\n"
                                          "</eventlog>")
        handler = logger.handlers[0]
        self.assertEqual(handler.host, "localhost")
        # XXX The "url" attribute of the handler is misnamed; it
        # really means just the selector portion of the URL.
        self.assertEqual(handler.url, "/")
        self.assertEqual(handler.level, logging.ERROR)
        self.assertEqual(handler.method, "POST")
        self.assertTrue(isinstance(handler, loghandler.HTTPHandler))

    def test_with_http_logger_remote_host(self):
        logger = self.check_simple_logger("<eventlog>\n"
                                          "  <http-logger>\n"
                                          "    method get\n"
                                          "    url http://example.com/log/\n"
                                          "  </http-logger>\n"
                                          "</eventlog>")
        handler = logger.handlers[0]
        self.assertEqual(handler.host, "example.com")
        # XXX The "url" attribute of the handler is misnamed; it
        # really means just the selector portion of the URL.
        self.assertEqual(handler.url, "/log/")
        self.assertEqual(handler.level, logging.NOTSET)
        self.assertEqual(handler.method, "GET")
        self.assertTrue(isinstance(handler, loghandler.HTTPHandler))

    def test_with_email_notifier(self):
        logger = self.check_simple_logger("<eventlog>\n"
                                          "  <email-notifier>\n"
                                          "    to sysadmin@example.com\n"
                                          "    to sa-pager@example.com\n"
                                          "    from zlog-user@example.com\n"
                                          "    level fatal\n"
                                          "  </email-notifier>\n"
                                          "</eventlog>")
        handler = logger.handlers[0]
        self.assertEqual(handler.toaddrs, ["sysadmin@example.com",
                                           "sa-pager@example.com"])
        self.assertEqual(handler.fromaddr, "zlog-user@example.com")
        self.assertEqual(handler.level, logging.FATAL)

    def test_with_email_notifier_with_credentials(self):
        try:
            logger = self.check_simple_logger("<eventlog>\n"
                                              "  <email-notifier>\n"
                                              "    to sysadmin@example.com\n"
                                              "    from zlog-user@example.com\n"
                                              "    level fatal\n"
                                              "    smtp-username john\n"
                                              "    smtp-password johnpw\n"
                                              "  </email-notifier>\n"
                                              "</eventlog>")
        except ValueError:
            if sys.version_info >= (2, 6):
                # For python 2.6 no ValueError must be raised.
                raise
        else:
            # This path must only be reached with python >=2.6
            self.assertTrue(sys.version_info >= (2, 6))
            handler = logger.handlers[0]
            self.assertEqual(handler.toaddrs, ["sysadmin@example.com"])
            self.assertEqual(handler.fromaddr, "zlog-user@example.com")
            self.assertEqual(handler.fromaddr, "zlog-user@example.com")
            self.assertEqual(handler.level, logging.FATAL)
            self.assertEqual(handler.username, 'john')
            self.assertEqual(handler.password, 'johnpw')

    def test_with_email_notifier_with_invalid_credentials(self):
        self.assertRaises(ValueError,
                          self.check_simple_logger,
                          "<eventlog>\n"
                          "  <email-notifier>\n"
                          "    to sysadmin@example.com\n"
                          "    from zlog-user@example.com\n"
                          "    level fatal\n"
                          "    smtp-username john\n"
                          "  </email-notifier>\n"
                          "</eventlog>")
        self.assertRaises(ValueError,
                          self.check_simple_logger,
                          "<eventlog>\n"
                          "  <email-notifier>\n"
                          "    to sysadmin@example.com\n"
                          "    from zlog-user@example.com\n"
                          "    level fatal\n"
                          "    smtp-password john\n"
                          "  </email-notifier>\n"
                          "</eventlog>")

    def check_simple_logger(self, text, level=logging.INFO):
        conf = self.get_config(text)
        self.assertTrue(conf.eventlog is not None)
        self.assertEqual(conf.eventlog.level, level)
        logger = conf.eventlog()
        self.assertTrue(isinstance(logger, logging.Logger))
        self.assertEqual(len(logger.handlers), 1)
        return logger


class TestReopeningRotatingLogfiles(LoggingTestHelper, unittest.TestCase):

    # These tests should not be run on Windows.

    handler_factory = loghandler.RotatingFileHandler

    _schematext = """
      <schema>
        <import package='ZConfig.components.logger'/>
        <multisection type='logger' name='*' attribute='loggers'/>
      </schema>
    """

    _sampleconfig_template = """
      <logger>
        name  foo.bar
        <logfile>
          path  %(path0)s
          level debug
          max-size 1mb
          old-files 10
        </logfile>
        <logfile>
          path  %(path1)s
          level info
          max-size 1mb
          old-files 3
        </logfile>
        <logfile>
          path  %(path1)s
          level info
          when D
          old-files 3
        </logfile>
      </logger>

      <logger>
        name  bar.foo
        <logfile>
          path  %(path2)s
          level info
          max-size 10mb
          old-files 10
        </logfile>
      </logger>
    """

    def test_filehandler_reopen(self):

        def mkrecord(msg):
            #
            # Python 2.5.0 added an additional required argument to the
            # LogRecord constructor, making it incompatible with prior
            # versions.  Python 2.5.1 corrected the bug by making the
            # additional argument optional.  We deal with 2.5.0 by adding
            # the extra arg in only that case, using the default value
            # from Python 2.5.1.
            #
            args = ["foo.bar", logging.ERROR, __file__, 42, msg, (), ()]
            if sys.version_info[:3] == (2, 5, 0):
                args.append(None)
            return logging.LogRecord(*args)

        # This goes through the reopening operation *twice* to make
        # sure that we don't lose our handle on the handler the first
        # time around.

        fn = self.mktemp()
        h = self.handler_factory(fn)
        h.handle(mkrecord("message 1"))
        nfn1 = self.move(fn)
        h.handle(mkrecord("message 2"))
        h.reopen()
        h.handle(mkrecord("message 3"))
        nfn2 = self.move(fn)
        h.handle(mkrecord("message 4"))
        h.reopen()
        h.handle(mkrecord("message 5"))
        h.close()

        # Check that the messages are in the right files::
        text1 = read_file(nfn1)
        text2 = read_file(nfn2)
        text3 = read_file(fn)
        self.assertTrue("message 1" in text1)
        self.assertTrue("message 2" in text1)
        self.assertTrue("message 3" in text2)
        self.assertTrue("message 4" in text2)
        self.assertTrue("message 5" in text3)

    def test_logfile_reopening(self):
        #
        # This test only applies to the simple logfile reopening; it
        # doesn't work the same way as the rotating logfile handler.
        #
        paths = self.mktemp(), self.mktemp(), self.mktemp()
        d = {
            "path0": paths[0],
            "path1": paths[1],
            "path2": paths[2],
            }
        text = self._sampleconfig_template % d
        conf = self.get_config(text)
        self.assertEqual(len(conf.loggers), 2)
        # Build the loggers from the configuration, and write to them:
        conf.loggers[0]().info("message 1")
        conf.loggers[1]().info("message 2")
        #
        # We expect this to re-open the original filenames, so we'll
        # have six files instead of three.
        #
        loghandler.reopenFiles()
        #
        # Write to them again:
        conf.loggers[0]().info("message 3")
        conf.loggers[1]().info("message 4")
        #
        # We expect this to re-open the original filenames, so we'll
        # have nine files instead of six.
        #
        loghandler.reopenFiles()
        #
        # Write to them again:
        conf.loggers[0]().info("message 5")
        conf.loggers[1]().info("message 6")
        #
        # We should now have all nine files:
        for fn in paths:
            fn1 = fn + ".1"
            fn2 = fn + ".2"
            self.assertTrue(os.path.isfile(fn), "%r must exist" % fn)
            self.assertTrue(os.path.isfile(fn1), "%r must exist" % fn1)
            self.assertTrue(os.path.isfile(fn2), "%r must exist" % fn2)
        #
        # Clean up:
        for logger in conf.loggers:
            logger = logger()
            for handler in logger.handlers[:]:
                logger.removeHandler(handler)
                handler.close()


class TestReopeningLogfiles(TestReopeningRotatingLogfiles):

    handler_factory = loghandler.FileHandler

    _sampleconfig_template = """
      <logger>
        name  foo.bar
        <logfile>
          path  %(path0)s
          level debug
        </logfile>
        <logfile>
          path  %(path1)s
          level info
        </logfile>
      </logger>

      <logger>
        name  bar.foo
        <logfile>
          path  %(path2)s
          level info
        </logfile>
      </logger>
    """

    def test_logfile_reopening(self):
        #
        # This test only applies to the simple logfile reopening; it
        # doesn't work the same way as the rotating logfile handler.
        #
        paths = self.mktemp(), self.mktemp(), self.mktemp()
        d = {
            "path0": paths[0],
            "path1": paths[1],
            "path2": paths[2],
            }
        text = self._sampleconfig_template % d
        conf = self.get_config(text)
        self.assertEqual(len(conf.loggers), 2)
        # Build the loggers from the configuration, and write to them:
        conf.loggers[0]().info("message 1")
        conf.loggers[1]().info("message 2")
        npaths1 = [self.move(fn) for fn in paths]
        #
        # We expect this to re-open the original filenames, so we'll
        # have six files instead of three.
        #
        loghandler.reopenFiles()
        #
        # Write to them again:
        conf.loggers[0]().info("message 3")
        conf.loggers[1]().info("message 4")
        npaths2 = [self.move(fn) for fn in paths]
        #
        # We expect this to re-open the original filenames, so we'll
        # have nine files instead of six.
        #
        loghandler.reopenFiles()
        #
        # Write to them again:
        conf.loggers[0]().info("message 5")
        conf.loggers[1]().info("message 6")
        #
        # We should now have all nine files:
        for fn in paths:
            self.assertTrue(os.path.isfile(fn), "%r must exist" % fn)
        for fn in npaths1:
            self.assertTrue(os.path.isfile(fn), "%r must exist" % fn)
        for fn in npaths2:
            self.assertTrue(os.path.isfile(fn), "%r must exist" % fn)
        #
        # Clean up:
        for logger in conf.loggers:
            logger = logger()
            for handler in logger.handlers[:]:
                logger.removeHandler(handler)
                handler.close()

    def test_filehandler_reopen_thread_safety(self):
        # The reopen method needs to do locking to avoid a race condition
        # with emit calls. For simplicity we replace the "acquire" and
        # "release" methods with dummies that record calls to them.

        fn = self.mktemp()
        h = self.handler_factory(fn)

        calls = []
        h.acquire = lambda: calls.append("acquire")
        h.release = lambda: calls.append("release")

        h.reopen()
        h.close()

        self.assertEqual(calls, ["acquire", "release"])


def test_logger_convenience_function_and_ommiting_name_to_get_root_logger():
    """

The ZConfig.loggers function can be used to configure one or more loggers.
We'll configure the rot logger and a non-root logger.

    >>> old_level = logging.getLogger().getEffectiveLevel()
    >>> old_handler_count = len(logging.getLogger().handlers)

    >>> ZConfig.configureLoggers('''
    ... <logger>
    ...    level INFO
    ...    <logfile>
    ...       PATH STDOUT
    ...       format root %(levelname)s %(name)s %(message)s
    ...    </logfile>
    ... </logger>
    ...
    ... <logger>
    ...    name ZConfig.TEST
    ...    level DEBUG
    ...    <logfile>
    ...       PATH STDOUT
    ...       format test %(levelname)s %(name)s %(message)s
    ...    </logfile>
    ... </logger>
    ... ''')

    >>> logging.getLogger('ZConfig.TEST').debug('test message')
    test DEBUG ZConfig.TEST test message
    root DEBUG ZConfig.TEST test message

    >>> logging.getLogger().getEffectiveLevel() == logging.INFO
    True
    >>> len(logging.getLogger().handlers) == old_handler_count + 1
    True
    >>> logging.getLogger('ZConfig.TEST').getEffectiveLevel() == logging.DEBUG
    True
    >>> len(logging.getLogger('ZConfig.TEST').handlers) == 1
    True

.. cleanup

    >>> logging.getLogger('ZConfig.TEST').setLevel(logging.NOTSET)
    >>> logging.getLogger('ZConfig.TEST').removeHandler(
    ...     logging.getLogger('ZConfig.TEST').handlers[-1])
    >>> logging.getLogger().setLevel(old_level)
    >>> logging.getLogger().removeHandler(logging.getLogger().handlers[-1])


    """

def test_suite():
    suite = unittest.TestSuite()
    suite.addTest(doctest.DocTestSuite())
    suite.addTest(unittest.makeSuite(TestConfig))
    if os.name != "nt":
        # Though log files can be closed and re-opened on Windows, these
        # tests expect to be able to move the underlying files out from
        # underneath the logger while open.  That's not possible on
        # Windows.
        #
        # Different tests are needed that only test that close/re-open
        # operations are performed by the handler; those can be run on
        # any platform.
        suite.addTest(unittest.makeSuite(TestReopeningLogfiles))
        suite.addTest(unittest.makeSuite(TestReopeningRotatingLogfiles))
    return suite

if __name__ == '__main__':
    unittest.main(defaultTest="test_suite")
