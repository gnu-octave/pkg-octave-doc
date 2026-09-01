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
## @deftypefn {pkg-octave-doc} {@var{blocks} =} __class_blocks__ (@var{srcfile})
##
## Private function locating the help text of every member of a classdef file.
##
## @var{blocks} is a struct array with one element per texinfo block found,
## carrying the fields @qcode{'member'}, the name of the member the block
## documents and empty for the block documenting the class itself;
## @qcode{'line'}, the line of the file the block starts on; and
## @qcode{'lines'}, the block's lines as they appear in the file, comment
## markers and indentation included.
##
## A block is attributed to whatever it stands above, which is how a classdef
## is written: a @code{function} line gives a method, a bare name inside a
## properties block gives a property, and a block standing above a
## @code{properties} or @code{methods} block documents the class.  The lines
## are needed as they are in the file, since the rules that use them measure
## the file rather than the text the interpreter answers with.
##
## @end deftypefn

function blocks = __class_blocks__ (srcfile)

  ## Input validation
  if (nargin != 1)
    error ("__class_blocks__: invalid number of input arguments.");
  endif
  if (! (ischar (srcfile) && isrow (srcfile)))
    error ("__class_blocks__: SRCFILE must be a character vector.");
  endif
  if (! exist (srcfile, 'file'))
    error ("__class_blocks__: cannot read file '%s'.", srcfile);
  endif

  blocks = struct ('member', {}, 'line', {}, 'lines', {});
  lines = strsplit (strrep (fileread (srcfile), "\r\n", "\n"), "\n", ...
                    'CollapseDelimiters', false);

  inprops = false;
  ii = 1;
  while (ii <= numel (lines))
    trimmed = strtrim (lines{ii});

    ## Track whether a bare name would be a property or a statement
    ## A word boundary does not match at the end of the subject here, so the
    ## alternatives are spelled out
    if (! isempty (regexp (trimmed, '^properties($|[ \t(])', 'once')))
      inprops = true;
    else
      closes = '^(endproperties|methods|endclassdef)($|[ \t(])';
      if (! isempty (regexp (trimmed, closes, 'once')))
        inprops = false;
      endif
    endif

    if (isempty (regexp (trimmed, '^##\s*-\*-\s*texinfo', 'once')))
      ii += 1;
      continue;
    endif

    ## Collect the comment run following the marker
    at = ii;
    blk = {};
    jj = ii + 1;
    while (jj <= numel (lines) ...
           && ! isempty (regexp (lines{jj}, '^\s*##', 'once')))
      blk{end+1} = lines{jj};
      jj += 1;
    endwhile

    ## Attribute it to the first declaration standing below it
    member = '';
    kk = jj;
    while (kk <= numel (lines))
      decl = strtrim (lines{kk});
      if (isempty (decl))
        kk += 1;
        continue;
      endif
      pat = '^function\s+(?:\[[^\]]*\]\s*=\s*|[\w.]+\s*=\s*)?([A-Za-z]\w*)';
      tok = regexp (decl, pat, 'tokens', 'once');
      if (! isempty (tok))
        member = tok{1};
      elseif (inprops)
        tok = regexp (decl, '^([A-Za-z]\w*)\s*(=|$)', 'tokens', 'once');
        if (! isempty (tok))
          member = tok{1};
        endif
      endif
      break;
    endwhile

    blocks(end+1) = struct ('member', member, 'line', at, 'lines', {blk});
    ii = jj;
  endwhile

endfunction
