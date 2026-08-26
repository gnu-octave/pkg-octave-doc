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
## @deftypefn {pkg-octave-doc} {@var{html} =} qch_postprocess (@var{html}, @var{name}, @var{qchmap})
##
## Retarget the HTML of a single help text for inclusion in a Qt help page.
##
## @code{__texi2html__} renders a help text for the online documentation, where
## every documented name owns a page of its own.  A Qt help file built by
## @code{package_texi2qch} groups the names of an INDEX category onto one page
## instead, so both the links between names and the anchors within a help text
## have to be moved before the fragments of a category are concatenated.  This
## function performs that move on the rendered HTML alone, leaving
## @code{__texi2html__} untouched and its output unchanged for every other
## caller.
##
## @var{html} is the character vector returned by @code{__texi2html__},
## @var{name} the documented name it belongs to, and @var{qchmap} an Nx3 cell
## array whose columns are the documented name, the page it has been assigned
## to, and its anchor within that page.
##
## Two transformations are applied.
##
## @itemize
## @item
## A link to another documented name, which @code{__texi2html__} emits as
## @qcode{<a href="NAME.html">}, is retargeted at that name's page and anchor.
## A link whose target is absent from @var{qchmap} is unwrapped to its own text,
## since a Qt help file has nowhere to send it and a dead link is worse than
## none.
##
## @item
## An anchor within the help text, which @code{__texi2html__} emits as
## @qcode{<a name="ANCHOR">} for every @code{@@subheading}, is prefixed with
## @var{name}.  Without this the @qcode{Description} anchor of every function
## sharing a page would collide, and only the first would be reachable.  Any
## reference to that anchor from within the same help text is moved with it.
## @end itemize
##
## @seealso{package_texi2qch, __texi2html__}
## @end deftypefn

function html = qch_postprocess (html, name, qchmap)

  if (nargin != 3)
    print_usage ();
  endif
  if (! (ischar (html) && (isempty (html) || isrow (html))))
    error ("qch_postprocess: HTML must be a character vector.");
  endif
  if (! (ischar (name) && isrow (name)))
    error ("qch_postprocess: NAME must be a character vector.");
  endif
  if (! (iscell (qchmap) && columns (qchmap) == 3))
    error ("qch_postprocess: QCHMAP must be an Nx3 cell array.");
  endif
  if (isempty (html))
    return;
  endif

  ## The file names __texi2html__ links to are the documented names with any
  ## file separator squashed to an underscore, so the lookup keys must be too.
  keys = strrep (qchmap(:,1), filesep, '_');

  ## 1. Retarget the links between documented names.
  pat = '<a href="([^"]+)\.html">(.*?)</a>';
  [tok, ts, te] = regexp (html, pat, 'tokens', 'start', 'end');
  if (! isempty (ts))
    parts = {};
    last = 1;
    for i = 1:numel (ts)
      parts{end+1} = html(last:ts(i)-1);
      target = tok{i}{1};
      text = tok{i}{2};
      idx = find (strcmp (keys, target), 1);
      if (isempty (idx))
        parts{end+1} = text;
      else
        parts{end+1} = ['<a href="', qchmap{idx,2}, '#', qchmap{idx,3}, ...
                        '">', text, '</a>'];
      endif
      last = te(i) + 1;
    endfor
    parts{end+1} = html(last:end);
    html = [parts{:}];
  endif

  ## 2. Scope the anchors of this help text to the name that owns them, so that
  ##    the names sharing a page do not collide.
  prefix = regexprep (name, '[^A-Za-z0-9._-]', '-');
  anchors = regexp (html, '<a name="([^"]+)"></a>', 'tokens');
  for i = 1:numel (anchors)
    old = anchors{i}{1};
    if (strncmp (old, [prefix, '-'], numel (prefix) + 1))
      continue;                     # already scoped, leave it alone
    endif
    esc = regexptranslate ('escape', old);
    new = [prefix, '-', old];
    html = regexprep (html, ['<a name="', esc, '"></a>'], ...
                            ['<a name="', new, '"></a>']);
    html = regexprep (html, ['href="#', esc, '"'], ['href="#', new, '"']);
  endfor

endfunction
