## Copyright (C) 2008 Soren Hauberg <soren@hauberg.org>
## Copyright (C) 2015 Julien Bect <jbect@users.sourceforge.net>
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
## @deftypefn {Function File} {[@var{header}, @var{text}, @var{footer} =} texi2html (@var{text}, @var{options})
## Converts texinfo function help to a html page.
##
## @seealso{html_help_text}
## @end deftypefn

function [header, text, footer] = texi2html (text, options = struct (), root = "../..")

  ## This function is an interface, to be called as a standalone function.

  ## Check number of input arguments
  if (nargin < 1)
    print_usage ();
  endif

  ## Process input argument 'options'
  if (ischar (options)) || (isstruct (options))
    options = get_html_options (options);
  else
    error ("Second input argument must be a string or a structure");
  endif

  ## Initialize setopts.
  setopts (options, struct ());

  ## Compute 'pkgroot' from 'root'.
  pkgroot = fileparts (fullfile (root, "dummy"))(1:end-3);

  ## Call the actual function, now under private/.
  [header, text, footer] = ...
  __texi2html__ (text, struct ("pkgroot", pkgroot));
  
endfunction
