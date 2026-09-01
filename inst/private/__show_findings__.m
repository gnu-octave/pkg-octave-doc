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
## @deftypefn {pkg-octave-doc} {} __show_findings__ (@var{findings}, @var{opts}, @var{label}, @var{examined}, @var{noun})
##
## Private function printing findings and a tally per rule.
##
## @code{Verbosity} decides how much appears: @qcode{'all'} prints every
## finding and then the summary, @qcode{'summary'} prints the summary alone,
## and @qcode{'none'} prints nothing.
##
## @var{label} names what was examined, @var{examined} counts what was read
## and @var{noun} is the plural word for it, so that a run says what it did
## and not merely what it found: a run that read nothing says so, which is a
## different answer from one that read a great deal and had nothing to
## report.  Each route counts what it actually handles, which is files for a
## run over a tree and help texts for one driven by a package's index.
##
## @end deftypefn

function __show_findings__ (findings, options, label, examined, noun)

  ## Input validation
  if (nargin != 5)
    error ("__show_findings__: invalid number of input arguments.");
  endif

  if (strcmp (options.Verbosity, 'none'))
    return;
  endif
  if (strcmp (options.Verbosity, 'all'))
    for ii = 1:numel (findings)
      printf ('%s:%d: %s: %s (%s)\n', findings(ii).file, findings(ii).line, ...
              findings(ii).severity, findings(ii).message, findings(ii).rule);
    endfor
  endif
  if (examined == 0)
    printf ('%s: checked no %s, there is nothing here to check.\n', label, ...
            noun);
    return;
  endif
  if (examined == 1 && noun(end) == 's')
    noun = noun(1:end-1);
  endif
  if (isempty (findings))
    printf ('%s: checked %d %s, found 0 issues to report.\n', label, ...
            examined, noun);
    return;
  endif
  rules = unique ({findings.rule});
  parts = cell (1, numel (rules));
  for ii = 1:numel (rules)
    n = sum (strcmp ({findings.rule}, rules{ii}));
    parts{ii} = sprintf ('%s %d', rules{ii}, n);
  endfor
  if (numel (findings) == 1)
    word = 'issue';
  else
    word = 'issues';
  endif
  printf ('%s: checked %d %s, found %d %s: %s.\n', label, examined, noun, ...
          numel (findings), word, strjoin (parts, ', '));
endfunction
