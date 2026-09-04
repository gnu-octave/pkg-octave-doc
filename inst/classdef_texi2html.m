## Copyright (C) 2024-2026 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefnx {pkg-octave-doc} {} classdef_texi2html (@dots{}, @var{Name}, @var{Value})
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
## datatypes package, and never directly above a method: a comment run
## reaching down to one is that method's help text, so the banner would be
## documenting it.  Each public method is assigned to the most recent banner
## above its definition; groups whose methods are all non-public (@code{Hidden}
## or private) are omitted, and any public method before the first banner is
## collected under an @qcode{"Other"} group.
##
## The generated HTML is based on the @qcode{classdef_template.html} and
## @qcode{default.html} layouts; a grouped classdef additionally uses
## @qcode{group_template.html} for the method groups and
## @qcode{methodpage_template.html} for the per-method pages.
##
## @subsubheading Optional Name/Value pairs
##
## @multitable @columnfractions 0.2 0.8
## @headitem @var{Name} @tab @var{Value}
##
## @item @qcode{'figformat'} @tab The file format the demo figures are printed
## in, either @qcode{'png'} (default) or @qcode{'svg'}.  It applies to the demo
## figures of the class page and of every per-method page alike.
## @end multitable
##
## @seealso{package_texi2html, function_texi2html, find_GHurls, build_DEMOS}
## @end deftypefn

function classdef_texi2html (clsname, pkgfcns, info, varargin)

  if (nargin < 3)
    print_usage ();
  endif

  ## Parse optional Name/Value paired arguments
  [opts, args] = parse_pairs ({'figformat'}, {'png'}, varargin);
  if (! isempty (args))
    print_usage ();
  endif
  figformat = opts.figformat;
  if (! (ischar (figformat) && any (strcmpi (figformat, {'png', 'svg'}))))
    error ("classdef_texi2html: FIGFORMAT must be 'png' or 'svg'.");
  endif
  figformat = lower (figformat);

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

  ## Get methods while checking if clsname is an actual classdef.  The source
  ## is what decides and not methods, which answers for an old style class as
  ## well: such a class carries no properties at all, and its constructor and
  ## its methods are INDEX entries of their own, documented as functions.
  try
    srcfile = which (clsname);
    MTHDS = methods (clsname);
  catch
    error ("classdef_texi2html: '%s' is not classdef name", clsname);
  end_try_catch
  if (! __is_classdef__ (srcfile))
    error ("classdef_texi2html: '%s' is not classdef name", clsname);
  endif

  ## Remove constructor name from methods list.  A namespaced class is named
  ## by its stem in what methods reports, and a constructor kept out of the
  ## public surface is not reported at all, which is what keeps it unpublished.
  parts = strsplit (clsname, ".");
  stem = parts{end};
  has_cntr = any (strcmp (MTHDS, stem));
  MTHDS(strcmp (MTHDS, stem)) = [];

  ## Order methods according to the order they appear in classdef file
  MTHDS = get_methods_ordered (clsname, MTHDS);

  ## A "large" classdef groups its methods with banner comment blocks.  When
  ## such groups are found, the class is rendered with per-group collapsibles on
  ## the main page and a standalone page per method; otherwise the ordinary
  ## single-page layout (one collapsible per method) is used.  A published
  ## constructor is included in group detection so that, for a large classdef,
  ## it is listed within its banner group rather than floating above the groups.
  MTHDS_grp = MTHDS;
  if (has_cntr)
    MTHDS_grp{end+1} = stem;
  endif
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
      if (! isempty (url))
        url_text = strcat ("<p><strong>Source Code: </strong>\n", ...
                           "  <a href=""", url, """>", clsname, ...
                           "</a>\n</p>\n</div>");
        cls_text = strrep (cls_text, "</div>", url_text);
      endif
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
          demo_txt = __build_demos__ (prop_name, true, figformat);
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
      prop_num = __member_anchor__ (clsname, PROPS{p});
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
  cntr_name = [clsname "." stem];
  [text, format] = get_help_text (cntr_name);

  ## Only if the class publishes a constructor and texinfo is available
  if (has_cntr && ! is_large && strcmp (format, "texinfo"))
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
      demo_txt = __build_demos__ (cntr_name, true, figformat);
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
        demo_txt = __build_demos__ (method_name, true, figformat);
        mtds_text = [mtds_text "\n" demo_txt];
      else
        ## Any help text that is not texinfo, an empty one included: the
        ## branch has to be total, since both names below are consumed
        ## unconditionally and would otherwise carry the previous method's
        ## documentation, or nothing at all for the first one.
        mtds_text = sprintf ("<b><code>%s</code></b> is not documented.", ...
                             method_name);
        mtds_fs = "undocumented";
      endif
      ## Populate method template
      mtds_template = strrep (template, "{{METHOD_NAME}}", MTHDS{m});
      mtds_num = __member_anchor__ (clsname, MTHDS{m});
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
      grp_methods = strcat ("                  <table class=""table", ...
                            " table-striped"">\n", ...
                            "                    <tbody>\n");
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
                          pkgfcns, info, figformat);
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
        demo_html = __demo_notebook__ (body_block, clsname, d * 100, figformat);

        ## Populate demo template.  Anchor the collapse as "<class>-exampleN"
        ## (matching build_DEMOS' scheme) so the class docstring can link to a
        ## class-level demo with @url{#exampleN} and have it auto-open.
        demo_template = strrep (template, "{{DEMO_NUMBER}}", ...
                                sprintf ("%s-example%d", ...
                                         regexprep (clsname, "[^A-Za-z0-9]", "_"), d));
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
  cls_text = __retarget_members__ (cls_text);
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
%!error <classdef_texi2html: FIGFORMAT must be 'png' or 'svg'.>
%! classdef_texi2html ("find_GHurls", cell (2), struct (), 'figformat', 'gif');
%!error <Invalid call> classdef_texi2html ("find_GHurls", cell (2), struct (), 'nosuch', 1)

## The tests below reach the private members of the classdef path through this
## public entry point: get_method_groups and parse_method_groups decide whether
## a class is grouped and what each group holds, method_texi2html writes the
## page of a grouped class's method, and build_class_sidebar builds the
## navigation those pages carry.  None of the four can be named in a test
## block, which is evaluated in the scope of test.m rather than in this file's,
## so three fixture classes are written to a temporary directory and rendered,
## and the assertions read the pages that came out.  A fixture class declares
## no demos, so nothing here reaches __reset_classes__ and the rendered pages
## survive as shared variables.
##
## A banner stands between two methods blocks, as it does in a real classdef:
## a comment run reaching down to a method becomes that method's help text, so
## a banner written directly above one would be read as its documentation.

%!shared grouped, mthd, flat, hashed, plain, derived, base, files, hidc, nsc
%! d = fullfile (tempdir (), "pkg_octave_doc_cls_bist");
%! if (! isfolder (d))
%!   mkdir (d);
%! endif
%! src = {'## -*- texinfo -*-', ...
%!        '## @deftypefn {} {@var{obj} =} BistGrouped ()', ...
%!        '## A fixture class carrying banner groups.', ...
%!        '## @end deftypefn', ...
%!        'classdef BistGrouped', ...
%!        '  methods (Access = public)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {@var{obj} =} BistGrouped ()', ...
%!        '    ## Construct it.', ...
%!        '    ## @end deftypefn', ...
%!        '    function this = BistGrouped ()', ...
%!        '    endfunction', ...
%!        '', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {} m0 (@var{obj})', ...
%!        '    ## Declared before any banner.', ...
%!        '    ## @end deftypefn', ...
%!        '    function m0 (this)', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        '', ...
%!        '  ## ** Group One ** ##', ...
%!        '', ...
%!        '  methods (Access = public)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {} m1 (@var{obj})', ...
%!        '    ## First method.', ...
%!        '    ## @seealso{m2, BistFlat.m1, BistDerived.OwnProp,', ...
%!        '    ## BistGrouped.BistGrouped}', ...
%!        '    ## @end deftypefn', ...
%!        '    function m1 (this)', ...
%!        '    endfunction', ...
%!        '', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {[@var{a}, @var{b}] =} m2 (@var{obj})', ...
%!        '    ## Second method.', ...
%!        '    ## @end deftypefn', ...
%!        '    function [a, b] = m2 (this)', ...
%!        '      a = 1;', ...
%!        '      b = 2;', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        '', ...
%!        '  ## **    Padded Title    ** ##', ...
%!        '', ...
%!        '  methods (Access = public)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {@var{c} =} m3 (@var{obj})', ...
%!        '    ## Third method.', ...
%!        '    ## @end deftypefn', ...
%!        '    function c = m3 (this)', ...
%!        '      c = 3;', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        '', ...
%!        '  ## ** All Private ** ##', ...
%!        '', ...
%!        '  methods (Access = private)', ...
%!        '    function h1 (this)', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        'endclassdef'};
%! fid = fopen (fullfile (d, "BistGrouped.m"), "w");
%! fprintf (fid, "%s\n", src{:});
%! fclose (fid);
%! src = {'## -*- texinfo -*-', ...
%!        '## @deftypefn {} {@var{obj} =} BistFlat ()', ...
%!        '## A fixture class declaring no banner at all.', ...
%!        '## @end deftypefn', ...
%!        'classdef BistFlat', ...
%!        '  methods (Access = public)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {@var{obj} =} BistFlat ()', ...
%!        '    ## Construct it.', ...
%!        '    ## @end deftypefn', ...
%!        '    function this = BistFlat ()', ...
%!        '    endfunction', ...
%!        '', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {} m1 (@var{obj})', ...
%!        '    ## Only method.', ...
%!        '    ## @end deftypefn', ...
%!        '    function m1 (this)', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        'endclassdef'};
%! fid = fopen (fullfile (d, "BistFlat.m"), "w");
%! fprintf (fid, "%s\n", src{:});
%! fclose (fid);
%! src = {'## -*- texinfo -*-', ...
%!        '## @deftypefn {} {@var{obj} =} BistHash ()', ...
%!        '## A fixture class whose decoration carries no title.', ...
%!        '## @end deftypefn', ...
%!        'classdef BistHash', ...
%!        '  methods (Access = public)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {@var{obj} =} BistHash ()', ...
%!        '    ## Construct it.', ...
%!        '    ## @end deftypefn', ...
%!        '    function this = BistHash ()', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        '', ...
%!        '  ################################', ...
%!        '', ...
%!        '  methods (Access = public)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {} m1 (@var{obj})', ...
%!        '    ## Only method.', ...
%!        '    ## @end deftypefn', ...
%!        '    function m1 (this)', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        'endclassdef'};
%! fid = fopen (fullfile (d, "BistHash.m"), "w");
%! fprintf (fid, "%s\n", src{:});
%! fclose (fid);
%! src = {'## -*- texinfo -*-', ...
%!        '## @deftypefn {} {@var{obj} =} BistPlain ()', ...
%!        '## A fixture class documenting methods without texinfo.', ...
%!        '## @end deftypefn', ...
%!        'classdef BistPlain', ...
%!        '  methods (Access = public)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {@var{obj} =} BistPlain ()', ...
%!        '    ## Construct it.', ...
%!        '    ## @end deftypefn', ...
%!        '    function this = BistPlain ()', ...
%!        '    endfunction', ...
%!        '', ...
%!        '    ## A plain comment, and so not a texinfo help text.', ...
%!        '    function m1 (this)', ...
%!        '    endfunction', ...
%!        '', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {} m2 (@var{obj})', ...
%!        '    ## Second method.', ...
%!        '    ## @end deftypefn', ...
%!        '    function m2 (this)', ...
%!        '    endfunction', ...
%!        '', ...
%!        '    ## Another plain comment.', ...
%!        '    function m3 (this)', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        'endclassdef'};
%! fid = fopen (fullfile (d, "BistPlain.m"), "w");
%! fprintf (fid, "%s\n", src{:});
%! fclose (fid);
%! src = {'## -*- texinfo -*-', ...
%!        '## @deftypefn {} {@var{obj} =} BistBase ()', ...
%!        '## A fixture base class documenting a property.', ...
%!        '## @end deftypefn', ...
%!        'classdef (Abstract) BistBase', ...
%!        '  properties', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftp {BistBase} {property} InheritedProp', ...
%!        '    ##', ...
%!        '    ## Inherited property', ...
%!        '    ##', ...
%!        '    ## Documented on the abstract base class.', ...
%!        '    ##', ...
%!        '    ## @end deftp', ...
%!        '    InheritedProp = 1', ...
%!        '  endproperties', ...
%!        'endclassdef'};
%! fid = fopen (fullfile (d, "BistBase.m"), "w");
%! fprintf (fid, "%s\n", src{:});
%! fclose (fid);
%! src = {'## -*- texinfo -*-', ...
%!        '## @deftypefn {} {@var{obj} =} BistDerived ()', ...
%!        '## A fixture class inheriting a documented property.', ...
%!        '## @end deftypefn', ...
%!        'classdef BistDerived < BistBase', ...
%!        '  properties', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftp {BistDerived} {property} OwnProp', ...
%!        '    ##', ...
%!        '    ## Own property', ...
%!        '    ##', ...
%!        '    ## Documented on the subclass itself.', ...
%!        '    ##', ...
%!        '    ## @end deftp', ...
%!        '    OwnProp = 2', ...
%!        '  endproperties', ...
%!        '  methods (Access = public)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {@var{obj} =} BistDerived ()', ...
%!        '    ## Construct it.', ...
%!        '    ## @end deftypefn', ...
%!        '    function this = BistDerived ()', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        'endclassdef'};
%! fid = fopen (fullfile (d, "BistDerived.m"), "w");
%! fprintf (fid, "%s\n", src{:});
%! fclose (fid);
%! src = {'classdef BistHidCtor', ...
%!        '  ## -*- texinfo -*-', ...
%!        '  ## @deftp {} BistHidCtor', ...
%!        '  ## A class hiding the constructor it declares.', ...
%!        '  ## @end deftp', ...
%!        '  methods (Hidden)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {@var{obj} =} BistHidCtor ()', ...
%!        '    ## Construct it.', ...
%!        '    ## @end deftypefn', ...
%!        '    function this = BistHidCtor ()', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        '  methods (Access = public)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {} pubm (@var{obj})', ...
%!        '    ## A public method.', ...
%!        '    ## @end deftypefn', ...
%!        '    function pubm (this)', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        'endclassdef'};
%! fid = fopen (fullfile (d, "BistHidCtor.m"), "w");
%! fprintf (fid, "%s\n", src{:});
%! fclose (fid);
%! src = {'classdef BistGrpHid', ...
%!        '  ## -*- texinfo -*-', ...
%!        '  ## @deftp {} BistGrpHid', ...
%!        '  ## A grouped class hiding the constructor it declares.', ...
%!        '  ## @end deftp', ...
%!        '  methods (Hidden)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {@var{obj} =} BistGrpHid ()', ...
%!        '    ## Construct it.', ...
%!        '    ## @end deftypefn', ...
%!        '    function this = BistGrpHid ()', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        '', ...
%!        '  ## ** Group One ** ##', ...
%!        '', ...
%!        '  methods (Access = public)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {} m1 (@var{obj})', ...
%!        '    ## First method.', ...
%!        '    ## @end deftypefn', ...
%!        '    function m1 (this)', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        'endclassdef'};
%! fid = fopen (fullfile (d, "BistGrpHid.m"), "w");
%! fprintf (fid, "%s\n", src{:});
%! fclose (fid);
%! if (! isfolder (fullfile (d, "+bistns")))
%!   mkdir (fullfile (d, "+bistns"));
%! endif
%! src = {'classdef BistNs', ...
%!        '  ## -*- texinfo -*-', ...
%!        '  ## @deftp {} BistNs', ...
%!        '  ## A class living inside a namespace.', ...
%!        '  ## @end deftp', ...
%!        '  methods (Access = public)', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {@var{obj} =} BistNs ()', ...
%!        '    ## Construct it.', ...
%!        '    ## @end deftypefn', ...
%!        '    function this = BistNs ()', ...
%!        '    endfunction', ...
%!        '    ## -*- texinfo -*-', ...
%!        '    ## @deftypefn {} {} nsm (@var{obj})', ...
%!        '    ## A public method.', ...
%!        '    ## @end deftypefn', ...
%!        '    function nsm (this)', ...
%!        '    endfunction', ...
%!        '  endmethods', ...
%!        'endclassdef'};
%! fid = fopen (fullfile (d, "+bistns", "BistNs.m"), "w");
%! fprintf (fid, "%s\n", src{:});
%! fclose (fid);
%! ## An old style class: an @ directory whose constructor file declares no
%! ## classdef.  methods answers for it while properties does not, so what the
%! ## source declares is what has to decide which route documents it.
%! if (! isfolder (fullfile (d, "@BistOld")))
%!   mkdir (fullfile (d, "@BistOld"));
%! endif
%! src = {'## -*- texinfo -*-', ...
%!        '## @deftypefn {} {@var{obj} =} BistOld ()', ...
%!        '## An old style class constructor.', ...
%!        '## @end deftypefn', ...
%!        'function this = BistOld ()', ...
%!        '  this.x = 1;', ...
%!        '  this = class (this, "BistOld");', ...
%!        'endfunction'};
%! fid = fopen (fullfile (d, "@BistOld", "BistOld.m"), "w");
%! fprintf (fid, "%s\n", src{:});
%! fclose (fid);
%! addpath (d);
%! rehash ();
%! info = struct ("PKG_ICON", "pkg.png", "PKG_NAME", "bist", ...
%!                "PKG_TITLE", "Bist", "OCTAVE_LOGO", "octave-logo.svg");
%! pf = {"BistGrouped", "Cat"; "BistFlat", "Cat"; "BistHash", "Cat"; ...
%!       "BistDerived", "Cat"; "BistBase", "Cat"; "BistPlain", "Cat"; ...
%!       "BistHidCtor", "Cat"; "BistGrpHid", "Cat"; "bistns.BistNs", "Cat"};
%! oldpwd = pwd ();
%! unwind_protect
%!   cd (d);
%!   classdef_texi2html ("BistGrouped", pf, info);
%!   classdef_texi2html ("BistFlat", pf, info);
%!   classdef_texi2html ("BistHash", pf, info);
%!   classdef_texi2html ("BistDerived", pf, info);
%!   classdef_texi2html ("BistBase", pf, info);
%!   classdef_texi2html ("BistHidCtor", pf, info);
%!   classdef_texi2html ("BistGrpHid", pf, info);
%!   classdef_texi2html ("bistns.BistNs", pf, info);
%!   ## A class documenting its methods outside texinfo used to raise rather
%!   ## than render, so its failure is kept to the two tests that own it.
%!   try
%!     classdef_texi2html ("BistPlain", pf, info);
%!     plain = fileread ("BistPlain.html");
%!   catch
%!     plain = "";
%!   end_try_catch
%!   files = {dir("*.html").name};
%!   grouped = fileread ("BistGrouped.html");
%!   mthd = fileread ("BistGrouped.m1.html");
%!   flat = fileread ("BistFlat.html");
%!   hashed = fileread ("BistHash.html");
%!   derived = fileread ("BistDerived.html");
%!   base = fileread ("BistBase.html");
%!   hidc = fileread ("BistHidCtor.html");
%!   nsc = fileread ("bistns.BistNs.html");
%! unwind_protect_cleanup
%!   cd (oldpwd);
%! end_unwind_protect

%!test  # a class declaring no method at all is documented rather than raising
%! assert (any (strcmp (files, "BistBase.html")));
%! assert (! isempty (strfind (base, "InheritedProp")));
%! assert (! isempty (strfind (base, "Documented on the abstract base")));

%!test  # a class declaring no banner keeps the single-page layout
%! assert (any (strcmp (files, "BistFlat.html")));
%! assert (! any (strcmp (files, "BistFlat.m1.html")));
%! assert (! isempty (strfind (flat, "Only method.")));

%!test  # a '####' line carrying no title is not a banner
%! assert (any (strcmp (files, "BistHash.html")));
%! assert (! any (strcmp (files, "BistHash.m1.html")));
%! assert (! isempty (strfind (hashed, "Only method.")));

%!test  # a method whose help text is not texinfo is marked undocumented
%! assert (! isempty (strfind (plain, ...
%!                    "BistPlain.m1</code></b> is not documented")));
%! assert (! isempty (strfind (plain, ...
%!                    "BistPlain.m3</code></b> is not documented")));
%! assert (! isempty (strfind (plain, "Second method.")));

%!test  # such a method does not carry the documentation of the previous one
%! assert (numel (strfind (plain, "Second method.")), 1);

%!test  # a banner group gives every one of its methods a page of its own
%! assert (any (strcmp (files, "BistGrouped.m1.html")));
%! assert (any (strcmp (files, "BistGrouped.m3.html")));

%!test  # a method declaring several output arguments is collected too
%! assert (any (strcmp (files, "BistGrouped.m2.html")));

%!test  # the constructor of a grouped class is given a page of its own
%! assert (any (strcmp (files, "BistGrouped.BistGrouped.html")));

%!test  # two banners keep the order the class declares them in
%! i_one = strfind (grouped, ">Group One</h4>");
%! i_two = strfind (grouped, ">Padded Title</h4>");
%! assert (! isempty (i_one) && ! isempty (i_two));
%! assert (i_one(1) < i_two(1));

%!test  # a banner title padded with spaces is trimmed
%! assert (! isempty (strfind (grouped, ">Padded Title</h4>")));

%!test  # a method declared before any banner lands in a trailing Other group
%! i_two = strfind (grouped, ">Padded Title</h4>");
%! i_oth = strfind (grouped, ">Other</h4>");
%! assert (! isempty (i_oth));
%! assert (i_two(1) < i_oth(1));
%! assert (any (strcmp (files, "BistGrouped.m0.html")));

%!test  # a private method is left out, and an all-private group is omitted
%! assert (isempty (strfind (grouped, "All Private")));
%! assert (! any (strcmp (files, "BistGrouped.h1.html")));

%!test  # a method page carries the help text of that method
%! assert (! isempty (strfind (mthd, "First method.")));

%!test  # the sidebar of a method page links back to the class page
%! assert (! isempty (strfind (mthd, "<a href=\"BistGrouped.html\"")));

%!test  # the sidebar names a method page after its class and method
%! assert (! isempty (strfind (mthd, "href=\"BistGrouped.m2.html\"")));

%!test  # the method a page belongs to is the one rendered bold
%! i_act = strfind (mthd, "BistGrouped.m1.html\" class=");
%! i_bold = strfind (mthd, "fw-bolder");
%! assert (! isempty (i_bold));
%! assert (numel (i_bold), 1);
%! assert (i_act(end) < i_bold(1));

%!test  # the group holding that method is the one expanded
%! tog = "id=\"togList1\" type=\"checkbox\" checked";
%! assert (! isempty (strfind (mthd, tog)));

%!test  # a group holding no active method stays collapsed
%! assert (! isempty (strfind (mthd, "id=\"togList2\" type=\"checkbox\">")));

%!test  # the sidebar carries every group of the class
%! assert (! isempty (strfind (mthd, "<h6>Group One</h6>")));
%! assert (! isempty (strfind (mthd, "<h6>Padded Title</h6>")));
%! assert (! isempty (strfind (mthd, "<h6>Other</h6>")));

%!test  # a property inherited from a superclass is documented on the subclass
%! assert (! isempty (strfind (derived, "OwnProp")));
%! assert (! isempty (strfind (derived, "InheritedProp")));
%! assert (! isempty (strfind (derived, "Documented on the abstract base class.")));

%!test  # a constructor declared Hidden is neither published nor listed
%! assert (isempty (strfind (hidc, "colapsibleConstructor")));
%! assert (! isempty (strfind (hidc, "id=\"BistHidCtor_pubm\"")));
%! assert (isempty (strfind (hidc, "id=\"BistHidCtor_BistHidCtor\"")));

%!test  # a grouped class gives no page to a constructor declared Hidden
%! assert (! any (strcmp (files, "BistGrpHid.BistGrpHid.html")));
%! assert (any (strcmp (files, "BistGrpHid.m1.html")));

%!test  # a namespaced class publishes its constructor rather than listing it
%! assert (! isempty (strfind (nsc, "colapsibleConstructor")));
%! assert (! isempty (strfind (nsc, "id=\"bistns_BistNs_nsm\"")));
%! assert (isempty (strfind (nsc, "id=\"bistns_BistNs_BistNs\"")));

%!test  # a bare sibling name resolves to that method's page
%! assert (! isempty (strfind (mthd, "href=\"BistGrouped.m2.html\"")));

%!test  # a method of a flat class resolves to the class page and its anchor
%! assert (! isempty (strfind (mthd, "href=\"BistFlat.html#BistFlat_m1\"")));

%!test  # a property resolves to the anchor of the collapsible holding it
%! tgt = "href=\"BistDerived.html#BistDerived_OwnProp\"";
%! assert (! isempty (strfind (mthd, tgt)));

%!test  # the constructor of a grouped class resolves to its own page
%! tgt = "href=\"BistGrouped.BistGrouped.html\"";
%! assert (! isempty (strfind (mthd, tgt)));

%!test  # an old style class answers methods but is not a classdef
%! assert (! isempty (methods ("BistOld")));

%!error <classdef_texi2html: 'BistOld' is not classdef name>
%! info = struct ("PKG_ICON", "pkg.png", "PKG_NAME", "bist", ...
%!                "PKG_TITLE", "Bist", "OCTAVE_LOGO", "octave-logo.svg");
%! classdef_texi2html ("BistOld", {"BistOld", "Cat"}, info);

%!test  # remove the fixture directory
%! d = fullfile (tempdir (), "pkg_octave_doc_cls_bist");
%! rmpath (d);
%! delete (fullfile (d, "+bistns", "*.m"));
%! rmdir (fullfile (d, "+bistns"));
%! delete (fullfile (d, "@BistOld", "*.m"));
%! rmdir (fullfile (d, "@BistOld"));
%! delete (fullfile (d, "*.m"));
%! delete (fullfile (d, "*.html"));
%! rmdir (d);
%! assert (! isfolder (d));
