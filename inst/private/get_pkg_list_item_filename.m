## Copyright (C) 2009 Carlo de Falco
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

## THIS FUNCTION SHOULD BE private

function pkg_list_item_filename = get_pkg_list_item_filename (name, outdir, section)

  pldir = mk_package_list_dir (outdir, section);
  pkg_list_item_filename = fullfile (pldir, name);
  
endfunction

function pldir = mk_package_list_dir (outdir, section)

  descdir = fullfile (outdir, "short_package_descriptions");
  pldir   = fullfile (descdir, section);

  if (!exist (descdir, "dir"))
    [succ, msg] = mkdir (descdir);
    if (! succ)
      error ("generate_package_html: unable to create directory %s:\n %s", 
	     descdir, msg);
    endif
  endif

  if (!exist (pldir, "dir"))
    [succ, msg] = mkdir (pldir);
    if (! succ)
      error ("generate_package_html: unable to create directory %s:\n %s", 
	     pldir, msg);
    endif
  endif

endfunction

