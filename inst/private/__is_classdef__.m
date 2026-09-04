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
## @deftypefn {pkg-octave-doc} {@var{tf} =} __is_classdef__ (@var{srcfile})
##
## Private function reporting whether a source file declares a classdef.
##
## @var{tf} is true when @var{srcfile} is an @file{.m} file carrying a
## @code{classdef} keyword at the head of a line.  The source is what decides
## and not @code{methods}, which answers for an old style class as well: such a
## class carries no properties at all, and its constructor and its methods are
## @file{INDEX} entries of their own, documented as functions.
##
## A name that resolves to nothing, to a compiled file or to anything that
## cannot be read is not a classdef.  Nothing is evaluated.
##
## @end deftypefn

function tf = __is_classdef__ (srcfile)

  ## Input validation
  if (nargin != 1)
    error ("__is_classdef__: invalid number of input arguments.");
  endif

  tf = false;

  ## Only a classdef source can carry methods; anything else, a compiled
  ## function above all, is not worth reading and would not parse as text.
  if (! (ischar (srcfile) && isrow (srcfile)) || numel (srcfile) < 3
      || ! strcmp (srcfile(end-1:end), ".m"))
    return;
  endif

  try
    txt = fileread (srcfile);
  catch
    return;
  end_try_catch

  ## The classdef keyword is ASCII, and a source file carrying a byte that is
  ## not valid UTF-8 makes regexp refuse the whole string, so drop them first.
  txt(txt > 127) = " ";
  tf = ! isempty (regexp (txt, '^\s*classdef\s', "once", "lineanchors"));

endfunction
