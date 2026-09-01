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
## @deftypefn {pkg-octave-doc} {@var{changed} =} __cache_write__ (@var{filename}, @var{cache}, @var{header}, @var{check})
##
## Private function writing a @file{doc-cache} file.
##
## @var{cache} is the @math{3xN} cell array to write, which is sorted by name
## first, so that a directory rebuilt whole and one refreshed a file at a time
## hold the same file.  @var{header} is the first line to keep; an empty one
## stamps the running session's Octave version, which is what a whole-package
## rebuild does.
##
## The file is compared by its content rather than by its bytes and is left
## alone when nothing changed, which is what makes a check meaningful.  A
## cache left with no entries is deleted instead of written empty, Octave
## rejecting an empty one and rebuilding it from scratch.  The write goes
## through a temporary file in the same directory and is renamed into place,
## so an interrupted run cannot leave a truncated cache behind.
##
## @var{check} writes nothing and only answers whether the file would change.
## @var{changed} is true when the file was written, deleted, or would have
## been.
##
## @end deftypefn

function changed = __cache_write__ (filename, cache, header, check)

  ## Input validation
  if (nargin != 4)
    error ("__cache_write__: invalid number of input arguments.");
  endif
  if (! (ischar (filename) && isrow (filename)))
    error ("__cache_write__: FILENAME must be a character vector.");
  endif
  if (! iscell (cache) || (! isempty (cache) && rows (cache) != 3))
    error ("__cache_write__: CACHE must be a 3-row cell array.");
  endif

  ## Sort by name, so that the file does not depend on the order it was built
  if (! isempty (cache))
    [~, idx] = sort (cache(1,:));
    cache = cache(:,idx);
  endif

  ## A cache with no entries is deleted rather than written empty
  if (isempty (cache))
    changed = logical (exist (filename, 'file'));
    if (changed && ! check)
      unlink (filename);
    endif
    return;
  endif

  ## Compare by content, so that an unchanged directory is left untouched
  old = __cache_read__ (filename);
  changed = ! isequal (old, cache);
  if (! changed || check)
    return;
  endif

  if (isempty (header))
    header = sprintf ('# doc-cache created by Octave %s', version ());
  endif

  ## Write through a temporary file in the same directory and rename it, so an
  ## interrupted run leaves the previous cache in place
  tmp = sprintf ('%s.%d.tmp', filename, getpid ());
  save ('-text', tmp, 'cache');
  text = fileread (tmp);
  lines = strsplit (text, "\n", 'CollapseDelimiters', false);
  lines{1} = header;
  fid = fopen (tmp, 'w');
  if (fid < 0)
    error ("__cache_write__: cannot write file '%s'.", tmp);
  endif
  fputs (fid, strjoin (lines, "\n"));
  fclose (fid);
  [err, msg] = rename (tmp, filename);
  if (err)
    unlink (tmp);
    error ("__cache_write__: cannot write file '%s': %s", filename, msg);
  endif

endfunction
