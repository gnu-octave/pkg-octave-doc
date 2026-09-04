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
## @deftypefn {pkg-octave-doc} {@var{info} =} __member_info__ (@var{name})
##
## Private function telling whether a name is a documented member of a class.
##
## @var{name} is a qualified name, @qcode{"Class.member"}, the class part
## carrying its namespace where it has one.  @var{info} is a scalar struct
## carrying @qcode{'found'}, true only for a member this package documents;
## @qcode{'class'} and @qcode{'member'}, the two parts of the name;
## @qcode{'kind'}, one of @qcode{"constructor"}, @qcode{"method"} or
## @qcode{"property"}; and @qcode{'grouped'}, true when the class sorts its
## methods under banner blocks and so is rendered a page per method.
##
## A member of a @code{Hidden} or private block is not found, @code{methods} and
## @code{properties} not reporting one, which is what keeps a link from being
## made to a page that is never published.
##
## @end deftypefn

function info = __member_info__ (name)

  ## Input validation
  if (nargin != 1)
    error ("__member_info__: invalid number of input arguments.");
  endif

  info = struct ('found', false, 'class', '', 'member', '', 'kind', '', ...
                 'grouped', false);
  if (! (ischar (name) && isrow (name)))
    return;
  endif

  ## The class is everything before the last dot, so a namespace stays with it
  at = strfind (name, ".");
  if (isempty (at))
    return;
  endif
  clsname = name(1:at(end)-1);
  member = name(at(end)+1:end);
  if (isempty (clsname) || isempty (member))
    return;
  endif

  ## Only a classdef is read this way.  An old style class answers to methods
  ## too, but documents its members as "@class/member" and is reached by that
  ## name instead.
  file = which (clsname);
  if (isempty (file))
    return;
  endif
  try
    src = fileread (file);
  catch
    return;
  end_try_catch
  if (isempty (regexp (src, '^\s*classdef\s', "once", "lineanchors")))
    return;
  endif

  try
    MTHDS = methods (clsname);
    PROPS = properties (clsname);
  catch
    return;
  end_try_catch

  parts = strsplit (clsname, ".");
  stem = parts{end};
  if (any (strcmp (MTHDS, member)))
    if (strcmp (member, stem))
      info.kind = "constructor";
    else
      info.kind = "method";
    endif
  elseif (any (strcmp (PROPS, member)))
    info.kind = "property";
  else
    return;
  endif

  ## The layout the class is rendered in, as classdef_texi2html decides it
  MTHDS_grp = MTHDS;
  MTHDS_grp(strcmp (MTHDS_grp, stem)) = [];
  MTHDS_grp = get_methods_ordered (clsname, MTHDS_grp);
  if (any (strcmp (MTHDS, stem)))
    MTHDS_grp{end+1} = stem;
  endif
  info.grouped = ! isempty (get_method_groups (clsname, MTHDS_grp));

  info.found = true;
  info.class = clsname;
  info.member = member;

endfunction
