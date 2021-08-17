## Copyright (C) 2008 Soren Hauberg <soren@hauberg.org>
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

function expanded = html_see_also_with_prefix (prefix, varargin)
  header = "@html\n<div class=\"seealso\">\n<b>See also</b>: ";
  footer = "\n</div>\n@end html\n";

  format = sprintf (" <a href=\"%s%%s.html\">%%s</a> ", prefix);

  varargin2 = cell (1, 2*length (varargin));
  varargin2 (1:2:end) = varargin;
  varargin2 (2:2:end) = varargin;

  list = sprintf (format, varargin2{:});

  expanded = strcat (header, list, footer);
endfunction
