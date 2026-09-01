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
## @deftypefn {pkg-octave-doc} {[@var{cache}, @var{header}] =} __cache_read__ (@var{filename})
##
## Private function reading a @file{doc-cache} file.
##
## @var{cache} is the @math{3xN} cell array the file holds, its rows being the
## name, the help text and the first sentence of each entry, and is
## @math{3x0} when @var{filename} names no file.  @var{header} is the file's
## first line, which records the Octave version the cache was built with, and
## is empty when there is no file to read it from.
##
## A file that exists but holds no @code{cache} variable is an error rather
## than an empty result, since overwriting it would destroy something that was
## not a doc-cache.
##
## @end deftypefn

function [cache, header] = __cache_read__ (filename)

  ## Input validation
  if (nargin != 1)
    error ("__cache_read__: invalid number of input arguments.");
  endif
  if (! (ischar (filename) && isrow (filename)))
    error ("__cache_read__: FILENAME must be a character vector.");
  endif

  cache = cell (3, 0);
  header = '';
  if (! exist (filename, 'file'))
    return;
  endif

  ## The first line is a comment carrying the Octave version
  fid = fopen (filename, 'r');
  if (fid < 0)
    error ("__cache_read__: cannot read file '%s'.", filename);
  endif
  header = fgetl (fid);
  fclose (fid);
  if (! ischar (header))
    header = '';
  endif

  s = load (filename);
  if (! isfield (s, 'cache'))
    error ("__cache_read__: '%s' holds no doc-cache.", filename);
  endif
  cache = s.cache;
  if (! iscell (cache) || (! isempty (cache) && rows (cache) != 3))
    error ("__cache_read__: '%s' holds a malformed doc-cache.", filename);
  endif
  if (isempty (cache))
    cache = cell (3, 0);
  endif

endfunction
