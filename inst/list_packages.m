## Copyright (C) 2023 Andreas Bertsatos <abertsatos@biol.uoa.gr>
##
## This file is part of the statistics package for GNU Octave.
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
##
## List @qcode{pkg}-installable packages from Octave Packages.
##
## @code{@var{valid_packages} = list_packages ()} returns a cell array of
## strings with the available names at Octave Package, which are installable
## with the @code{pkg} command.
##
## @end deftypefn

function valid_packages = list_packages ()
  ## Get package index
  __pkg__ = package_index_resolve ();

  ## Initialize count for valid packages
  vp = 0;

  ## Search the __pkg__ structure for packages with `pkg` dependency
  pkg_names = fieldnames (__pkg__);
  for i = 1:numel (pkg_names)
    ## Get dependencies of latest version
    pkg_dep = __pkg__.(pkg_names{i}).versions(1).depends;

    ## Get all listed dependencies into a cell array
    for c = 1:numel (pkg_dep)
      depends(c) = {pkg_dep(c).name};
    endfor

    ## Check that there is a 'pkg' dependency
    if (any (strcmp (depends, "pkg")))
      vp += 1;
      valid_packages(vp) = {pkg_names{i}};
    endif
    clear depends;
  endfor
  valid_packages = valid_packages';

endfunction

function __pkg__ = package_index_resolve ()
  data = urlread ("https://gnu-octave.github.io/packages/packages/")(6:end);
  data = strrep (data, "&gt;",  ">");
  data = strrep (data, "&lt;",  "<");
  data = strrep (data, "&amp;", "&");
  data = strrep (data, "&#39;", "'");
  eval (data);
endfunction
