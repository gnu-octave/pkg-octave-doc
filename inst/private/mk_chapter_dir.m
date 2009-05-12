## Copyright (C) 2008 Soren Hauberg
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

function location = mk_chapter_dir (outdir, options)
  if (isfield (options, "chapter_dir"))
    location = options.chapter_dir;
  else
    location = "chapter";
  endif
  
  location = fullfile (outdir, location);
  
  ## Create output directory if needed
  if (!exist (location, "dir"))
    mkdir (location);
  endif

endfunction