## Copyright (C) 2024-2025 Andreas Bertsatos <abertsatos@biol.uoa.gr>
##
## This file is part of the pkg-octave-doc package for GNU Octave.
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
## @code{classdef_texi2html} requires three input arguments: @var{clsname}, a
## char string with the class' name; @var{pkgfcns}, a cell array with all
## available functions of a package; and @var{info}, a structure with relevant
## information about the package, which the function @var{clsname} belongs to.
##
## @var{pkgfcns} can be either a @math{Nx2} or a @math{Nx3} cell array, whose
## 1st column list all available function names, the 2nd column list the each
## function's category, and the 3rd column contains the URL to the function's
## source code.  @var{pkgfcns} is used to create relative references to other
## pages of functions which are listed in the @qcode{seealso} tag.  When a third
## column is present, @code{classdef_texi2html} uses it to add a source code
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
## @subsubheading Layout: grouped vs.@ lumped methods
##
## The class is rendered in one of two layouts, chosen automatically from the
## class source:
##
## @itemize
## @item A @strong{lumped} classdef (the default) becomes a @emph{single} page:
## the class help and its properties, then the constructor and one collapsible
## block per public method, each holding that method's help and demos.
##
## @item A @strong{grouped} classdef -- one whose methods are organised into
## named groups by banner comment blocks (see below) -- becomes a main page with
## the class help, the properties, and one collapsible block per @emph{group}.
## Each group lists its methods, each with a one-line description, linking to a
## standalone @qcode{@var{Class}.@var{method}.html} page.  Every public method
## (the constructor included) gets such a page, laid out like a function page
## but with a class-scoped sidebar (the groups and their methods) and a
## breadcrumb back to the package index and the class page; its source-code link
## points to the class source file.
## @end itemize
##
## A class counts as grouped when -- and only when -- its source holds at least
## one method-group @strong{banner}; this is never decided by the class' size or
## line count.  A banner is a comment block of the form
##
## @example
## @group
## ################################################################
## ##                     ** Group Name **                       ##
## ################################################################
## @end group
## @end example
##
## placed before a @code{methods} block, matching the convention used by the
## datatypes package.  Each public method is assigned to the most recent banner
## above its definition; groups whose methods are all non-public (@code{Hidden}
## or private) are omitted, and any public method before the first banner is
## collected under an @qcode{"Other"} group.
##
## The generated HTML is based on the @qcode{classdef_template.html} and
## @qcode{default.html} layouts; a grouped classdef additionally uses
## @qcode{group_template.html} for the method groups and
## @qcode{methodpage_template.html} for the per-method pages.
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

  ## Get methods while checking if clsname is an actual classdef
  try
    MTHDS = methods (clsname);
  catch
    error ("classdef_texi2html: '%s' is not classdef name", clsname);
  end_try_catch

  ## Remove constructor name from methods list
  idx = strcmp (MTHDS, clsname);
  MTHDS(idx) = [];

  ## Order methods according to the order they appear in classdef file
  MTHDS = get_methods_ordered (clsname, MTHDS);

  ## A "large" classdef groups its methods with banner comment blocks.  When
  ## such groups are found, the class is rendered with per-group collapsibles on
  ## the main page and a standalone page per method; otherwise the ordinary
  ## single-page layout (one collapsible per method) is used.  The constructor
  ## is included in group detection so that, for a large classdef, it is listed
  ## within its banner group rather than floating above the groups.
  MTHDS_grp = MTHDS;
  MTHDS_grp{end+1} = clsname;
  groups = get_method_groups (clsname, MTHDS_grp);
  is_large = ! isempty (groups);

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

    ## Replace class signature at the beginning of the HTML code
    ## inside the <dl></dl> tags with more appropriate formatting
    end_DL = strfind (cls_text, "</dl>")(1) + 5;
    cls_text(1:end_DL) = [];
    html_tag = "<dl><code><h5 class=""description"">%s: %s</h5></code></dl>\n";
    classsig = sprintf (html_tag, info.PKG_NAME, clsname);
    cls_text = [classsig cls_text];

    ## Add link to classdef's source code (if applicable)
    if (size (pkgfcns, 2) == 3)
      url = pkgfcns{fcn_idx, 3};
      url_text = strcat (["<p><strong>Source Code: </strong>\n", ...
                          "  <a href=""", url, """>", clsname, ...
                          "</a>\n</p>\n</div>"]);
      cls_text = strrep (cls_text, "</div>", url_text);
    endif
  catch
    printf ("Unable to process classdef '%s':\n %s\n", clsname, lasterr);
    return;
  end_try_catch

  ## Get properties
  PROPS = properties (clsname);

  ## Order properties according to the order they appear in classdef file
  PROPS = get_properties_ordered (clsname, PROPS);

  ## Build HTML code for available properties
  if (! isempty (PROPS))
    ## Add a one-line lead-in for the properties block
    prop_header = sprintf (strcat ("        <p class=""lead my-3"">The", ...
                                   " <code>%s</code> class contains the", ...
                                   " following properties:</p>\n"), clsname);
    cls_text = [cls_text "\n" prop_header];
    ## Load property template
    filename = fullfile ("_layouts", "property_template.html");
    template = fileread (filename);
    for p = 1:numel (PROPS)
      ## Get help text from property
      prop_name = [clsname "." PROPS{p}];
      [text, format] = get_help_text (prop_name);
      ## Only if texinfo is available
      if (strcmp (format, "texinfo"))
        try
          ## Build the HTML code for property
          prop_text = __texi2html__ (text, prop_name, pkgfcns);
          ## Grab first sentence
          prop_fs = get_text_first_sentence (prop_text);
          ## Remove texinfo header
          idx = strfind (prop_text, "</dl>");
          if (isempty (idx))
            idx = 1;
          else
            idx = idx(1) + 5;
          endif
          prop_text = prop_text(idx:end);
          ## Remove first sentence from text body
          idx = strfind (prop_text, prop_fs);
          if (! isempty (idx))
            idx = idx(1);
            len = length (prop_fs);
            prop_text(idx:idx+len) = [];
          endif
          ## Remove '<div class="ms-5">' and '</div>' from html text body
          idx = strfind (prop_text, '<div class="ms-5">');
          if (! isempty (idx))
            idx = idx(1);
            prop_text(idx:idx+18) = [];
          endif
          ## Strip the wrapper's closing tag: use the LAST </div> so inner
          ## divs in the body (e.g. a table's "table-responsive" wrapper) stay
          ## balanced -- otherwise everything after them nests inside them.
          idx = strfind (prop_text, '</div>');
          if (! isempty (idx))
            idx = idx(end);
            prop_text(idx:end) = [];
          endif
          ## Add DEMOS for properties (if applicable), collapsed by default
          demo_txt = build_DEMOS (prop_name, true);
          prop_text = [prop_text "\n" demo_txt];
        catch
          prop_text = "";
          prop_fs = "";
          printf ("Unusable texinfo in property '%s' of class '%s':\n %s\n", ...
                  PROPS{p}, clsname, lasterr);
        end_try_catch
      else
        prop_text = sprintf ("<b><code>%s</code></b> is not documented.", ...
                             prop_name);
        prop_fs = "undocumented";
      endif
      ## Populate property template
      prop_template = strrep (template, "{{PROPERTY_NAME}}", PROPS{p});
      prop_num = sprintf ("collapseProperty%d", p);
      prop_template = strrep (prop_template, "{{PROPERTY_NUMBER}}", prop_num);
      prop_template = strrep (prop_template, "{{PROPERTY_FS}}", prop_fs);
      prop_template = strrep (prop_template, "{{PROPERTY_HELP}}", prop_text);
      cls_text = [cls_text "\n" prop_template];
    endfor
  endif

  ## Add a one-line lead-in for the methods block
  meth_header = sprintf (strcat ("        <p class=""lead my-3"">The", ...
                                 " <code>%s</code> class offers the", ...
                                 " following public methods:</p>\n"), clsname);
  cls_text = [cls_text "\n" meth_header];

  ## Build HTML code for constructor.  In a large classdef the constructor is
  ## listed within its banner group (as a method page), so it is rendered inline
  ## here only for ordinary classdefs.
  cntr_name = [clsname "." clsname];
  [text, format] = get_help_text (cntr_name);

  ## Only if texinfo is available
  if (! is_large && strcmp (format, "texinfo"))
    try
      ## Build the HTML code for class constructor
      cntr_text = __texi2html__ (text, cntr_name, pkgfcns);
      ## Grab first sentence
      cntr_fs = get_text_first_sentence (cntr_text);
      ## Remove first sentence from text body
      idx = strfind (cntr_text, cntr_fs);
      if (! isempty (idx))
        idx = idx(1);
        len = length (cntr_fs);
        cntr_text(idx:idx+len) = [];
      endif
      ## Remove '<div class="ms-5">' and '</div>' from html text body
      idx = strfind (cntr_text, '<div class="ms-5">');
      if (! isempty (idx))
        idx = idx(1);
        cntr_text(idx:idx+18) = [];
      endif
      idx = strfind (cntr_text, '</div>');
      if (! isempty (idx))
        idx = idx(end);
        cntr_text(idx:end) = [];
      endif
    catch
      cntr_text = "";
      cntr_fs = "";
      printf ("Unusable texinfo in constructor of class '%s':\n %s\n", ...
              clsname, lasterr);
    end_try_catch
    if (isempty (cntr_text) && isempty (cntr_fs))
      cls_text = [cls_text "\n"];
    else
      ## Add DEMOS for constructor (if applicable), collapsed by default
      demo_txt = build_DEMOS (cntr_name, true);
      cntr_text = [cntr_text "\n" demo_txt];
      ## Load constructor template
      filename = fullfile ("_layouts", "constructor_template.html");
      cntr_template = fileread (filename);
      ## Populate constructor template
      cntr_template = strrep (cntr_template, "{{CONSTRUCTOR_NAME}}", clsname);
      cntr_template = strrep (cntr_template, "{{CONSTRUCTOR_FS}}", cntr_fs);
      cntr_template = strrep (cntr_template, "{{CONSTRUCTOR_HELP}}", cntr_text);
      cls_text = [cls_text "\n" cntr_template];
    endif
  endif

  ## Build HTML code for available methods
  if (! is_large)
    ## Ordinary classdef: one collapsible per method on the single page
    template = fileread (fullfile ("_layouts", "method_template.html"));
    for m = 1:numel (MTHDS)
      method_name = [clsname "." MTHDS{m}];
      ## Methods listed in MTHDS are already ensured to exist in the classdef
      ## file and not inherited from a parent class.
      [text, format] = get_help_text (method_name);
      ## Only if texinfo is available
      if (strcmp (format, "texinfo"))
        try
          ## Build the HTML code for class method
          mtds_text = __texi2html__ (text, method_name, pkgfcns);
          ## Grab first sentence
          mtds_fs = get_text_first_sentence (mtds_text);
          ## Remove first sentence from text body
          idx = strfind (mtds_text, mtds_fs);
          if (! isempty (idx))
            idx = idx(1);
            len = length (mtds_fs);
            mtds_text(idx:idx+len) = [];
          endif
          ## Remove '<div class="ms-5">' and '</div>' from html text body
          idx = strfind (mtds_text, '<div class="ms-5">');
          if (! isempty (idx))
            idx = idx(1);
            mtds_text(idx:idx+18) = [];
          endif
          idx = strfind (mtds_text, '</div>');
          if (! isempty (idx))
            idx = idx(end);
            mtds_text(idx:end) = [];
          endif
        catch
          mtds_text = "";
          mtds_fs = "";
          printf ("Unusable texinfo in method '%s' of class '%s':\n %s\n", ...
                  MTHDS{m}, clsname, lasterr);
        end_try_catch
        ## Add DEMOS for individual methods (if available), collapsed by default
        demo_txt = build_DEMOS (method_name, true);
        mtds_text = [mtds_text "\n" demo_txt];
      elseif (isempty (text))
        mtds_text = sprintf ("<b><code>%s</code></b> is not documented.", ...
                             method_name);
        mtds_fs = "undocumented";
      endif
      ## Populate method template
      mtds_template = strrep (template, "{{METHOD_NAME}}", MTHDS{m});
      mtds_num = sprintf ("collapseMethod%d", m);
      mtds_template = strrep (mtds_template, "{{METHOD_NUMBER}}", mtds_num);
      mtds_template = strrep (mtds_template, "{{METHOD_FS}}", mtds_fs);
      mtds_template = strrep (mtds_template, "{{METHOD_HELP}}", mtds_text);
      cls_text = [cls_text "\n" mtds_template];
    endfor
  else
    ## Large classdef: one collapsible per method GROUP listing its methods
    ## (each linking to a standalone page), then emit those method pages.
    grp_template = fileread (fullfile ("_layouts", "group_template.html"));
    for gi = 1:numel (groups)
      ## Build a table of the group's methods: linked name + first sentence
      grp_methods = strcat (["                  <table class=""table ", ...
                             "table-striped"">\n                    ", ...
                             "<tbody>\n"]);
      for mm = 1:numel (groups(gi).methods)
        mname = groups(gi).methods{mm};
        mfile = [strrep(clsname, filesep, "_") "." mname];
        [fs, st] = get_first_help_sentence ([clsname "." mname], 240);
        if (st != 0)
          fs = "";
        endif
        row = sprintf (["                      <tr>\n", ...
          "                        <td><b><code>", ...
          "<a href=""%s.html"">%s</a></code></b></td>\n", ...
          "                        <td>%s</td>\n", ...
          "                      </tr>\n"], mfile, mname, fs);
        grp_methods = [grp_methods row];
      endfor
      grp_methods = [grp_methods, "                    </tbody>\n", ...
                     "                  </table>\n"];
      ## Populate the group template
      gt = strrep (grp_template, "{{GROUP_NAME}}", groups(gi).name);
      gt = strrep (gt, "{{GROUP_NUMBER}}", sprintf ("collapseGroup%d", gi));
      gt = strrep (gt, "{{GROUP_METHODS}}", grp_methods);
      cls_text = [cls_text "\n" gt];
    endfor
    ## Emit a standalone page for every public method
    for gi = 1:numel (groups)
      for mm = 1:numel (groups(gi).methods)
        method_texi2html (clsname, groups(gi).methods{mm}, groups, ...
                          pkgfcns, info);
      endfor
    endfor
  endif

  ## Add DEMOS from classdef file (if applicable)
  DEMOS = find_DEMOS (clsname);
  if (! isempty (DEMOS))
    ## Add header for demos
    demo_header = strcat ("        <h4 class=""d-inline-block my-3"">\n", ...
                          "          Examples\n        </h4>\n");
    cls_text = [cls_text "\n" demo_header];
    ## Load classdemo template
    template = fileread (fullfile ("_layouts", "classdemo_template.html"));
    ## For each demo
    for d = 1:numel (DEMOS)
      try
        ## Split the leading comment run off as the collapsible label; the
        ## remaining source is rendered as an interleaved notebook.
        [demo_description, body_block] = get_demo_label (DEMOS{d});
        if (isempty (demo_description))
          demo_description = sprintf ("demo&nbsp;%s&nbsp;%d", clsname, d);
        endif

        ## Render the notebook HTML for the demo body
        demo_html = __demo_notebook__ (body_block, clsname, d * 100);

        ## Populate demo template.  Anchor the collapse as "<class>-exampleN"
        ## (matching build_DEMOS' scheme) so the class docstring can link to a
        ## class-level demo with @url{#exampleN} and have it auto-open.
        demo_template = strrep (template, "{{DEMO_NUMBER}}", ...
                                sprintf ("%s-example%d", ...
                                         strrep (clsname, filesep, "_"), d));
        demo_template = strrep (demo_template, "{{DEMO_DESCRIPTION}}", ...
                                demo_description);
        demo_template = strrep (demo_template, "{{DEMO_CODE}}", demo_html);
        demo_template = [demo_template "\n"];
        cls_text = [cls_text "\n" demo_template];
      catch
        printf ("Unable to process demo %d from %s:\n %s\n", ...
                d, clsname, lasterr);
      end_try_catch

      ## Reset classdef dispatch state so a demo cannot poison the ones that
      ## follow it (all demos of a package build share one Octave process).  See
      ## https://octave.discourse.group/t/octave-core-classdef-dispatch-bug/7633
      __reset_classes__ ();
    endfor
  endif

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

## Split off the leading comment run of a demo block: return it (marker-stripped
## and HTML-escaped) as the collapsible label DESC, and the remaining source as
## BODY to be rendered by __demo_notebook__.
function [desc, body] = get_demo_label (block)
  lines = strsplit (block, "\n", "collapsedelimiters", false);
  desc = "";
  k = 1;
  while (k <= numel (lines))
    t = strtrim (lines{k});
    if (isempty (t))
      k += 1;
    elseif (t(1) == "#" || t(1) == "%")
      desc = [desc, " ", regexprep(t, "^[#%]+ ?", "")];
      k += 1;
    else
      break;
    endif
  endwhile
  desc = strtrim (desc);
  desc = strrep (desc, "&", "&amp;");
  desc = strrep (desc, "<", "&lt;");
  desc = strrep (desc, ">", "&gt;");
  body = strjoin (lines(k:end), "\n");
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
