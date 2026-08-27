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
## @deftypefn  {pkg-octave-doc} {@var{sidebar} =} build_class_sidebar (@var{clsname}, @var{groups}, @var{active})
##
## Build the class-scoped sidebar HTML for a standalone method page.
##
## Unlike the package sidebar (categories of functions), a method page shows the
## tree of its @emph{own} class: the banner @var{groups} are the collapsible
## sections and the methods are the leaves.  @var{clsname} is the class name,
## @var{groups} the struct array from @code{parse_method_groups}, and
## @var{active} the method to highlight (its group is pre-expanded).  Each method
## links to its @qcode{@var{Class}.@var{method}.html} page; a pinned overview
## entry links back to the class page.
##
## The markup mirrors the package sidebar (@code{divcat}/@code{ul_cat}/
## @code{li_fcn}) so both look identical.
##
## @seealso{parse_method_groups, method_texi2html, classdef_texi2html}
## @end deftypefn

function sidebar = build_class_sidebar (clsname, groups, active)

  if (nargin != 3 || ! ischar (clsname) || ! isstruct (groups) ...
      || ! ischar (active))
    print_usage ();
  endif

  ## Sidebar templates (identical to the package sidebar)
  divcat = ["			<div class=""row"">\n", ...
            "				<input id=""togList%d"" type=""checkbox""%s>\n", ...
            "				<label for=""togList%d"">\n", ...
            "					<span><h6>%s</h6></span>\n", ...
            "					<span><h6>%s</h6></span>\n", ...
            "				</label>\n", ...
            "				<div class=""list"">"];
  ul_cat = ["				<ul style=""list-style-type: none; padding-", ...
            "left: 20px;"">"];
  li_fcn = ["					<li><a href=""%s.html"" class=""text-", ...
            "decoration-none font-monospace""><small>%s</small></a></li>"];
  li_fcn_active = ["					<li><a href=""%s.html"" class=""text-", ...
                   "decoration-none font-monospace fw-bolder"">", ...
                   "<small>%s</small></a></li>"];

  clsfile = strrep (clsname, filesep, "_");

  ## Pinned overview link back to the class page
  sidebar = sprintf (["			<div class=""row"">\n", ...
                      "				<a href=""%s.html"" class=""text-decoration-none"">", ...
                      "<h6>&#8962;&nbsp;%s</h6></a>\n", ...
                      "			</div>\n"], clsfile, clsname);

  ## One collapsible section per group; expand the section holding the active
  ## method
  for i = 1:numel (groups)
    if (any (strcmp (groups(i).methods, active)))
      checkbox = " checked";
    else
      checkbox = "";
    endif
    tmpcat = sprintf (divcat, i, checkbox, i, groups(i).name, groups(i).name);
    sidebar = [sidebar, tmpcat, "\n", ul_cat, "\n"];
    for j = 1:numel (groups(i).methods)
      m = groups(i).methods{j};
      mfile = [clsfile ".", m];
      if (strcmp (m, active))
        tmp = sprintf (li_fcn_active, mfile, m);
      else
        tmp = sprintf (li_fcn, mfile, m);
      endif
      sidebar = [sidebar, tmp, "\n"];
    endfor
    sidebar = [sidebar "				</ul>\n				</div>\n			</div>\n"];
  endfor

endfunction

## The behaviour of this function is tested through classdef_texi2html, the
## public entry point that reaches it: a test block is evaluated in the scope
## of test.m, so it cannot name a private function.
