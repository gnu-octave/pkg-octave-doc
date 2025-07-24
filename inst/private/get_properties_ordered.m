## Copyright (C) 2025 Andreas Bertsatos <abertsatos@biol.uoa.gr>
##
## This file is part of the statistics package for GNU Octave.
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
## in the classdef file.
##
## @end deftypefn

function PROPS = get_properties_ordered (class, PROPS);

  ## Get the path to the classdef
  pathname = which (class);

  ## Read source file
  fid = fopen (pathname);
  txt = fscanf (fid, "%c", Inf);
  fclose (fid);

  ## Find lines with properties declarations
  prop_beg = strfind (txt, "properties");
  prop_end = strfind (txt, "endproperties");
  endline = strfind (txt, "\n");
  pbeg_idx = [];
  for ii = 1:numel (prop_beg)
    ## Get text line for each occurence of "properties"
    pbeg_line_beg = endline(find (endline < prop_beg(ii), 1, "last")) + 1;
    pbeg_line_end = endline(find (endline > prop_beg(ii), 1, "first")) - 1;
    pbeg_line = txt(pbeg_line_beg:pbeg_line_end);
    ## Remove any leading spaces and check if line corresponds to a
    ## valid function declaration (it should start with "properties "
    pbeg_line = strtrim (pbeg_line);
    if (strncmp (pbeg_line, "properties ", 10))
      ## Save index of first line after the 'properties' declaration line
      pbeg_idx = [pbeg_idx, pbeg_line_end+2];
    endif
  endfor
  pend_idx = [];
  for ii = 1:numel (prop_end)
    ## Get text line for each occurence of "endproperties"
    pend_line_beg = endline(find (endline < prop_end(ii), 1, "last")) + 1;
    pend_line_end = endline(find (endline > prop_end(ii), 1, "first")) - 1;
    pend_line = txt(pend_line_beg:pend_line_end);
    ## Remove any leading spaces and check if line corresponds to a
    ## valid function declaration (it should start with "properties "
    pend_line = strtrim (pend_line);
    if (strncmp (pend_line, "endproperties ", 13))
      ## Save index of first line after the 'properties' declaration line
      pend_idx = [pend_idx, pend_line_end+2];
    endif
  endfor

  ## Ensure that properties declaration blocks have been parsed correctly
  if (numel (pbeg_idx) != numel (pend_idx))
    warning ("properties in %s classdef file could not be ordered.", class);
    return
  endif

  ## Merge blocks of properties declariations
  pb_txt = '';
  for ii = 1:numel (pbeg_idx)
    btxt = txt(pbeg_idx(ii):pend_idx(ii));
    pb_txt = [pb_txt, btxt];
  endfor

  ## Scan the block line by line
  end_line = strfind (pb_txt, "\n");
  start_line = 1;
  index = [];
  for ii = 1:numel (end_line)
    txt_line = pb_txt(start_line:end_line(ii)-1);
    start_line = end_line(ii) + 1;
    ## Remove leading spaces
    txt_line = strtrim (txt_line);
    ## Split line into words and check the first element.
    ## If first character is '#' or '%' then it is a comment line,
    ## otherwise it is property name
    word = strsplit (txt_line){1};
    if (! isempty (word))     # empty lines
      if (! any (strcmp (word(1), {'#', '%'})))   # comment lines
        ## This is a property name
        ## Search for valid property
        prop_idx = find (strcmp (PROPS, word));
        ## Keep only those available in public methods
        if (! isempty (prop_idx))
          index = [index, prop_idx];
        endif
      endif
    endif
  endfor

  ## Reorder methods in MTDS cell array
  PROPS = PROPS(index);

endfunction
