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
## @deftypefn  {pkg-octave-doc} {@var{PROPS} =} get_properties_ordered (@var{class}, @var{PROPS})
##
## Private function to order properties according to their order of appearance
## in the classdef file.  Properties inherited from a superclass are not
## declared in the file, so they are appended in the order @code{properties}
## reported them.
##
## @end deftypefn

function PROPS = get_properties_ordered (class, PROPS);

  ## Get the path to the classdef
  pathname = which (class);

  ## Read source file
  fid = fopen (pathname);
  txt = fscanf (fid, "%c", Inf);
  fclose (fid);

  ## Find the property declarations in the order the file makes them.  A line
  ## is what carries a declaration, so the file is read line by line, as
  ## get_methods_ordered reads it.  Unlike a method, a property is a bare name
  ## and cannot be told apart from ordinary code, so only the lines standing
  ## between a 'properties' line and its 'endproperties' are read.
  lines = strsplit (strrep (txt, "\r\n", "\n"), "\n");
  index = [];
  inblock = false;
  nbeg = 0;
  nend = 0;
  for i = 1:numel (lines)
    txt_line = strtrim (lines{i});

    ## Block opener: 'properties' alone or carrying attributes
    if (strncmp (txt_line, "properties", 10)
        && (numel (txt_line) == 10 || any (txt_line(11) == " (")))
      nbeg += 1;
      inblock = true;
      continue;
    endif

    ## Block terminator
    if (strncmp (txt_line, "endproperties", 13))
      nend += 1;
      inblock = false;
      continue;
    endif

    if (! inblock)
      continue;
    endif

    ## Split line into words and check the first element.  A '#' or a '%'
    ## opens a comment, so the line declares nothing.
    words = strsplit (txt_line);
    word = words{1};
    if (isempty (word) || any (strcmp (word(1), {'#', '%'})))
      continue;
    endif

    ## Keep only those available in public properties
    prop_idx = find (strcmp (PROPS, word));
    if (! isempty (prop_idx))
      index = [index, prop_idx];
    endif
  endfor

  ## Ensure that properties declaration blocks have been parsed correctly
  if (nbeg != nend)
    warning ("properties in %s classdef file could not be ordered.", class);
    return;
  endif

  ## Reorder properties according to their appearance in the classdef file.
  ## Properties inherited from a superclass are not declared in this file, so
  ## keep them, in the order 'properties' reported them, after those that are.
  ## Scanning only this file would otherwise drop them without warning.
  rest = 1:numel (PROPS);
  rest(index) = [];
  PROPS = PROPS([index, rest]);

endfunction
