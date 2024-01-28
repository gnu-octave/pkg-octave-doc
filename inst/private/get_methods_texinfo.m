## Copyright (C) 2024 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefn  {pkg-octave-doc} {@var{text} =} get_methods_help_text (@var{class}, @var{method})
##
## Private function to parse a method texinfo from a classdef file.
##
## @end deftypefn

function text = get_methods_texinfo (class, method);

  ## Get the path to the classdef
  pathname = which (class);

  ## Read source file
  fid = fopen (pathname);
  txt = fscanf (fid, "%c", Inf);
  fclose (fid);

  ## Find texinfo blocks
  txt_beg = strfind (txt, "## @deftypefn ");
  txt_end = strfind (txt, "## @end deftypefn");

  if (numel (txt_beg) != numel (txt_end))
    warning ("get_methods_texinfo: texinfo blocks not properly terminated.");
    text = "";
    return;
  endif

  ## Search texinfo block for given method
  method_found = false;
  for i = 1:numel (txt_beg)
    textblock = txt([txt_beg(i):txt_end(i)+16]);
    firstline = textblock([1:strfind(textblock,"\n")(1)-1]);
    if (! isempty (strfind (firstline, method)))
      helptext = textblock;
      method_found = true;
    endif
  endfor

  if (method_found)
    ## Remove '##' and leading spaces from each line
    nl_idx = strfind (helptext, "\n");
    begidx = 1;
    endidx = length (helptext);
    if (nl_idx(end) < endidx)
      nl_idx = [nl_idx, endidx];
    endif
    text = "\n";
    for i = 1:numel (nl_idx)
      txt_line = helptext([begidx:nl_idx(i)]);
      txt_line(strfind (txt_line, "#")) = [];
      txt_line = strtrim (txt_line);
      begidx = nl_idx(i) + 1;
      text = sprintf ("%s%s\n", text, txt_line);
    endfor
  else
    text = "";
  endif

endfunction
