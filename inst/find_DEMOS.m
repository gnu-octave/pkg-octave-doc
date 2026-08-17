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
## @deftypefn  {pkg-octave-doc} {@var{demos} =} find_DEMOS (@var{fcnname})
##
## Retrieve the DEMO code blocks from a particular function.
##
## @itemize
## @item
## @var{fcnname} is a char string with the function's name.
##
## @item
## @var{demos} is cell array with each cell containing a char string with the
## code block of each DEMO available in @var{fcnname}.
## @end itemize
##
## @seealso{build_DEMOS, function_texi2html, classdef_texi2html, find_GHurls}
## @end deftypefn

function demos = find_DEMOS (fcnname)

  if (nargin != 1)
    print_usage ();
  endif

  if (! ischar (fcnname))
    print_usage ();
  endif

  ## Get demos from function and store them separately in cell array
  demos = {};
  [code, idx] = test (fcnname, "grabdemo");

  ## `test` locates the file with `file_in_loadpath`, which does not resolve a
  ## namespaced name such as 'geom.offset', so a function inside a +namespace
  ## directory yields no demos and reports no error.  `which` resolves it, but
  ## only try it when the name found nothing: for a compiled function `which`
  ## returns the .oct, bypassing the .cc-tst suffixes `test` searches by name.
  if (isempty (code))
    fpath = which (fcnname);
    if (! isempty (fpath))
      [code, idx] = test (fpath, "grabdemo");
    endif
  endif

  if (idx > 0)
    for i = 1:length (idx) - 1
      block = code(idx(i):idx(i+1)-1);
      demos = [demos; sprintf("%s\n", block)];
    endfor
  endif

endfunction

%!test  # a namespaced function's demos are found
%! tmpd = tempname ();
%! mkdir (tmpd);
%! mkdir (fullfile (tmpd, "+ns"));
%! fid = fopen (fullfile (tmpd, "+ns", "fcn.m"), "w");
%! fprintf (fid, "function fcn ()\nendfunction\n");
%! fprintf (fid, "%%!demo\n%%! disp (1);\n%%!demo\n%%! disp (2);\n");
%! fclose (fid);
%! addpath (tmpd);
%! rehash ();
%! unwind_protect
%!   demos = find_DEMOS ("ns.fcn");
%!   assert (numel (demos), 2);
%!   assert (! isempty (strfind (demos{1}, "disp (1)")));
%!   assert (! isempty (strfind (demos{2}, "disp (2)")));
%! unwind_protect_cleanup
%!   rmpath (tmpd);
%!   unlink (fullfile (tmpd, "+ns", "fcn.m"));
%!   rmdir (fullfile (tmpd, "+ns"));
%!   rmdir (tmpd);
%! end_unwind_protect

%!test  # a namespaced function without demos returns an empty cell
%! tmpd = tempname ();
%! mkdir (tmpd);
%! mkdir (fullfile (tmpd, "+ns"));
%! fid = fopen (fullfile (tmpd, "+ns", "bare.m"), "w");
%! fprintf (fid, "function bare ()\nendfunction\n");
%! fclose (fid);
%! addpath (tmpd);
%! rehash ();
%! unwind_protect
%!   assert (find_DEMOS ("ns.bare"), {});
%! unwind_protect_cleanup
%!   rmpath (tmpd);
%!   unlink (fullfile (tmpd, "+ns", "bare.m"));
%!   rmdir (fullfile (tmpd, "+ns"));
%!   rmdir (tmpd);
%! end_unwind_protect

%!error find_DEMOS ()
%!error find_DEMOS (1)
%!error find_DEMOS ("function_texi2html", 1)

