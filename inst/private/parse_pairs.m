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
## @deftypefn  {pkg-octave-doc} {@var{opts} =} parse_pairs (@var{names}, @var{defaults}, @var{args})
## @deftypefnx {pkg-octave-doc} {[@var{opts}, @var{rest}] =} parse_pairs (@var{names}, @var{defaults}, @var{args})
##
## Parse optional Name/Value paired arguments.
##
## @var{names} is a cell array of character vectors naming the recognized
## options and @var{defaults} a cell array of the same size holding their
## default values.  @var{args} is the @code{varargin} of the calling function.
##
## The returned @var{opts} is a scalar structure with one field per @var{names}
## entry, carrying either the value found in @var{args} or its default.  Option
## names are matched case insensitively, and an option given more than once
## takes the value of its last occurrence, as in MATLAB.
##
## The optional second output, @var{rest}, returns the elements of @var{args}
## that were not consumed as a Name/Value pair, so that a caller can handle its
## own positional arguments and reject whatever it does not recognize.
##
## Adding an option to a function is therefore a matter of extending
## @var{names} and @var{defaults} at its single call site.
##
## @end deftypefn

function [opts, rest] = parse_pairs (names, defaults, args)

  if (nargin != 3)
    print_usage ();
  endif

  opts = cell2struct (defaults(:), names(:), 1);
  found = false (numel (names), 1);

  ## Scan from the back, where the pairs are, so that a leading positional
  ## argument is never matched against an option name.
  for i = numel (args)-1:-1:1
    ## A pair consumed further back has shortened ARGS, so this position may no
    ## longer hold a value to pair with.
    if (i + 1 > numel (args) || ! ischar (args{i}))
      continue;
    endif
    idx = find (strcmpi (args{i}, names));
    if (isempty (idx))
      continue;
    endif
    ## The scan runs backwards, so the last occurrence is reached first and an
    ## earlier one is consumed without overwriting the value already taken.
    if (! found(idx))
      opts.(names{idx}) = args{i+1};
      found(idx) = true;
    endif
    args(i:i+1) = [];
  endfor

  rest = args;

endfunction
