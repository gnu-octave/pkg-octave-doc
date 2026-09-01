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
## @deftypefn {pkg-octave-doc} {} __show_findings__ (@var{findings}, @var{opts}, @var{label})
##
## Private function printing findings and a tally per rule.
##
## @code{Verbosity} decides how much appears: @qcode{'all'} prints every
## finding and then the tally, @qcode{'summary'} prints the tally alone, and
## @qcode{'none'} prints nothing.  @var{label} names what was examined, and is
## printed when nothing was found so that a quiet run says so rather than
## nothing at all.
##
## @end deftypefn

function __show_findings__ (findings, options, label)
  if (strcmp (options.Verbosity, 'none'))
    return;
  endif
  if (strcmp (options.Verbosity, 'all'))
    for ii = 1:numel (findings)
      printf ('%s:%d: %s: %s (%s)\n', findings(ii).file, findings(ii).line, ...
              findings(ii).severity, findings(ii).message, findings(ii).rule);
    endfor
  endif
  if (isempty (findings))
    printf ('%s: nothing found.\n', label);
    return;
  endif
  rules = unique ({findings.rule});
  parts = cell (1, numel (rules));
  for ii = 1:numel (rules)
    n = sum (strcmp ({findings.rule}, rules{ii}));
    parts{ii} = sprintf ('%s %d', rules{ii}, n);
  endfor
  printf ('%d findings: %s\n', numel (findings), strjoin (parts, ', '));
endfunction
