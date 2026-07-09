## Copyright (C) 2026 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefn  {pkg-octave-doc} {} method_texi2html (@var{clsname}, @var{method}, @var{groups}, @var{pkgfcns}, @var{info})
##
## Generate a standalone HTML page for a single method of a large classdef.
##
## The page is function-like (help text, source-code link, and notebook demos)
## but carries a @emph{class-scoped} sidebar (the banner @var{groups} of
## @var{clsname}, built by @code{build_class_sidebar}) and a breadcrumb back to
## the package index and the class page.  It is written to
## @qcode{@var{Class}.@var{method}.html}.
##
## @var{method} is the method name, @var{groups} the struct array from
## @code{parse_method_groups}, and @var{pkgfcns}/@var{info} the package function
## list and info structure (as for @code{function_texi2html}).  The source-code
## link, when available, points to the class source file.
##
## @seealso{classdef_texi2html, build_class_sidebar, function_texi2html}
## @end deftypefn

function method_texi2html (clsname, method, groups, pkgfcns, info)

  if (nargin != 5 || ! ischar (clsname) || ! ischar (method) ...
      || ! isstruct (groups) || ! iscell (pkgfcns) || ! isstruct (info))
    print_usage ();
  endif

  clsfile = strrep (clsname, filesep, "_");
  method_name = [clsname "." method];

  try
    ## Build HTML from the method's texinfo help
    [text, format] = get_help_text (method_name);
    if (strcmp (format, "texinfo"))
      fcn_text = __texi2html__ (text, method_name, pkgfcns);
    else
      fcn_text = sprintf (["            <div class=\"card-text\">\n", ...
                           "<p><b><code>%s</code></b> is not documented.</p>\n", ...
                           "            </div>"], method_name);
    endif

    ## Add link to the class source file (methods share the class file)
    cls_idx = find (strcmp (pkgfcns(:,1), clsname));
    if (size (pkgfcns, 2) == 3 && ! isempty (cls_idx))
      url = pkgfcns{cls_idx, 3};
      if (! isempty (url))
        url_text = strcat (["<p><strong>Source Code: </strong>\n"], ...
                           ["  <a href=""", url, """>", clsname, "</a>\n</div>"]);
        fcn_text = strrep (fcn_text, "</div>", url_text);
      endif
    endif

    ## Add DEMOS (if applicable)
    demo_txt = build_DEMOS (method_name);
    fcn_text = [fcn_text "\n" demo_txt];

    ## Class-scoped sidebar (groups -> methods) with this method active
    fcn_list = build_class_sidebar (clsname, groups, method);

    ## Breadcrumb: package index > class > method (the constructor is labelled)
    if (strcmp (method, clsname))
      crumb = [method " (constructor)"];
    else
      crumb = method;
    endif
    breadcrumb = sprintf (["              <nav aria-label=\"breadcrumb\">\n", ...
      "                <ol class=\"breadcrumb\">\n", ...
      "                  <li class=\"breadcrumb-item\">", ...
      "<a href=\"index.html\">%s</a></li>\n", ...
      "                  <li class=\"breadcrumb-item\">", ...
      "<a href=\"%s.html\">%s</a></li>\n", ...
      "                  <li class=\"breadcrumb-item active\" ", ...
      "aria-current=\"page\">%s</li>\n", ...
      "                </ol>\n              </nav>\n"], ...
      info.PKG_NAME, clsfile, clsname, crumb);

    ## The class's package category, for the top navbar link
    catname = pkgfcns{cls_idx, 2};

    ## Populate the method-page template
    tmpl = fileread (fullfile ("_layouts", "methodpage_template.html"));
    tmpl = strrep (tmpl, "{{PKG_ICON}}", info.PKG_ICON);
    tmpl = strrep (tmpl, "{{PKG_NAME}}", info.PKG_NAME);
    tmpl = strrep (tmpl, "{{PKG_TITLE}}", info.PKG_TITLE);
    tmpl = strrep (tmpl, "{{CAT_NAME}}", catname);
    tmpl = strrep (tmpl, "{{OCTAVE_LOGO}}", info.OCTAVE_LOGO);
    tmpl = strrep (tmpl, "{{CLS_NAME}}", clsname);
    tmpl = strrep (tmpl, "{{CLS_FILE}}", clsfile);
    tmpl = strrep (tmpl, "{{FCN_LIST}}", fcn_list);
    tmpl = strrep (tmpl, "{{FCN_NAME}}", method_name);
    tmpl = strrep (tmpl, "{{BREADCRUMB}}", breadcrumb);
    tmpl = strrep (tmpl, "{{FCN_TEXT}}", fcn_text);

    ## Populate default template
    default_template = fileread (fullfile ("_layouts", "default.html"));
    output_str = strrep (default_template, "{{TITLE}}", ...
                         sprintf ("%s: %s", info.PKG_TITLE, method_name));
    output_str = strrep (output_str, "{{BODY}}", tmpl);

    ## Write html to file
    fid = fopen ([clsfile "." method ".html"], "w");
    fprintf (fid, "%s", output_str);
    fclose (fid);
  catch
    printf ("Unable to process method '%s' of class '%s':\n %s\n", ...
            method, clsname, lasterr);
  end_try_catch

endfunction

%!error <Invalid call> method_texi2html (1)
%!error <Invalid call> method_texi2html ("table", "head")
%!error <Invalid call> method_texi2html ("table", "head", struct(), cell (2))
