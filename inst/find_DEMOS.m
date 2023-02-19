## Copyright (C) 2023 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefn  {pkg-octave-doc} {@var{demos} =} find_DEMOS (@var{fcnname})
##
## Retrieve DEMO blocks from a particular function.
##
## @seealso{function_texi2html, find_GHurls}
## @end deftypefn

function demos = find_DEMOS (fcnname)

  if (nargin != 1)
    print_usage ();
  endif

  if (! ischar (fcnname))
    print_usage ();
  endif

  ## Get demos from function and store them separately in cell array
  demos = {};
  [code, idx] = test (fcnname, "grabdemo");

  if (idx > 0)
    for i = 1:length (idx) - 1
      block = code(idx(i):idx(i+1)-1);
      demos = [demos; sprintf("%s\n", block)];
    endfor
  endif

endfunction

%!error find_DEMOS ()
%!error find_DEMOS (1)
%!error find_DEMOS ("function_texi2html", 1)

