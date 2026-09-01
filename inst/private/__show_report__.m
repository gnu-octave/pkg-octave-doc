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
## @deftypefn {pkg-octave-doc} {} __show_report__ (@var{report}, @var{opts})
##
## Private function printing what a run did and what it found.
##
## Each finding is printed with the file and the line it came from, followed
## by a count of what changed and a tally per rule.  @code{Verbosity} decides
## how much of that appears: @qcode{'all'} prints every finding and then the
## summary, @qcode{'summary'} prints the summary alone, and @qcode{'none'}
## prints nothing.  The findings are in the report at every setting, so the
## quietest one hides nothing from a caller that asked for them.
##
## @end deftypefn

function __show_report__ (report, opts)

  ## Input validation
  if (nargin != 2)
    error ("__show_report__: invalid number of input arguments.");
  endif

  if (strcmp (opts.Verbosity, 'none'))
    return;
  endif

  f = report.findings;
  if (strcmp (opts.Verbosity, 'all'))
    for ii = 1:numel (f)
      printf ('%s:%d: %s: %s (%s)\n', f(ii).file, f(ii).line, ...
              f(ii).severity, f(ii).message, f(ii).rule);
    endfor
  endif

  printf ('%s: %d added, %d updated, %d removed\n', report.cache, ...
          numel (report.added), numel (report.updated), ...
          numel (report.removed));

  if (isempty (f))
    return;
  endif

  ## A tally per rule, so that a long run ends with something readable
  rules = unique ({f.rule});
  parts = cell (1, numel (rules));
  for ii = 1:numel (rules)
    n = sum (strcmp ({f.rule}, rules{ii}));
    parts{ii} = sprintf ('%s %d', rules{ii}, n);
  endfor
  printf ('%d findings: %s\n', numel (f), strjoin (parts, ', '));

endfunction
