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
## @deftypefn  {pkg-octave-doc} {@var{html} =} __demo_notebook__ (@var{block}, @var{imgprefix}, @var{imgbase})
##
## Render a single DEMO block as notebook-style HTML.
##
## @var{block} is the source of one DEMO block, @var{imgprefix} the file-name
## prefix for figures saved under @qcode{assets/}, and @var{imgbase} the
## starting figure number.  The block is evaluated cell by cell by
## @code{__eval_demo__} and laid out by @code{__demo_html__}, producing an
## interleaved sequence of prose, input, output, and figure boxes.
##
## This is the shared primitive used by @code{build_DEMOS} and
## @code{classdef_texi2html} so that every demo renders identically.
##
## @seealso{__eval_demo__, __demo_html__, __demo_segments__, __demo_markdown__}
## @end deftypefn

function html = __demo_notebook__ (block, imgprefix, imgbase)

  if (nargin != 3 || ! ischar (block) || ! ischar (imgprefix))
    print_usage ();
  endif

  cells = __eval_demo__ (block, imgprefix, imgbase);
  html = __demo_html__ (cells);

endfunction

%!error <Invalid call> __demo_notebook__ ()
%!error <Invalid call> __demo_notebook__ ("x = 1")
%!error <Invalid call> __demo_notebook__ (1, "p", 100)
