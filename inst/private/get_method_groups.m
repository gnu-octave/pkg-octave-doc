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
## @deftypefn  {pkg-octave-doc} {@var{groups} =} get_method_groups (@var{clsname}, @var{MTHDS})
##
## Return the comment-banner method groups of a classdef.
##
## @var{clsname} is a char string with the class name and @var{MTHDS} a cell
## array of its public method names.  @code{get_method_groups} reads the class
## source located by @code{which} and delegates to @code{parse_method_groups}.
##
## @var{groups} is a struct array with fields @qcode{name} and @qcode{methods};
## it is empty when the classdef has no banner blocks (i.e. is not @qcode{
## "large"}).  See @code{parse_method_groups} for the full contract.
##
## @seealso{parse_method_groups, classdef_texi2html}
## @end deftypefn

function groups = get_method_groups (clsname, MTHDS)

  if (nargin != 2 || ! ischar (clsname) || ! iscellstr (MTHDS))
    print_usage ();
  endif

  src = fileread (which (clsname));
  groups = parse_method_groups (src, MTHDS);

endfunction

## The behaviour of this function is tested through classdef_texi2html, the
## public entry point that reaches it: a test block is evaluated in the scope
## of test.m, so it cannot name a private function.
