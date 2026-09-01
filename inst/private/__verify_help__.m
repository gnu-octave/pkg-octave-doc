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
## @deftypefn {pkg-octave-doc} {} __verify_help__ (@var{caller}, @var{name}, @var{srcfile}, @var{text}, @var{srclines})
##
## Private function proving a help text came from the file on disk.
##
## A definition the interpreter is holding does not change when its file is
## edited, so a maintainer running one of these functions in the session where
## a docstring was written would otherwise cache the previous text.
## @code{clear functions} restores the definitions, and this checks that it
## took: a distinctive run of the docstring in @var{srclines} must appear in
## @var{text}, or the run stops rather than write something false.
##
## Nothing is checked when there is nothing to compare against, which is the
## case for a compiled function, whose docstring lives only in its
## @file{.oct}, and for an inherited property, whose text belongs to another
## file entirely.
##
## @end deftypefn

function __verify_help__ (caller, name, srcfile, text, srclines)

  ## Input validation
  if (nargin != 5)
    error ("__verify_help__: invalid number of input arguments.");
  endif

  if (isempty (text) || isempty (srclines))
    return;
  endif

  ## The longest plain line of the docstring, markup left out so that what is
  ## compared survives rendering unchanged
  best = '';
  for ii = 1:numel (srclines)
    ln = strtrim (regexprep (srclines{ii}, '^\s*##\s?', ''));
    if (numel (ln) > numel (best) && isempty (strfind (ln, '@')))
      best = ln;
    endif
  endfor
  if (numel (best) < 12)
    return;
  endif

  if (isempty (strfind (text, best)))
    error (strcat ("%s: the help text of '%s' is not the one in '%s';", ...
                   " the definition did not reload."), caller, name, srcfile);
  endif

endfunction
