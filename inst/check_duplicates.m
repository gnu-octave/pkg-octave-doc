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
## @deftypefn {Function File} check_duplicates (@var{pkgname})
## @deftypefnx {Function File} check_duplicates ()
## @deftypefnx {Function File} check_duplicates (@var{options})
## @deftypefnx {Function File} check_duplicates (@var{pkgname}, @var{options})
## Query Octave Forge website to check for duplicate symbols.
##
## With the name of a locally installed package as argument
## @var{pkgname}, check for symbols (function names except class
## methods and functions under a namespace, class base names, and
## namespace names) of this package which are also used by another
## package at Octave Forge or by Octave.
##
## Without arguments, check for duplications of such symbols among
## Octave and all packages at Octave Forge.
##
## @var{options} is a structure whose fields correspond to the
## following possible options:
##
## @table @code
## @item excl
## Cell array of package names at Octave Forge which are excluded from
## the check. If the argument @var{pkgname} was given, this packages
## symbols are retrieved locally, therefore this package will be
## automatically excluded from the symbol search at Octave Forge.
##
## @item syms
## Cell array of symbols (without any @code{@@} or @code{+} prefix for
## class basenames or namespace names). If given, only these symbols
## are checked.
##
## @item browser
## Use this browser instead of trying to find one.
##
## @item text_only
## If given and true, results are displayed as text and no html
## browser is started.
##
## @item url
## Used instead of the default URL of Octave Forge.
##
## @end table
##
## The result is displayed in the HTML browser specified with option
## @code{browser} or found by this function. The browser must have
## javascript enabled. If option @code{text_only} is given and true, a
## simplified text version of the result is displayed and no HTML
## browser is started.
##
## If an output argument is given, a cell array is returned with the
## symbol names in the first column and the corresponding package
## names in the second column.
##
## Note that checking for class basenames and namespace names at
## Octave Forge requires that the @code{generate_html} package of a
## version greater than 0.1.13 had been used to generate the package
## documentations.
##
## @end deftypefn

function ret = check_duplicates (varargin)

  ## Argument processing.

  if ((nargs = nargin ()) > 2)
    print_usage ();
  endif

  ## assign arguments
  pkgn = "";
  options = struct ();
  for id = 1:nargs
    if (ischar (varargin{id}) && id == 1)
      pkgn = varargin{id};
    elseif (isstruct (varargin{id}) && id == nargs)
      options = varargin{id};
    else
      print_usage ();
    endif
  endfor

  ## lowercase option names
  opts = struct ();
  for [val, key] = options
    opts.(tolower (key)) = val;
  endfor
  clear ("options"); # so we can't erroneously use it later

  ## check for unknown option names
  known = {"excl"; "syms"; "text_only"; "url"; "browser"};
  if (numel (unknown = setdiff (fieldnames (opts), known)))
    warning ("unknown option(s):%s", sprintf (" %s", unknown{}));
  endif

  ## set option values
  astext = setoption (opts, "text_only");
  url = setoption (opts, "url");
  excl = setoption (opts, "excl");
  syms = setoption (opts, "syms");
  browser = setoption (opts, "browser");

  ## If necessary, retrieve symbol names of local package.

  psyms = {};
  if (! isempty (pkgn))
    [desc, flag] = pkg ("describe", pkgn);
    if (strcmp (flag, "Not installed"))
      error ("package '%s' not installed", pkgn);
    else
      desc = desc{1};
    endif

    psyms_hash = struct ();
    for c = 1 : numel (desc.provides)
      for f = 1 : numel (desc.provides{c}.functions)
        fun = desc.provides{c}.functions{f};
        if (any (fun == "."))
          ## namespaced function
          psyms_hash.(strsplit (fun, "."){1}) = [];
        elseif (fun(1) == "@")
          ## class method
          psyms_hash.(strsplit (fun, "/"){1}(2:end)) = [];
        else
          ## normal function
          psyms_hash.(fun) = [];
        endif
      endfor
    endfor

    psyms = fieldnames (psyms_hash);
  endif

  ## Define symbols to check for, if any, and excluded packages, if
  ## any.

  if (! isempty (pkgn))

    if (isempty (syms))
      syms = psyms;
    else
      nsyms = numel (syms);
      syms = intersect (psyms, syms);
      if (numel (syms) < nsyms)
        warning ("option 'syms' has been given and package doesn't contain all these symbols -- some symbols in 'syms' not checked");
      endif
    endif

    excl = union (excl, {pkgn});

  endif

  ## Construct parameter arrays and url for url handlers.

  pars = cell (0, 1);

  excl_pars(1 : numel (excl)) = {"exclpkgs[]"};
  excl_pars = vertcat (excl_pars, excl(:).');
  pars = vertcat (pars, excl_pars(:));

  sym_pars(1 : numel (syms)) = {"syms[]"};
  sym_pars = vertcat (sym_pars, syms(:).');
  pars = vertcat (pars, sym_pars(:));
  
  ## we can't use fullfile() since it removes one '/' in '://'
  if (url(end) == '/')
    full_url = [url, "show_duplicates.php"];
  else
    full_url = [url, '/', "show_duplicates.php"];
  endif

  ## Query url.

  if (astext || nargout ())
    [text, succ, msg] = urlread (full_url, "post",
                                 vertcat (pars, {"astext"; ""}));
    if (! succ)
      error ("urlread returned error message: %s", msg);
    endif
    ret = text;
  endif

  if (! astext)
    urlview (full_url, "post", pars, struct ("browser", browser));
  endif

  if (astext)
    printf (text);
  endif

endfunction

function ret = setoption (opts, opt)

  persistent defaults = {"text_only", false;
                         "url",       "http://packages.octave.org";
                         "excl",      {};
                         "syms",      {};
                         "browser",   ""};

  persistent defs = cell2struct (defaults(:, 2), defaults(:, 1));

  if (isfield (opts, opt))
    ret = opts.(opt);
  else
    ret = defs.(opt);
  endif

endfunction
