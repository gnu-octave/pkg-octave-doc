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
## @deftypefn {pkg-octave-doc} {@var{html} =} __retarget_members__ (@var{html})
##
## Private function pointing a link to a class member at the page carrying it.
##
## @code{__texi2html__} names a cross-referenced member by its class and the
## member, @qcode{"Class.member.html"}, leaving where that is published to the
## route that publishes it.  This is the html route's answer: a method of a
## grouped class keeps the link, having a page of that name, and everything else
## a class page carries is pointed at the class page and the anchor of the
## collapsible holding it.
##
## A link to anything that is not a documented member is left as it stands.
##
## @seealso{__member_href__, __member_anchor__}
## @end deftypefn

function html = __retarget_members__ (html)

  ## Input validation
  if (nargin != 1)
    error ("__retarget_members__: invalid number of input arguments.");
  endif
  if (! (ischar (html) && (isempty (html) || isrow (html))))
    error ("__retarget_members__: HTML must be a character vector.");
  endif
  if (isempty (html))
    return;
  endif

  [tok, ts, te] = regexp (html, 'href="([^"#]+)\.html"', 'tokens', ...
                          'start', 'end');
  if (isempty (ts))
    return;
  endif

  ## A name resolves once, however many links the text makes to it
  seen = struct ();
  parts = {};
  last = 1;
  for i = 1:numel (ts)
    parts{end+1} = html(last:ts(i)-1);
    name = tok{i}{1};
    key = ["x_" regexprep(name, '[^A-Za-z0-9]', "_")];
    if (! isfield (seen, key))
      seen.(key) = __member_href__ (name);
    endif
    if (isempty (seen.(key)))
      parts{end+1} = html(ts(i):te(i));
    else
      parts{end+1} = ["href=\"" seen.(key) "\""];
    endif
    last = te(i) + 1;
  endfor
  parts{end+1} = html(last:end);
  html = [parts{:}];

endfunction
