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

function opt = getopt (varargin)

  ## this function performs the parameterization of options, if
  ## applicable
  ##
  ## initialize with 'getopt (options, pkg_desc)' (options is the
  ## structure returned by 'get_html_options')
  ##
  ## get an option with 'getopt ("option_name");', or with 'getopt
  ## ("option_name", var_pars)', where var_pars is a structure with
  ## variable parameters like "pkgroot"

  ## options
  persistent opts;

  ## invariable parameters
  persistent pars;

  if (isstruct (varargin{1}))

    ## initialization

    opts = varargin{1};

    pars = struct ();

    desc = varargin{2};

    pars.package = getpar (desc, "name", "");
    pars.version = getpar (desc, "version", "");
    ## next command and comment moved here from
    ## generate_package_html.m 
    ##
    ## Extract first sentence for a short description, remove period
    ## at the end.
    pars.shortdescription = regexprep (getpar (desc, "description", ""),
                                       '\.($| .*)', '');

    pars.date = date ();
    pars.ghv = (a = ver ("generate_html")).Version;

  elseif (ischar (varargin{1}))

    ## return an option

    optname = varargin{1};

    if (is_function_handle (opts.(optname)))

      ## parameterize option

      if (nargin () < 2)
        vpars = struct ();
      else
        vpars = varargin{2};
      endif

      ## defaults
      if (! isfield (vpars, "pkgroot"))
        vpars.pkgroot = "";
      endif

      ## pre-compute 'root' from 'pkgroot'
      vpars.root = fullfile ("..", vpars.pkgroot);

      opt = opts.(optname) (opts, pars, vpars);

    else

      ## simple option

      opt = opts.(optname);

    endif

  else
    error ("getopt: invalid usage");
  endif

endfunction

function ret = getpar (s, field, default)

  if (isfield (s, field))
    ret = s.(field);
  else
    ret = default;
  endif

endfunction
