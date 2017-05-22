## Copyright (C) 2017 Olaf Till <i7tiol@t-online.de>
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
## @deftypefn {Function File} getopt ()
## undocumented internal function
## @end deftypefn

function ret = getopt (optname, vpars)

  ## this function performs the parameterization of options, if
  ## applicable
  ##
  ## get an option with 'getopt ("option_name");', or with 'getopt
  ## ("option_name", var_pars)', where var_pars is a structure with
  ## variable parameters like "pkgroot"

  [opts, pars] = setopts ();

  if (is_function_handle (opts.(optname)))

    ## parameterize option

    if (nargin () < 2)
      vpars = struct ();
    endif

    ## defaults
    if (! isfield (vpars, "pkgroot"))
      vpars.pkgroot = "";
    endif

    ## pre-compute 'root' from 'pkgroot'
    vpars.root = fullfile ("..", vpars.pkgroot);

    ret = opts.(optname) (opts, pars, vpars);

  else

    ## simple option

    ret = opts.(optname);

  endif

endfunction
