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
## @deftypefn  {pkg-octave-doc} {@var{groups} =} parse_method_groups (@var{src}, @var{MTHDS})
##
## Map the public methods of a classdef to the comment-banner groups they fall
## under.
##
## @var{src} is the source text of a classdef file and @var{MTHDS} is a cell
## array of its public method names (as returned by @code{methods}).  A @qcode{
## "large"} classdef groups its methods with banner comment blocks of the form
##
## @example
## @group
## ################################################################
## ##                     ** Group Name **                       ##
## ################################################################
## @end group
## @end example
##
## placed before each @code{methods} block, matching the convention used in the
## datatypes package.  @code{parse_method_groups} walks the source and assigns
## each public method to the most recent banner above its @code{function}
## declaration.
##
## @var{groups} is a struct array (in order of appearance) with fields
## @qcode{name} (the banner title) and @qcode{methods} (a cell array of the
## public methods in that group).  Groups whose methods are all non-public
## (@code{Hidden}/private, hence absent from @var{MTHDS}) are omitted; public
## methods that precede any banner are collected into a trailing @qcode{"Other"}
## group.
##
## When @var{src} contains no banner at all, @var{groups} is returned empty,
## which signals that the classdef is @emph{not} large and should be rendered as
## a single page.
##
## @seealso{get_method_groups, classdef_texi2html}
## @end deftypefn

function groups = parse_method_groups (src, MTHDS)

  if (nargin != 2 || ! ischar (src) || ! iscellstr (MTHDS))
    print_usage ();
  endif

  src = strrep (src, "\r\n", "\n");
  lines = strsplit (src, "\n", "collapsedelimiters", false);

  gnames = {};        # group names, in order of first appearance
  gmeths = {};        # parallel cell array of method-name cell arrays
  other = {};         # public methods seen before any banner
  cur = "";           # current banner title
  has_banner = false;

  for k = 1:numel (lines)
    t = strtrim (lines{k});

    ## Banner title line:  ## ... ** Title ** ... ##
    tok = regexp (t, "^##\\s*\\*\\*\\s*(.*?)\\s*\\*\\*\\s*##$", "tokens");
    if (! isempty (tok))
      cur = strtrim (tok{1}{1});
      has_banner = true;
      continue;
    endif

    ## Function declaration line
    if (strncmp (t, "function", 8) && (numel (t) == 8 || any (t(9) == " [")))
      name = i_method_name (t);
      if (! isempty (name) && any (strcmp (MTHDS, name)))
        if (isempty (cur))
          other{end+1} = name;
        else
          idx = find (strcmp (gnames, cur));
          if (isempty (idx))
            gnames{end+1} = cur;
            gmeths{end+1} = {name};
          else
            gmeths{idx}{end+1} = name;
          endif
        endif
      endif
    endif
  endfor

  ## No banners -> not a large classdef
  if (! has_banner)
    groups = struct ("name", {}, "methods", {});
    return;
  endif

  ## Assemble the struct array in file order, appending stragglers as "Other"
  groups = struct ("name", {}, "methods", {});
  for i = 1:numel (gnames)
    groups(end+1) = struct ("name", gnames{i}, "methods", {gmeths{i}});
  endfor
  if (! isempty (other))
    groups(end+1) = struct ("name", "Other", "methods", {other});
  endif

endfunction

## Extract the method name from a "function ..." declaration line.
function name = i_method_name (t)
  s = strtrim (regexprep (t, "^function", ""));
  ## Drop output arguments (everything up to and including the first '=')
  eq = strfind (s, "=");
  if (! isempty (eq))
    s = s(eq(1)+1:end);
  endif
  ## The name runs up to the argument list '(' or trailing whitespace
  s = strtrim (s);
  name = regexprep (s, "[^A-Za-z0-9_].*$", "");
endfunction

%!test
%! ## Ordinary classdef (no banners) -> empty (signals "not large")
%! src = "classdef Foo\n  methods\n    function a = m1 (o)\n    endfunction\n  endmethods\nendclassdef\n";
%! g = parse_method_groups (src, {"m1"});
%! assert (isempty (g));
%! assert (isstruct (g));

%!test
%! ## Single banner with two methods
%! src = ["classdef Foo\n  methods\n", ...
%!        "##################\n## ** Group One ** ##\n##################\n", ...
%!        "    function a = m1 (o)\n    endfunction\n", ...
%!        "    function m2 (o)\n    endfunction\n  endmethods\nend\n"];
%! g = parse_method_groups (src, {"m1", "m2"});
%! assert (numel (g), 1);
%! assert (g(1).name, "Group One");
%! assert (g(1).methods, {"m1", "m2"});

%!test
%! ## Two banners preserve order and membership
%! src = ["## ** First ** ##\n", ...
%!        "    function a = m1 (o)\n    endfunction\n", ...
%!        "## ** Second ** ##\n", ...
%!        "    function [x, y] = m2 (o)\n    endfunction\n", ...
%!        "    function m3 (o)\n    endfunction\n"];
%! g = parse_method_groups (src, {"m1", "m2", "m3"});
%! assert ({g.name}, {"First", "Second"});
%! assert (g(1).methods, {"m1"});
%! assert (g(2).methods, {"m2", "m3"});

%!test
%! ## Output-argument forms: [a,b]= and single a= and none
%! src = ["## ** G ** ##\n", ...
%!        "    function [a, b] = m1 (o)\n    endfunction\n", ...
%!        "    function c = m2 (o)\n    endfunction\n", ...
%!        "    function m3 (o)\n    endfunction\n"];
%! g = parse_method_groups (src, {"m1", "m2", "m3"});
%! assert (g(1).methods, {"m1", "m2", "m3"});

%!test
%! ## Banner title padded with extra spaces is trimmed
%! src = ["## **    Auxiliary Methods    ** ##\n", ...
%!        "    function m1 (o)\n    endfunction\n"];
%! g = parse_method_groups (src, {"m1"});
%! assert (g(1).name, "Auxiliary Methods");

%!test
%! ## Non-public methods (absent from MTHDS) are excluded; an all-hidden group
%! ## is omitted entirely
%! src = ["## ** Public ** ##\n", ...
%!        "    function m1 (o)\n    endfunction\n", ...
%!        "## ** Hidden Stuff ** ##\n", ...
%!        "    function subsref (o)\n    endfunction\n"];
%! g = parse_method_groups (src, {"m1"});
%! assert (numel (g), 1);
%! assert (g(1).name, "Public");
%! assert (g(1).methods, {"m1"});

%!test
%! ## A public method before any banner lands in a trailing "Other" group
%! src = ["    function m0 (o)\n    endfunction\n", ...
%!        "## ** Real Group ** ##\n", ...
%!        "    function m1 (o)\n    endfunction\n"];
%! g = parse_method_groups (src, {"m0", "m1"});
%! assert ({g.name}, {"Real Group", "Other"});
%! assert (g(2).methods, {"m0"});

%!test
%! ## A '####'-only line (no ** title **) is not a banner
%! src = ["################################\n", ...
%!        "    function m1 (o)\n    endfunction\n"];
%! g = parse_method_groups (src, {"m1"});
%! assert (isempty (g));

%!error <Invalid call> parse_method_groups ()
%!error <Invalid call> parse_method_groups ("x")
%!error <Invalid call> parse_method_groups (1, {"m"})
%!error <Invalid call> parse_method_groups ("x", "notcell")
