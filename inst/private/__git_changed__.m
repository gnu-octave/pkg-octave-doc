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
## @deftypefn {pkg-octave-doc} {[@var{files}, @var{why}] =} __git_changed__ (@var{dirpath})
##
## Private function listing the files @code{git} reports as changed.
##
## @var{files} holds the absolute path of every file that differs from
## @code{HEAD}, staged and unstaged alike, together with the untracked ones,
## since a function written but never committed is invisible to a diff and
## would otherwise be missing from its first commit.  A file that was deleted
## is listed too, its entries being what has to go.
##
## @var{why} says why the question could not be answered, and is empty when it
## was.  Neither @code{git} being absent nor the tree not being a repository
## is an error: a caller asking for the changed files alone is told that it
## cannot have them, and rebuilds everything instead, which is right rather
## than merely lenient, since the alternative is refusing to do work that is
## perfectly possible.
##
## @end deftypefn

function [files, why] = __git_changed__ (dirpath)

  ## Input validation
  if (nargin != 1)
    error ("__git_changed__: invalid number of input arguments.");
  endif

  files = {};
  why = '';

  ## Is there a git to ask at all.  Every call folds stderr into its output,
  ## so that a tree which is not a repository is answered by this function
  ## rather than by git writing to the terminal behind it.
  [status, ~] = system ('git --version 2>&1');
  if (status != 0)
    why = 'git is not installed';
    return;
  endif

  cmd = sprintf ('git -C "%s" rev-parse --show-toplevel 2>&1', dirpath);
  [status, out] = system (cmd);
  if (status != 0)
    why = 'this tree is not a git repository';
    return;
  endif
  root = strtrim (out);

  cmd = sprintf ('git -C "%s" status --porcelain -uall 2>&1', root);
  [status, out] = system (cmd);
  if (status != 0)
    why = 'git could not report what changed';
    return;
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
