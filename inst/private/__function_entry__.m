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
## @deftypefn {pkg-octave-doc} {[@var{rows}, @var{findings}] =} __function_entry__ (@var{caller}, @var{name}, @var{srcfile}, @var{opts}, @var{pkgname})
##
## Private function building the doc-cache entry of one function.
##
## @var{rows} is the @math{3x1} cell array the cache keeps for the function,
## and is empty when the function carries no texinfo help, which is reported
## rather than written.  @var{findings} carries what was found while the help
## text was read, each with the file it came from.
##
## @var{caller} names the public function to blame in an error message, since
## a help text that did not reload stops a run wherever it was started from.
##
## @end deftypefn

function [rows, findings] = __function_entry__ (caller, name, srcfile, opts, ...
                                                pkgname)

  ## Input validation
  if (nargin != 5)
    error ("__function_entry__: invalid number of input arguments.");
  endif

  rows = {};
  findings = struct ('rule', {}, 'severity', {}, 'line', {}, 'message', {}, ...
                     'file', {});

  ## A compiled help text lives inside the built file and nowhere else, so a
  ## missing or stale one would be cached as it was at the last build, which is
  ## worse than saying so
  if (numel (srcfile) > 4 && strcmp (srcfile(end-3:end), '.oct'))
    cc = [srcfile(1:end-4) '.cc'];
    if (! exist (srcfile, 'file'))
      error ("%s: '%s' has not been built.", caller, srcfile);
    endif
    if (exist (cc, 'file'))
      a = dir (srcfile);
      b = dir (cc);
      if (a.datenum < b.datenum)
        error (strcat ("%s: '%s' is older than its source, build the", ...
                       " package first."), caller, srcfile);
      endif
    endif
  endif

  [text, format] = get_help_text (name);
  if (isempty (text) || ! strcmp (format, 'texinfo'))
    if (! strcmp (opts.MissingDocstring, 'off'))
      msg = sprintf ("'%s' carries no texinfo help", name);
      findings(end+1) = struct ('rule', 'MissingDocstring', ...
                                'severity', opts.MissingDocstring, ...
                                'line', 1, 'message', msg, 'file', srcfile);
    endif
    return;
  endif

  srclines = __help_block__ (srcfile);
  __verify_help__ (caller, name, srcfile, text, srclines);

  [rows, found] = __cache_rows__ (name, text, opts);
  if (! isempty (srclines))
    ctx = struct ('package', pkgname, 'class', '', 'member', '');
    found = [found, __source_lint__(srclines, opts, ctx)];
  endif
  for ii = 1:numel (found)
    found(ii).file = srcfile;
  endfor
  if (! isempty (found))
    findings = [findings, found];
  endif

endfunction
