## Copyright (C) 2024 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefn  {pkg-octave-doc} {} classdef_texi2html (@var{clsname}, @var{pkgfcns}, @var{info})
##
## Generate HTML page for a class definition.
##
## @code{function_texi2html} requires three input arguments: @var{clsname}, a
## char string with the class' name; @var{pkgfcns}, a cell array with all
## available functions of a package; and @var{info}, a structure with relevant
## information about the package, which the function @var{clsname} belongs to.
##
## @var{pkgfcns} can be either a @math{Nx2} or a @math{Nx3} cell array, whose
## 1st column list all available function names, the 2nd column list the each
## function's category, and the 3rd column contains the URL to the function's
## source code.  @var{pkgfcns} is used to create relative references to other
## pages of functions which are listed in the @qcode{seealso} tag.  When a third
## column is present, @code{function_texi2html} uses it to add a source code
## link of the the function in @var{clsname}.
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
## @seealso{package_texi2html, function_texi2html, find_GHurls, build_DEMOS}
## @end deftypefn

function classdef_texi2html (clsname, pkgfcns, info)

  if (nargin != 3)
    print_usage ();
  endif

  if (! ischar (clsname))
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

  ## Check if clsname is an actual classdef
  try
    MTDS = methods (clsname);
  catch
    error ("classdef_texi2html: '%s' is not classdef name", clsname);
  end_try_catch

  ## Remove constructor name from methods list
  idx = find (cellfun (@(x) ! isempty(x), strfind (MTDS, clsname)));
  MTDS(idx) = [];

  ## Order methods according to the order they appear in classdef file
  MTDS = get_methods_ordered (clsname, MTDS);

  ## Add try catch to help identify classdef file that caused an issue
  ## during batch processing all functions in a package with package_texi2html
  try
    ## Get help text from class definition
    [text, format] = get_help_text (clsname);

    ## Build the HTML code for class definition
    cls_text = __texi2html__ (text, clsname, pkgfcns);

    ## Find the category the classdef belongs to
    fcn_idx = find (strcmp (pkgfcns(:,1), clsname));
    catname = pkgfcns{fcn_idx, 2};

    ## Add link to classdef's source code (if applicable)
    if (size (pkgfcns, 2) == 3)
      url = pkgfcns{fcn_idx, 3};
      url_text = strcat (["<p><strong>Source Code: </strong>\n"], ...
                         ["  <a href=""", url, """>", clsname, "</a>\n</div>"]);
      cls_text = strrep (cls_text, "</div>", url_text);
    endif
  catch
    printf ("Unable to process classdef '%s':\n %s\n", clsname, lasterr);
    return;
  end_try_catch

  ## Add collapsible cards with properties texinfo (if any)
  props = properties (clsname);
  if (! isempty (props))
    for p = 1:numel (props)
      ## Get help text from property
      prop_name = [clsname "." props{p}];
      [text, format] = get_help_text (prop_name);
      ## Only if texinfo is available
      if (strcmp (format, "texinfo"))
        try
          ## Build the HTML code for class constructor
          prop_text = __texi2html__ (text, prop_name, pkgfcns);
          ## Remove header
          idx = strfind (prop_text, "</dl>");
          idx = idx(1) + 5;
          prop_text = prop_text(idx:end);
          ## Load and populate property template
          filename = fullfile ("_layouts", "property_template.html");
          prop_template = fileread (filename);
          prop_template = strrep (prop_template, "{{PROPERTY_NAME}}", props{p});
          prop_num = sprintf ("collapse%d", p);
          prop_template = strrep (prop_template, "{{PROPERTY_NUMBER}}", prop_num);
          prop_template = strrep (prop_template, "{{PROPERTY_HELP}}", prop_text);
        catch
          prop_template = "";
          printf ("Unable to process property '%s' of class '%s':\n %s\n", ...
                  props{p}, clsname, lasterr);
        end_try_catch
        cls_text = [cls_text "\n" prop_template];
      endif
    endfor
  endif

  ## Build HTML code for constructor
  cntr_name = [clsname "." clsname];
  [text, format] = get_help_text (cntr_name);

  ## Only if texinfo is available
  if (strcmp (format, "texinfo"))
    try
      ## Build the HTML code for class constructor
      cntr_text = __texi2html__ (text, cntr_name, pkgfcns);
      ## Load constructor template
      filename = fullfile ("_layouts", "constructor_template.html");
      cntr_template = fileread (filename);
      cntr_template = strrep (cntr_template, "{{CONSTRUCTOR_NAME}}", clsname);
      cntr_template = strrep (cntr_template, "{{CONSTRUCTOR_HELP}}", cntr_text);
    catch
      cntr_template = "";
      printf ("Unable to process constructor of class '%s':\n %s\n", ...
              clsname, lasterr);
    end_try_catch
    cls_text = [cls_text "\n" cntr_template];
  endif

  ## Build HTML code for available methods
  for m = 1:numel (MTDS)
    method_name = [clsname "." MTDS{m}];
    ## Use custom get_help_text to get help text from methods contained in
    ## the classdef file, because core get_help_text returns help text from
    ## parrent class methods instead of the shadowing methods in the classdef
    text = get_methods_texinfo (clsname, MTDS{m});
    if (! isempty (text))
      try
        ## Build the HTML code for class method
        mtds_text = __texi2html__ (text, method_name, pkgfcns);

        ## Load method template
        mtds_template = fileread (fullfile ("_layouts", "method_template.html"));
        mtds_template = strrep (mtds_template, "{{METHOD_NAME}}", MTDS{m});
        mtds_template = strrep (mtds_template, "{{METHOD_HELP}}", mtds_text);
      catch
        mtds_template = "";
        printf ("Unable to process method '%s' of class '%s':\n %s\n", ...
                MTDS{m}, clsname, lasterr);
      end_try_catch
      cls_text = [cls_text "\n" mtds_template];
    endif
  endfor

  ## Add DEMOS (if applicable)
  demo_txt = build_DEMOS (clsname);
  cls_text = [cls_text "\n" demo_txt];

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
            "decoration-none font-monospace""><small>%s</small></a></li>"];
  li_fcn_active = ["					<li><a href=""%s.html"" class=""text-", ...
                   "decoration-none font-monospace fw-bolder"">", ...
                   "<small>%s</small></a></li>"];

  ## Build side bar function list
  fcn_list = "";
  cat_name = unique (pkgfcns(:,2), "stable");
  for i = 1:numel (cat_name)
    ## Expand current category
    if (strcmpi (cat_name{i}, catname))
      checkbox = " checked";
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
      if (strcmpi (fcn_name, clsname))
        tmpfcn = sprintf (li_fcn_active, fcn_file, fcn_name);
        fcn_list = [fcn_list, tmpfcn, "\n"];
      else
        tmpfcn = sprintf (li_fcn, fcn_file, fcn_name);
        fcn_list = [fcn_list, tmpfcn, "\n"];
      endif
    endfor
    ## Close ul and li tags and add empty line to separate categories
    fcn_list = [fcn_list "				</ul>\n"];
    fcn_list = [fcn_list "				</div>\n"];
    fcn_list = [fcn_list "			</div>\n"];
  endfor

  ## Populate classdef template with package info
  fnc_template = fileread (fullfile ("_layouts", "classdef_template.html"));
  fnc_template = strrep (fnc_template, "{{PKG_ICON}}", info.PKG_ICON);
  fnc_template = strrep (fnc_template, "{{PKG_NAME}}", info.PKG_NAME);
  fnc_template = strrep (fnc_template, "{{PKG_TITLE}}", info.PKG_TITLE);
  fnc_template = strrep (fnc_template, "{{CAT_NAME}}", catname);
  fnc_template = strrep (fnc_template, "{{OCTAVE_LOGO}}", info.OCTAVE_LOGO);
  fnc_template = strrep (fnc_template, "{{FCN_LIST}}", fcn_list);
  fnc_template = strrep (fnc_template, "{{CLS_NAME}}", clsname);
  fnc_template = strrep (fnc_template, "{{CLS_TEXT}}", cls_text);

  ## Populate default template
  default_template = fileread (fullfile ("_layouts", "default.html"));
  output_str = default_template;
  TITLE = sprintf ("%s: %s", info.PKG_TITLE, clsname);
  output_str = strrep (output_str, "{{TITLE}}", TITLE);
  output_str = strrep (output_str, "{{BODY}}", fnc_template);

  ## Write html to file
  try
    fid = fopen ([clsname ".html"], "w");
    fprintf (fid, "%s", output_str);
    fclose (fid);
  catch
    printf ("Unable to process class %s:\n %s\n", clsname, lasterr);
  end_try_catch

endfunction

%!error classdef_texi2html (1)
%!error classdef_texi2html (1, 2)
%!error classdef_texi2html (1, cell (2))
%!error classdef_texi2html (1, cell (2), struct("PKG_ICON", {""}, ...
%! "PKG_NAME", {""}, "PKG_TITLE", {""}, "OCTAVE_LOGO", {""}))
%!error classdef_texi2html ("find_GHurls", "text" , struct("PKG_ICON", {""}, ...
%! "PKG_NAME", {""}, "PKG_TITLE", {""}, "OCTAVE_LOGO", {""}))
%!error classdef_texi2html ("find_GHurls", cell (2) , struct("field", {""}, ...
%! "PKG_NAME", {""}, "PKG_TITLE", {""}, "OCTAVE_LOGO", {""}))
