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
## @deftypefn {pkg-octave-doc} {@var{findings} =} __index_notfound__ (@var{opts}, @var{why})
##
## Private function reporting an @file{INDEX} that was expected and not found.
##
## @var{findings} carries one finding when @var{why} says something and the
## rule is not off, and is empty otherwise.  It is a finding rather than a
## warning so that it is counted, tallied and returned like every other rule:
## a caller reading the report would never see a warning, and this is the one
## thing that silently turns off what decides a whole scope's contents.
##
## @end deftypefn

function findings = __index_notfound__ (opts, why)

  ## Input validation
  if (nargin != 2)
    error ("__index_notfound__: invalid number of input arguments.");
  endif

  findings = struct ('rule', {}, 'severity', {}, 'line', {}, 'message', {}, ...
                     'file', {});
  if (isempty (why) || strcmp (opts.IndexNotFound, 'off'))
    return;
  endif

  file = opts.IndexLocation;
  if (! ischar (file))
    file = 'INDEX';
  endif
  findings(1) = struct ('rule', 'IndexNotFound', ...
                        'severity', opts.IndexNotFound, 'line', 1, ...
                        'message', why, 'file', file);

endfunction
