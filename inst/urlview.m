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
## @deftypefn {Function File} urlview (@var{url})
## @deftypefnx {Function File} urlview (@var{url}, @var{method}, @var{parameters})
## @deftypefnx {Function File} urlview (@dots{}, @var{options})
## Asynchroneously view an url.
##
## The given url @var{url} is viewed in a browser in a separate
## process. As with @code{urlread}, parameters can be specified as a
## cell array @var{parameters} of name value pairs, and @var{method}
## can be "post" or "get". The field @code{browser} of a structure
## @var{options}, given as an optional last argument, may specify the
## browser to use instead of the default. The browser must have
## javascript enabled.
##
## @end deftypefn

function urlview (url, varargin)

  if ((nargs = nargin ()) < 1 || nargs > 4)
    print_usage ();
  endif

  options = struct ();
  method = "get";
  pars = {};
  for id = 1 : (nvargs = numel (varargin))
    if (isstruct (varargin{id}) && id == nvargs)
      options = varargin{id};
    elseif (ischar (varargin{id}) && id == 1)
      method = tolower (varargin{id});
      if (nvargs >= 2 && iscell (varargin{2}))
        pars = varargin{2};
      else
        print_usage ();
      endif
    elseif (iscell (varargin{id}) && id == 2)
      ## varargin{2} has already been processed
    else
      print_usage ();
    endif
  endfor
  if (! any (strcmp (method, {"get", "post"})))
    error ("method must be 'get' or 'post'");
  endif

  ## lowercase option names
  opts = struct ();
  for [val, key] = options
    opts.(tolower (key)) = val;
  endfor
  clear ("options"); # so we can't erroneously use it later

  ## check for unknown option names
  known = {"browser"};
  if (numel (unknown = setdiff (fieldnames (opts), known)))
    warning ("unknown option(s):%s", sprintf (" %s", unknown{}));
  endif

  ## set option values
  browser = setoption (opts, "browser");

  if (isempty (browser))
    for cmd = {"firefox", "epiphany"}
      if (! ([err, path] = system (sprintf ("which %s", cmd{}))))
        browser = cmd{};
        break
      endif
    endfor
    if (isempty (browser))
      error ("no browser found -- try with specifying option 'browser'");
    endif
  endif

  if (round (rem (npars = numel (pars), 2)))
    error ("parameters must be a cell array with an even number of elements");
  endif

  if (strcmp (method, "get")
      && numel (url) + npars + numel ([pars{}]) > 2048)
    error ("url size limit 2048 of method 'get' exceeded")
  endif

  pid = -1;

  ## Relying on Octave to delete the tempfile does not work here.
  if (([fid, tname, msg] = ...
       mkstemp (fullfile (tempdir (), "octave-urlview-XXXXXX"))) == -1)
    error ("could not make temporary file: %s", msg);
  endif

  unwind_protect

    if (npars)
      data = ...
      sprintf ('  <input type="hidden" name="%s" value="%s">', pars{});
    else
      data = "";
    endif

    fprintf (fid, "%s%s%s", header (url, method), data, footer ());

    fclose (fid);

    ## The 'sleep' is necessary since some browsers seem to pass the
    ## job on to an already running browser, and so may quit before
    ## the latter browser reads the temporary file.
    cmd = sprintf ("(%s file://%s > /dev/null 2> /dev/null; sleep 1; rm -f %s) &",
                   browser, tname, tname);

    pid = system (cmd, false, "async");

  unwind_protect_cleanup

    try
      fclose (fid);
    catch
    end_try_catch

    if (pid < 0)
      unlink (tname);
    else
      waitpid (pid);
    endif

  end_unwind_protect

endfunction

function ret = header (url, method)

  ret = ...
  ['<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"', "\n", ...
   ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">', "\n", ...
   '<html xmlns="http://www.w3.org/1999/xhtml">', "\n", ...
   '<body>', "\n", ...
   '<form id="hform" action="', url, '" method="', method, '">', "\n"];

endfunction

function ret = footer ()

  ret = ...
  ['</form>', "\n", ...
   '<script type="text/javascript">', "\n", ...
   '  document.forms["hform"].submit ();', "\n", ...
   '</script>', "\n", ...
   '</body>', "\n", ...
   '</html>', "\n"];

endfunction  

function ret = setoption (opts, opt)

  persistent defaults = {"browser",   ""};

  persistent defs = cell2struct (defaults(:, 2), defaults(:, 1));

  if (isfield (opts, opt))
    ret = opts.(opt);
  else
    ret = defs.(opt);
  endif

endfunction
