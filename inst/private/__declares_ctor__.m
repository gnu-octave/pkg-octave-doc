## Copyright (C) 2026 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefn {pkg-octave-doc} {@var{tf} =} __declares_ctor__ (@var{srcfile}, @var{stem})
##
## Private function reporting whether a classdef file declares its constructor.
##
## @var{tf} is true when @var{srcfile} carries a function declaration named
## @var{stem}, which is the name of the class without its namespace.  The file
## is what answers the question rather than @code{methods}, since a constructor
## declared in a @code{Hidden} or private block is documented and cached while
## @code{methods} does not report it at all.
##
## @end deftypefn

function tf = __declares_ctor__ (srcfile, stem)

  ## Input validation
  if (nargin != 2)
    error ("__declares_ctor__: invalid number of input arguments.");
  endif

  tf = false;
  lines = strsplit (strrep (fileread (srcfile), "\r\n", "\n"), "\n");
  pat = '^function\s+(?:\[[^\]]*\]\s*=\s*|[\w.]+\s*=\s*)?([A-Za-z]\w*)';
  for ii = 1:numel (lines)
    tok = regexp (strtrim (lines{ii}), pat, 'tokens', 'once');
    if (! isempty (tok) && strcmp (tok{1}, stem))
      tf = true;
      return;
    endif
  endfor

endfunction
