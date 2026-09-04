## Copyright (C) 2025-2026 Andreas Bertsatos <abertsatos@biol.uoa.gr>
##
## This file is part of the pkg-octave-doc package for GNU Octave.
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {pkg-octave-doc} {@var{MTHDS} =} get_methods_ordered (@var{class}, @var{MTHDS})
##
## Private function ordering the methods of a class by their appearance in its
## source file.
##
## @var{MTHDS} comes back in the order the file of @var{class} declares them,
## and it is also filtered: a name the file declares no function for is dropped
## rather than kept where it stood.  A method @var{class} inherits is therefore
## removed, being declared in the file of the class it comes from, which is what
## keeps an inherited method out of the documentation while an inherited
## property stays in it.
##
## @end deftypefn

function MTHDS = get_methods_ordered (class, MTHDS);

  ## Get the path to the classdef
  pathname = which (class);

  ## Read source file
  fid = fopen (pathname);
  txt = fscanf (fid, "%c", Inf);
  fclose (fid);

  ## Find the function declarations in the order the file makes them.  A line
  ## is what carries a declaration, so the file is read line by line: one
  ## standing at the first column is a declaration just the same.
  lines = strsplit (strrep (txt, "\r\n", "\n"), "\n");
  index = [];
  for i = 1:numel (lines)
    fcn_line = strtrim (lines{i});
    if (! strncmp (fcn_line, "function ", 9))
      continue;
    endif
    ## Remove input arguments (to avoid input arguments named after a method)
    end_line = strfind (fcn_line, "(");
    if (! isempty (end_line))
      fcn_name = fcn_line(1:end_line(1) - 1);
    else
      fcn_name = fcn_line;
    endif
    ## Remove output arguments (if any) and the "function" tag
    beg_line = strfind (fcn_name, "=");
    if (! isempty (beg_line))
      beg_line = beg_line(1) + 1;
    else
      beg_line = 10;
    endif
    fcn_name = strtrim (fcn_name(beg_line:end));
    ## Search for valid methods
    method_idx = find (strcmp (MTHDS, fcn_name));
    ## Keep only those available in public methods
    if (! isempty (method_idx))
      index = [index, method_idx];
    endif
  endfor

  ## Reorder methods in MTHDS cell array
  MTHDS = MTHDS(index);

endfunction
