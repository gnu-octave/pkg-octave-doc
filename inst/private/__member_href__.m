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
## @deftypefn {pkg-octave-doc} {@var{href} =} __member_href__ (@var{name})
##
## Private function giving the html target of a documented class member.
##
## @var{name} is a qualified name, @qcode{"Class.member"}, and @var{href} is
## empty for anything that is not a member this package documents.
##
## A method of a @emph{grouped} class has a page of its own and is linked to it.
## Everything else a class page carries, its properties in either layout and its
## methods in the @emph{flat} one, is linked to the class page and the anchor of
## the collapsible holding it.
##
## @seealso{__member_info__, __member_anchor__}
## @end deftypefn

function href = __member_href__ (name)

  ## Input validation
  if (nargin != 1)
    error ("__member_href__: invalid number of input arguments.");
  endif

  href = "";
  info = __member_info__ (name);
  if (! info.found)
    return;
  endif

  page = strrep (info.class, filesep, "_");
  if (info.grouped && ! strcmp (info.kind, "property"))
    href = [page "." info.member ".html"];
  elseif (strcmp (info.kind, "constructor"))
    href = [page ".html#colapsibleConstructor"];
  else
    href = [page ".html#" __member_anchor__(info.class, info.member)];
  endif

endfunction
