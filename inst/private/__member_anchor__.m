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
## @deftypefn {pkg-octave-doc} {@var{id} =} __member_anchor__ (@var{clsname}, @var{member})
##
## Private function naming the anchor a class member is given on its class page.
##
## @var{id} is the identifier of the collapsible holding @var{member}, so a link
## reaching it is @qcode{"<class page>#<id>"}.  It qualifies the member with its
## class, two classes sharing a page in the Qt help file, and carries no
## character but a letter, a digit or an underscore: the identifier is the
## target of a CSS selector, which reads a dot in it as a class rather than as
## part of the name.
##
## @end deftypefn

function id = __member_anchor__ (clsname, member)

  ## Input validation
  if (nargin != 2)
    error ("__member_anchor__: invalid number of input arguments.");
  endif

  id = regexprep ([clsname "." member], '[^A-Za-z0-9]', "_");

endfunction
