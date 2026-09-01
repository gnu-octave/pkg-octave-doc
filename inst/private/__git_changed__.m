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
## @deftypefn {pkg-octave-doc} {@var{files} =} __git_changed__ (@var{caller}, @var{dirpath})
##
## Private function listing the files @code{git} reports as changed.
##
## @var{files} holds the absolute path of every file that differs from
## @code{HEAD}, staged and unstaged alike, together with the untracked ones,
## since a function written but never committed is invisible to a diff and
## would otherwise be missing from its first commit.  A file that was deleted
## is listed too, its entries being what has to go.
##
## A directory that is not inside a repository stops the run rather than
## quietly rebuilding everything, since a caller asking for the changed files
## alone would otherwise be answered with silence.
##
## @end deftypefn

function files = __git_changed__ (caller, dirpath)

  ## Input validation
  if (nargin != 2)
    error ("__git_changed__: invalid number of input arguments.");
  endif

  files = {};
  [status, out] = system (sprintf ('git -C "%s" rev-parse --show-toplevel', ...
                                   dirpath));
  if (status != 0)
    error (strcat ("%s: '%s' is not inside a git repository, so the", ...
                   " changed files cannot be found."), caller, dirpath);
  endif
  root = strtrim (out);

  [status, out] = system (sprintf ('git -C "%s" status --porcelain -uall', ...
                                   root));
  if (status != 0)
    error ("%s: git could not report what changed in '%s'.", caller, root);
  endif

  lines = strsplit (strrep (out, "\r\n", "\n"), "\n", ...
                    'CollapseDelimiters', false);
  for ii = 1:numel (lines)
    ln = lines{ii};
    if (numel (ln) < 4)
      continue;
    endif
    path = ln(4:end);
    ## A rename is reported as its old name, an arrow, and its new one
    arrow = strfind (path, ' -> ');
    if (! isempty (arrow))
      files{end+1} = fullfile (root, strtrim (path(1:arrow(end)-1)));
      path = path(arrow(end)+4:end);
    endif
    path = strtrim (path);
    if (! isempty (path) && path(1) == '"' && path(end) == '"')
      path = path(2:end-1);              # git quotes an unusual name
    endif
    if (! isempty (path))
      files{end+1} = fullfile (root, path);
    endif
  endfor

endfunction
