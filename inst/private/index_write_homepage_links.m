## Copyright (C) 2016 Julien Bect <jbect@users.sourceforge.net>
## Copyright (C) 2016 Fernando Pujaico Rivera <fernando.pujaico.rivera@gmail.com>
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

function index_write_homepage_links (fid, url_list)

## Process url list
C = strsplit (url_list, ",");
C = cellfun (@strtrim, C, 'UniformOutput', false);
L = length (C);

for k = 1:L

  fprintf (fid, "  <tr>\n");
  fprintf (fid, "    <td>\n");
  fprintf (fid, "      <a href=\"%s\" class=\"homepage_link\">\n", C{k});  
  fprintf (fid, "        <img src=\"../homepage.png\" alt=\"Package homepage icon\"/>\n");
  fprintf (fid, "      </a>\n");
  fprintf (fid, "    </td>\n");
  fprintf (fid, "    <td>\n");  
  fprintf (fid, "      <a href=\"%s\" class=\"homepage_link\">\n", C{k});

  if L == 1
    fprintf (fid, "        Homepage\n");
  else
    fprintf (fid, "        Homepage #%d\n", k);
  endif

  fprintf (fid, "      </a>\n");
  fprintf (fid, "    </td>\n");
  fprintf (fid, "  </tr>\n");  

  endfor

endfunction
