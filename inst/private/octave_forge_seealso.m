## Copyright (C) 2009 Soren Hauberg
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

function expanded = octave_forge_seealso (arg)
  header = "@html\n<div class=\"seealso\">\n<b>See also</b>: ";
  footer = "\n</div>\n@end html\n";
  
  format = " <a href=\"../../find_function.php?fun=%s\">%s</a> ";
  
  arg2 = cell (1, 2*length (arg));
  arg2 (1:2:end) = arg;
  arg2 (2:2:end) = arg;
  
  list = sprintf (format, arg2 {:});
  
  expanded = strcat (header, list, footer);
endfunction
