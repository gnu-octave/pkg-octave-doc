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
## @deftypefn  {pkg-octave-doc} {@var{text} =} get_text_first_sentence (@var{text})
##
## Private function to grab the first sentence from help text returned from
## @code{__texi2html__} function.
##
## @end deftypefn

function text = get_text_first_sentence (text);

  ## Get indices to first paragraph
  fs_beg = strfind (text, "<p>");
  fs_end = strfind (text, "</p>");

  if (! isempty (fs_beg) && ! isempty (fs_end))
    fs_beg = fs_beg(1) + 4;
    fs_end = fs_end(1) - 2;
    text = text(fs_beg:fs_end);
  else
    text = "";
  endif

endfunction
