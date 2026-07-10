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
## @deftypefn {pkg-octave-doc} {} __reset_classes__ ()
##
## Reset the interpreter's classdef state between demos.
##
## Evaluating a DEMO can leave Octave's classdef dispatch corrupted for the rest
## of the process: for example, invoking a classdef constructor through a
## function handle (@code{@@Class}, or @code{cellfun (@@Class, @dots{})}) can make
## every later construction of that class fail from inside its own constructor
## with a spurious @qcode{subsasgn} error.  Because @code{build_DEMOS} evaluates
## all of a function's demos in one process, such a demo would poison every demo
## that follows it.  @code{clear classes} clears that state; running it from this
## isolated helper resets the class definitions without disturbing the caller's
## workspace (@code{clear classes} wipes the local variables of the frame it runs
## in, so it must not be called directly inside @code{build_DEMOS}).
##
## The underlying Octave core bug is tracked at
## @url{https://octave.discourse.group/t/octave-core-classdef-dispatch-bug/7633}.
## Minimal reproducer: @code{f = @@categorical; f (@{'a';'b'@}); categorical
## (@{'c';'d'@})} errors from inside the constructor.  Remove this workaround once
## that bug is fixed upstream.
##
## @seealso{build_DEMOS, __eval_demo__}
## @end deftypefn

function __reset_classes__ ()

  clear classes;

endfunction
