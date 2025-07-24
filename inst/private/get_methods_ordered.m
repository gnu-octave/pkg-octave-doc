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
## @deftypefn  {pkg-octave-doc} {@var{MTHDS} =} get_methods_ordered (@var{class}, @var{MTHDS})
##
## Private function to order methods according to their order of appearance in
## the classdef file.
##
## @end deftypefn

function MTHDS = get_methods_ordered (class, MTHDS);

  ## Get the path to the classdef
  pathname = which (class);

  ## Read source file
  fid = fopen (pathname);
  txt = fscanf (fid, "%c", Inf);
  fclose (fid);

  ## Find lines with function declarations
  fcn_beg = strfind (txt, " function ");
  endline = strfind (txt, "\n");
  fcn_beg = [fcn_beg, fcn_beg(end)];
  index = [];
  for i = 1:numel (fcn_beg) - 1
    ## Get text line for each occurence of "function"
    fcn_idx = fcn_beg(i);
    fcn_line_beg = endline(find (endline < fcn_beg(i), 1, "last")) + 1;
    fcn_line_end = endline(find (endline > fcn_beg(i), 1, "first")) - 1;
    fcn_line = txt(fcn_line_beg:fcn_line_end);
    ## Remove any leading spaces and check if line corresponds to a
    ## valid function declaration (it should start with "function "
    fcn_line = strtrim (fcn_line);
    if (strncmp (fcn_line, "function ", 9))
      ## Remove input arguments (to avoid input arguments named after a method)
      end_line = strfind (fcn_line, "(");
      if (! isempty (end_line))
        end_line = end_line(1) - 1;
        fcn_name = fcn_line(1:end_line);
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
      fcn_name = fcn_name(beg_line:end);
      fcn_name = strtrim (fcn_name);
      ## Search for valid methods
      method_idx = find (strcmp (MTHDS, fcn_name));
      ## Keep only those available in public methods
      if (! isempty (method_idx))
        index = [index, method_idx];
      endif
    endif
  endfor

  ## Reorder methods in MTHDS cell array
  MTHDS = MTHDS(index);

endfunction
