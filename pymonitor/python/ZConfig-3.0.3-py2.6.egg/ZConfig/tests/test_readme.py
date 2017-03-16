##############################################################################
#
# Copyright (c) 2009 Zope Foundation and Contributors.
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
import doctest
import logging


options = doctest.REPORT_NDIFF | doctest.ELLIPSIS

old = {}
def setUp(test):
    global old
    logger = logging.getLogger()
    old['level'] = logger.level
    old['handlers'] = logger.handlers[:]

def tearDown(test):
    logger = logging.getLogger()
    logger.level = old['level']
    logger.handlers = old['handlers']

def test_suite():
    return doctest.DocFileSuite(
        '../../README.txt',
        optionflags=options,
        setUp=setUp, tearDown=tearDown,
        )
