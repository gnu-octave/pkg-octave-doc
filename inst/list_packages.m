## Copyright (C) 2023-2026 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefn  {pkg-octave-doc} {@var{valid_packages} =} list_packages ()
## @deftypefnx {pkg-octave-doc} {@var{valid_packages} =} list_packages (@var{index})
##
## List @qcode{pkg}-installable packages from Octave Packages.
##
## @code{@var{valid_packages} = list_packages ()} returns an @math{Nx2} cell
## array naming every package at Octave Packages that is installable with the
## @code{pkg} command, against the URL of its latest release.  A package
## qualifies by declaring @qcode{pkg} among the dependencies of that release.
## The index is fetched from Octave Packages, and a fetch that does not
## succeed is an error saying so.
##
## @code{@var{valid_packages} = list_packages (@var{index})} reads the index
## from @var{index} instead of fetching it, given either as the JSON text or
## as the structure @code{jsondecode} returns for it.  This is what makes the
## selection testable without reaching the network, and it is useful against a
## copy of the index taken earlier.
##
## An index in which nothing qualifies returns an empty cell array rather than
## nothing at all.
##
## @end deftypefn

function valid_packages = list_packages (index)

  ## Get the package index, from the argument when there is one
  if (nargin == 1)
    if (isstruct (index))
      __pkg__ = index;
    elseif (ischar (index) && isrow (index))
      __pkg__ = jsondecode (index, "makeValidName", false);
    else
      error (strcat ("list_packages: INDEX must be a character vector or", ...
                     " the structure jsondecode returns for one."));
    endif
  else
    url = "https://gnu-octave.github.io/packages/packages.json";
    [list, ok] = urlread (url);
    if (! ok)
      error ("list_packages: cannot reach Octave Packages at %s.", url);
    endif
    __pkg__ = jsondecode (list, "makeValidName", false);
  endif

  ## An index naming nothing that qualifies is an empty answer, not no answer
  valid_packages = cell (0, 2);

  ## Search the __pkg__ structure for packages with `pkg` dependency
  pkg_names = fieldnames (__pkg__);
  for i = 1:numel (pkg_names)
    ## The latest release, which is the one listed first
    latest = i_element (__pkg__.(pkg_names{i}).versions, 1);
    if (! isstruct (latest) || ! isfield (latest, "url"))
      continue;
    endif

    ## Check that there is a 'pkg' dependency
    if (isfield (latest, "depends") ...
        && any (strcmp (i_dep_names (latest.depends), "pkg")))
      valid_packages(end+1,:) = {pkg_names{i}, latest.url};
    endif
  endfor

endfunction

## The Nth element of what jsondecode made of a JSON array, which is a struct
## array where the entries carry the same fields and a cell array where they
## do not.
function out = i_element (v, n)
  if (iscell (v))
    out = v{n};
  else
    out = v(n);
  endif
endfunction

## The names a release declares as its dependencies, of which there may be
## none at all.  Octave Packages lists one as a string carrying the name and
## any version it asks for, as in "octave (>= 9.1.0)", and named it in an
## object once, which is still read.
function names = i_dep_names (dep)
  names = {};
  for c = 1:numel (dep)
    d = i_element (dep, c);
    if (ischar (d) && isrow (d))
      names{end+1} = strtrim (strsplit (d, {" ", "\t", "("}){1});
    elseif (isstruct (d) && isfield (d, "name"))
      names{end+1} = d.name;
    endif
  endfor
endfunction

## The cases pass an index of their own rather than fetching one, so that the
## selection is tested without reaching the network and the suite does not
## depend on Octave Packages being up.

%!test  # a package declaring a pkg dependency is kept, one without is dropped
%! txt = ['{"kept": {"versions": [{"url": "u1", "depends": ', ...
%!        '[{"name": "octave"}, {"name": "pkg"}]}]},', ...
%!        '"dropped": {"versions": [{"url": "u2", "depends": ', ...
%!        '[{"name": "octave"}]}]}}'];
%! p = list_packages (txt);
%! assert (size (p), [1, 2]);
%! assert (p{1,1}, "kept");
%! assert (p{1,2}, "u1");

%!test  # a dependency named by a string, as Octave Packages lists it
%! txt = ['{"kept": {"versions": [{"url": "u1", "depends": ', ...
%!        '["octave (>= 9.1.0)", "pkg"]}]},', ...
%!        '"dropped": {"versions": [{"url": "u2", "depends": ', ...
%!        '["octave (>= 4.0.0)", "signal (>= 1.4.2)"]}]}}'];
%! p = list_packages (txt);
%! assert (size (p), [1, 2]);
%! assert (p{1,1}, "kept");
%! assert (p{1,2}, "u1");

%!test  # the URL comes from the latest release, which is the first listed
%! txt = ['{"kept": {"versions": [{"url": "newest", "depends": ', ...
%!        '[{"name": "pkg"}]}, {"url": "older", "depends": ', ...
%!        '[{"name": "pkg"}]}]}}'];
%! p = list_packages (txt);
%! assert (p{1,2}, "newest");

%!test  # a release declaring no dependency at all is passed over, not fatal
%! txt = ['{"bare": {"versions": [{"url": "u1", "depends": []}]},', ...
%!        '"kept": {"versions": [{"url": "u2", "depends": ', ...
%!        '[{"name": "pkg"}]}]}}'];
%! p = list_packages (txt);
%! assert (size (p), [1, 2]);
%! assert (p{1,1}, "kept");

%!test  # an index in which nothing qualifies gives an empty answer
%! txt = ['{"dropped": {"versions": [{"url": "u1", "depends": ', ...
%!        '[{"name": "io"}]}]}}'];
%! p = list_packages (txt);
%! assert (iscell (p));
%! assert (isempty (p));
%! assert (columns (p), 2);

%!test  # the decoded structure is taken as readily as the text
%! txt = ['{"kept": {"versions": [{"url": "u1", "depends": ', ...
%!        '[{"name": "pkg"}]}]}}'];
%! s = jsondecode (txt, "makeValidName", false);
%! assert (list_packages (s), list_packages (txt));

## Test input validation
%!error<list_packages: INDEX must be a character vector or the structure jsondecode returns for one.> ...
%! list_packages (5)
