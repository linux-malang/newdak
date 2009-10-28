#!/usr/bin/env python
# vim:set et sw=4:

"""
Simple summary class for dak

@contact: Debian FTP Master <ftpmaster@debian.org>
@copyright: 2001 - 2006 James Troup <james@nocrew.org>
@copyright: 2009  Joerg Jaspert <joerg@debian.org>
@license: GNU General Public License version 2 or later
"""

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

###############################################################################

from singleton import Singleton

###############################################################################

class SummaryStats(Singleton):
    def __init__(self, *args, **kwargs):
        super(SummaryStats, self).__init__(*args, **kwargs)

    def _startup(self):
        self.reset_accept()

    def reset_accept(self):
        self.accept_count = 0
        self.accept_bytes = 0

