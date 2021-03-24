## Copyright (C) 2021 Kai T. Ohlhus <k.ohlhus@gmail.com>
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} generate_html_manual (@var{srcdir}, @var{outdir})
## Generate @t{HTML} documentation for the core functions provided by Octave.
## @seealso{generate_package_html}
## @end deftypefn

function assert_dir (outdir)
  if (! exist (outdir, "dir"))
    [succ, msg] = mkdir (outdir);
    if (! succ)
      error ("Unable to create directory %s:\n %s", outdir, msg);
    endif
  endif
endfunction
