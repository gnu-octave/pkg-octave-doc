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
## @deftypefn {pkg-octave-doc} {[@var{names}, @var{pkgname}] =} __index_info__ (@var{opts})
##
## Private function reading the @file{INDEX} an options object points at.
##
## @var{names} is a cell array of every name the file lists and is empty when
## no @file{INDEX} is in play.  @var{pkgname} is the package's name, which the
## file carries on its first line as @code{name >> Title}, and is empty for the
## same reason.  Reading it here is what keeps the package's name out of
## @file{DESCRIPTION}, which nothing in this family opens.
##
## @end deftypefn

function [names, pkgname] = __index_info__ (opts)

  ## Input validation
  if (nargin != 1)
    error ("__index_info__: invalid number of input arguments.");
  endif
  if (! isa (opts, 'pkg_doc_options'))
    error ("__index_info__: OPTS must be a pkg_doc_options object.");
  endif

  names = {};
  pkgname = '';
  if (isempty (opts.Index) || ! ischar (opts.Index) ...
      || ! exist (opts.Index, 'file'))
    return;
  endif

  lines = strsplit (strrep (fileread (opts.Index), "\r\n", "\n"), "\n", ...
                    'CollapseDelimiters', false);
  if (isempty (lines))
    return;
  endif

  tok = regexp (lines{1}, '^\s*(\S+)\s*>>', 'tokens', 'once');
  if (! isempty (tok))
    pkgname = tok{1};
  endif

  ## A name is indented, a category label is not
  for ii = 2:numel (lines)
    if (! isempty (lines{ii}) && (lines{ii}(1) == ' ' || lines{ii}(1) == "\t"))
      nm = strtrim (lines{ii});
      if (! isempty (nm))
        names{end+1} = nm;
      endif
    endif
  endfor

endfunction
