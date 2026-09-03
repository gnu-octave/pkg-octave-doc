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
## @deftypefn {pkg-octave-doc} {[@var{names}, @var{pkgname}, @var{why}] =} __index_info__ (@var{opts})
##
## Private function reading the @file{INDEX} an options object points at.
##
## @var{names} is a cell array of every name the file lists and is empty when
## no @file{INDEX} is in play.  An indented line carries one name or several
## separated by whitespace, both being the supported format, and each name is
## read on its own.  @var{pkgname} is the package's name, which the file
## carries on its first line as @code{name >> Title}, and is empty for the same
## reason.  Reading it here is what keeps the package's name out of
## @file{DESCRIPTION}, which nothing in this family opens.
##
## @var{why} is set only when a file was named and could not be read, and is
## the one case that must be reported: a path that answers to nothing turns
## off the rule deciding what a whole scope caches, and a run that said
## nothing about it would look exactly like a clean one.  Asking for no
## @file{INDEX}, or naming none at all, is deliberate and says nothing.
##
## @end deftypefn

function [names, pkgname, why] = __index_info__ (opts)

  ## Input validation
  if (nargin != 1)
    error ("__index_info__: invalid number of input arguments.");
  endif
  if (! isa (opts, 'pkg_doc_options'))
    error ("__index_info__: OPTS must be a pkg_doc_options object.");
  endif

  names = {};
  pkgname = '';
  why = '';

  ## [] leaves it unspecified and '' asks for none, both deliberate
  if (! ischar (opts.IndexLocation) || isempty (opts.IndexLocation))
    return;
  endif
  if (! exist (opts.IndexLocation, 'file'))
    why = sprintf ("INDEX was named as '%s', which answers to no file", ...
                   opts.IndexLocation);
    return;
  endif

  lines = strsplit (strrep (fileread (opts.IndexLocation), "\r\n", "\n"), ...
                    "\n", 'CollapseDelimiters', false);
  if (isempty (lines))
    return;
  endif

  tok = regexp (lines{1}, '^\s*(\S+)\s*>>', 'tokens', 'once');
  if (! isempty (tok))
    pkgname = tok{1};
  endif

  ## A name is indented, a category label is not, and an indented line carries
  ## as many names as fit on it, which is the format core's own parser accepts
  for ii = 2:numel (lines)
    if (! isempty (lines{ii}) && (lines{ii}(1) == ' ' || lines{ii}(1) == "\t"))
      nms = regexp (lines{ii}, '\S+', 'match');
      names = [names, nms];
    endif
  endfor

endfunction
