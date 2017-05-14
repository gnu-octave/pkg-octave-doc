## Copyright (C) 2008 Soren Hauberg <soren@hauberg.org>
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

function generate_html_manual (srcdir, outdir = "htdocs", options = struct ())

  ## Check number of input arguments
  if (nargin < 1)
    print_usage ();
    error ("Not enough input arguments: at least one argument was expected.");
  endif

  if (! ischar (srcdir))
    error ("First input argument must be a string");
  endif

  if (! ischar (outdir))
    error ("Second input argument must be a string");
  endif

  ## Process input argument 'options'
  if (ischar (options)) || (isstruct (options))
    options = get_html_options (options);
  else
    error ("Third input argument must be a string or a structure");
  endif

  ## Create directories
  assert_dir (outdir);

  ###################################################
  ##  Generate reference for individual functions  ##
  ###################################################

  ## Get INDEX structure
  indices = txi2index (srcdir);
  index = struct ();
  index.provides = {};
  index.name = "octave";
  index.description = "GNU Octave comes with a large set of general-purpose functions that are listed below. This is the core set of functions that is available without any packages installed.";
  for k = 1:length (indices)
    if (! isempty (indices{k}))
      ikp = indices{k}.provides;
      index.provides (end+1:end+length (ikp)) = ikp;
    endif
  endfor

  ## Disable options that are specific to packages
  options.include_package_list_item = false;
  options.include_package_page = false;
  options.include_package_license = false;
  options.include_package_news = false;

  ## Generate the documentation  
  generate_package_html (index, outdir, options);

endfunction

function retval = docstring_handler (fun)
  retval = sprintf ("@ifhtml\n@html\n<div class='seefun'>See <a href='../function/%s.html'>%s</a></div>\n@end html\n@end ifhtml\n",
                    fun, fun);
endfunction

