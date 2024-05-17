## Copyright (C) 2023-2024 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefn  {pkg-octave-doc} {} function_texi2html (@var{fcnname}, @var{pkgfcns}, @var{info})
##
## Generate HTML page for a particular function.
##
## @code{function_texi2html} requires three input arguments: @var{fcnname}, a
## char string with the function's name; @var{pkgfcns}, a cell array with all
## available functions of a package; and @var{info}, a structure with relevant
## information about the package, which the function @var{fcnname} belongs to.
##
## @var{pkgfcns} can be either a @math{Nx2} or a @math{Nx3} cell array, whose
## 1st column list all available function names, the 2nd column list the each
## function's category, and the 3rd column contains the URL to the function's
## source code.  @var{pkgfcns} is used to relative references to other pages of
## functions which are listed in the @qcode{See also} tag.  When a 3rd column is
## present, @code{function_texi2html} uses it to add a source code link of the
## the function in @var{fcnname}.
##
## The @var{info} structure requires at least the following fields:
##
## @multitable @columnfractions 0.2 0.8
## @headitem Field Name @tab Description
## @item @qcode{PKG_ICON} @tab The relative reference to the package's logo
## image which must be either in .svg or .png format and it is located in the
## newly created @qcode{assets/} folder inside the working directory.
##
## @item @qcode{PKG_NAME} @tab The package's name (e.g. "pkg-octave-doc")
##
## @item @qcode{PKG_TITLE} @tab The package's title (e.g. "Octave Package
## Documentation")
##
## @item @qcode{OCTAVE_LOGO} @tab The relative reference to Octave's logo, also
## located inside the @qcode{assets/} folder.
##
## @end multitable
##
## To generate a suitable @math{Nx2} cell array for a specific package, use the
## @code{package_texi2html} function and to populate is with the 3rd column use
## @code{find_GHurls}.  The @var{info} structure can also be created with
## @code{package_texi2html}.
##
## @code{function_texi2html} depends on the @qcode{texi2html} command line tool
## version 1.82, which must be installed and available on the system's $PATH,
## and the generated HTML code is based on the @qcode{function_template.html}
## and @qcode{default.html} layouts.
##
## @seealso{package_texi2html, classdef_texi2html, find_GHurls, build_DEMOS}
## @end deftypefn

function function_texi2html (fcnname, pkgfcns, info)

  if (nargin != 3)
    print_usage ();
  endif

  if (! ischar (fcnname))
    print_usage ();
  endif

  if (! iscell (pkgfcns))
    print_usage ();
  endif

  if (! isstruct (info))
    print_usage ();
  endif

  if (! isfield (info, "PKG_ICON") || ! isfield (info, "PKG_NAME") || ...
      ! isfield (info, "PKG_TITLE") || ! isfield (info, "OCTAVE_LOGO"))
    print_usage ();
  endif

  ## Add try catch to help identify function file that caused an issue
  ## during batch processing all functions in a package with package_texi2html
  try
    ## Get help text from function
    [text, format] = get_help_text (fcnname);

    ## Build HTML code from function's texinfo
    fcn_text = __texi2html__ (text, fcnname, pkgfcns);

    ## Find the function's category
    fcn_idx = find (strcmp (pkgfcns(:,1), fcnname));
    catname = pkgfcns{fcn_idx, 2};

    ## Add link to function's source code (if applicable)
    if (size (pkgfcns, 2) == 3)
      url = pkgfcns{fcn_idx, 3};
      url_text = strcat (["<p><strong>Source Code: </strong>\n"], ...
                         ["  <a href=""", url, """>", fcnname, "</a>\n</div>"]);
      fcn_text = strrep (fcn_text, "</div>", url_text);
    endif

    ## Add DEMOS (if applicable)
    demo_txt = build_DEMOS (fcnname);
    fcn_text = [fcn_text "\n" demo_txt];

    ## Templates for side bar
    divcat = ["			<div class=""row"">\n", ...
              "				<input id=""togList%d"" type=""checkbox""%s>\n", ...
              "				<label for=""togList%d"">\n", ...
              "					<span><h6>%s</h6></span>\n", ...
              "					<span><h6>%s</h6></span>\n", ...
              "				</label>\n", ...
              "				<div class=""list"">"];
    ul_cat = ["				<ul style=""list-style-type: none; padding-", ...
              "left: 20px;"">"];
    li_fcn = ["					<li><a href=""%s.html"" class=""text-", ...
              "decoration-none font-monospace"">%s</a></li>"];
    li_fcn_active = ["					<li><a href=""%s.html"" class=""text-", ...
                     "decoration-none font-monospace fw-bolder"">%s</a></li>"];

    ## Build side bar function list
    fcn_list = "";
    cat_name = unique (pkgfcns(:,2));
    for i = 1:numel (cat_name)
      ## Expand current category
      if (strcmpi (cat_name{i}, catname))
        checkbox = " checked ";
      else
        checkbox = "";
      endif
      tmpcat = sprintf (divcat, i, checkbox, i, cat_name{i}, cat_name{i});
      fcn_list = [fcn_list, tmpcat, "\n"];
      fcn_list = [fcn_list, ul_cat, "\n"];
      ## Get functions for this category
      fcn_idx = find (strcmp (pkgfcns(:,2), cat_name{i}));
      for j = 1:numel (fcn_idx)
        fcn_name = pkgfcns{fcn_idx(j),1};
        fcn_file = strrep (fcn_name, filesep, "_");
        ## Make active function bolder
        if (strcmpi (fcn_name, fcnname))
          tmpfcn = sprintf (li_fcn_active, fcn_file, fcn_name);
          fcn_list = [fcn_list, tmpfcn, "\n"];
        else
          tmpfcn = sprintf (li_fcn, fcn_file, fcn_name);
          fcn_list = [fcn_list, tmpfcn, "\n"];
        endif
      endfor
      ## Close ul and li tags and add empty line to separate categories
      fcn_list = [fcn_list "				</ul>\n"];
      fcn_list = [fcn_list "			</div>\n"];
      fcn_list = [fcn_list "			</div>\n"];
    endfor

    ## Populate function template with package info
    fnc_template = fileread (fullfile ("_layouts", "function_template.html"));
    fnc_template = strrep (fnc_template, "{{PKG_ICON}}", info.PKG_ICON);
    fnc_template = strrep (fnc_template, "{{PKG_NAME}}", info.PKG_NAME);
    fnc_template = strrep (fnc_template, "{{PKG_TITLE}}", info.PKG_TITLE);
    fnc_template = strrep (fnc_template, "{{CAT_NAME}}", catname);
    fnc_template = strrep (fnc_template, "{{OCTAVE_LOGO}}", info.OCTAVE_LOGO);
    fnc_template = strrep (fnc_template, "{{FCN_LIST}}", fcn_list);
    fnc_template = strrep (fnc_template, "{{FCN_NAME}}", fcnname);
    fnc_template = strrep (fnc_template, "{{FCN_TEXT}}", fcn_text);

    ## Populate default template
    default_template = fileread (fullfile ("_layouts", "default.html"));
    output_str = default_template;
    TITLE = sprintf ("%s: %s", info.PKG_TITLE, fcnname);
    output_str = strrep (output_str, "{{TITLE}}", TITLE);
    output_str = strrep (output_str, "{{BODY}}", fnc_template);

    ## Fix file separator in function names with @
    fcnfile = strrep (fcnname, filesep, "_");

    ## Write html to file
    fid = fopen ([fcnfile ".html"], "w");
    fprintf (fid, "%s", output_str);
    fclose (fid);
  catch
    printf ("Unable to process %s:\n %s\n", fcnname, lasterr);
  end_try_catch

endfunction

%!error function_texi2html (1)
%!error function_texi2html (1, 2)
%!error function_texi2html (1, cell (2))
%!error function_texi2html (1, cell (2), struct("PKG_ICON", {""}, ...
%! "PKG_NAME", {""}, "PKG_TITLE", {""}, "OCTAVE_LOGO", {""}))
%!error function_texi2html ("find_GHurls", "text" , struct("PKG_ICON", {""}, ...
%! "PKG_NAME", {""}, "PKG_TITLE", {""}, "OCTAVE_LOGO", {""}))
%!error function_texi2html ("find_GHurls", cell (2) , struct("field", {""}, ...
%! "PKG_NAME", {""}, "PKG_TITLE", {""}, "OCTAVE_LOGO", {""}))
