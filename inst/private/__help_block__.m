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
## @deftypefn {pkg-octave-doc} {@var{srclines} =} __help_block__ (@var{srcfile})
##
## Private function returning the leading help text of a function file.
##
## @var{srclines} holds the lines of the file's texinfo block as they appear
## in it, comment markers and indentation included, since the rules that use
## them measure the file rather than the text the interpreter answers with.
## It is empty for a compiled function, whose docstring lives only inside the
## @file{.oct} and has no source to compare against.
##
## @end deftypefn

function srclines = __help_block__ (srcfile)

  ## Input validation
  if (nargin != 1)
    error ("__help_block__: invalid number of input arguments.");
  endif

  srclines = {};
  if (numel (srcfile) < 2 || ! strcmp (srcfile(end-1:end), '.m'))
    return;
  endif

  lines = strsplit (strrep (fileread (srcfile), "\r\n", "\n"), "\n", ...
                    'CollapseDelimiters', false);
  at = 0;
  for ii = 1:numel (lines)
    marker = regexp (strtrim (lines{ii}), '^##\s*-\*-\s*texinfo', 'once');
    if (! isempty (marker))
      at = ii;
      break;
    endif
  endfor
  if (at == 0)
    return;
  endif

  for ii = at+1:numel (lines)
    if (isempty (regexp (lines{ii}, '^\s*##', 'once')))
      break;
    endif
    srclines{end+1} = lines{ii};
  endfor

endfunction
