##############################################################################
#
# Copyright (c) 2001, 2002 Zope Foundation and Contributors.
# All Rights Reserved.
#
# This software is subject to the provisions of the Zope Public License,
# Version 2.1 (ZPL).  A copy of the ZPL should accompany this distribution.
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY AND ALL EXPRESS OR IMPLIED
# WARRANTIES ARE DISCLAIMED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF TITLE, MERCHANTABILITY, AGAINST INFRINGEMENT, AND FITNESS
# FOR A PARTICULAR PURPOSE
#
##############################################################################

import os
import errno
import logging
logger = logging.getLogger("zc.lockfile")

class LockError(Exception):
    """Couldn't get a lock
    """

try:
    import fcntl
except ImportError:
        def _lock_file(file):
            raise TypeError('No file-locking support on this platform')
        def _unlock_file(file):
            raise TypeError('No file-locking support on this platform')
else:
    # Unix
    def _lock_file(file):
    	if os.path.exists(file):
		fp = open(file, 'r')
		lockpid = fp.read().strip()[:20]
		fp.close()
		pids = [pid for pid in os.listdir('/proc') if pid.isdigit()]
		if lockpid in pids:
			raise LockError("Couldn't lock %r" % file)
	fp = open(file, 'w')
	fp.write(" %s\n" % os.getpid())
	fp.flush()
	fp.close()

    def _unlock_file(file):
        fp = open(file, 'w')
	fp.close()


class LockFile:

    _path = None

    def __init__(self, path):
        self._path = path
        try:
            _lock_file(path)
        except:
            logger.exception("Error locking file %s", path)
            raise

    def close(self):
            _unlock_file(self._path)
