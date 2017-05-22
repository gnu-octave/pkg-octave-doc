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
## @deftypefn {Function File} setopt ()
## undocumented internal function
## @end deftypefn

function [ret_opts, ret_pars] = setopts (options, desc)

  ## initialize options with 'setopts (options, pkg_desc)' (options is
  ## the structure returned by 'get_html_options')
  ##
  ## 'setopt ()' without arguments returns the options and the package
  ## parameters.
  ##
  ## The persistent parameters could be directly in 'getopt ()'
  ## instead, but this triggered a cleanup bug in Octave.

  ## options
  persistent opts;

  ## invariable parameters
  persistent pars;


  if (! nargin ())

    ret_opts = opts;

    ret_pars = pars;
    
    return;

  endif

  ## initialization

  opts = options;

  pars = struct ();

  pars.package = getpar (desc, "name", "");
  pars.version = getpar (desc, "version", "");
  pars.description = getpar (desc, "description", "");
  ## next command and comment moved here from generate_package_html.m
  ##
  ## Extract first sentence for a short description, remove period at
  ## the end.
  pars.shortdescription = regexprep (pars.description,
                                     '\.($| .*)', '');

  pars.gen_date = datestr (date (), "yyyy-mm-dd");
  pars.ghv = (a = ver ("generate_html")).Version;

endfunction

function ret = getpar (s, field, default)

  if (isfield (s, field))
    ret = s.(field);
  else
    ret = default;
  endif

endfunction
