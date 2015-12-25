## Copyright (C) 2008 Soren Hauberg <soren@hauberg.org>
## Copyright (C) 2014, 2015 Julien Bect <jbect@users.sourceforge.net>
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
## @deftypefn {Function File} {@var{options} =} get_html_options (@var{project_name})
## Returns a structure containing design options for various project web sites.
##
## Given a string @var{project_name}, the function returns a structure containing
## various types of information for generating web pages for the specified project.
## Currently, the accepted values of @var{project_name} are
##
## @table @t
## @item "octave-forge"
## Design corresponding to the pages at @t{http://octave.sf.net}.
##
## @item "octave"
## Design corresponding to the pages at @t{http://octave.org}. The pages are
## meant to be processed with the @code{m4} preprocessor, using the macros for
## the site.
## @end table
## @seealso{generate_package_html, html_help_text}
## @end deftypefn

function options = get_html_options (argin)

  ## Check number of input arguments
  if (nargin != 1)
    print_usage ();
    error ("Not enough input arguments: exactly one argument was expected.");
  endif

  if (isstruct (argin))
    options = get_html_options_default (argin);
  elseif (ischar (argin))
    options = get_html_options_default (struct ());
    options = get_html_options_project (options, argin);
  else
    error ("Input argument must be a string or a structure");
  endif

endfunction


function options = get_html_options_default (options)

  default = struct ();

  ## Create data files for alphabetical function lists ?
  default.include_alpha = false;

  ## Extract demos ?  (this option is used in html_help_text)
  default.include_demos = false;

  ## Create overview page ?  (list of functions, sorted by category)
  default.include_overview = false;

  ## Filename for overview page (used only if include_overview is true)
  ## %name can be used to denote the name of the package
  default.overview_filename = "overview.html";
  
  ## Variable values (%title, %body_command...) for the overview page.
  default.overview_title = "List of Functions for the '%name' package";
  default.overview_body_command = "";
  default.overview_header = "";
  default.overview_footer = "";

  ## Variable values (%title, %body_command...) for the news page.
  default.news_title = "Recent changes for the '%name' package";
  default.news_body_command = "";
  default.news_header = "";
  default.news_footer = "";

  ## Variable values (%title, %body_command...) for the copying page.
  default.copying_title = "Copying conditions for the '%name' package";
  default.copying_body_command = "";
  default.copying_header = "";
  default.copying_footer = "";

  ## Create short_package_description files ?  (used by packages.php)
  default.include_package_list_item = false;

  ## Filename for short_package_description
  ## (used only if include_package_list_item is true)
  default.pkg_list_item_filename = "short_package_description";

  ## Create main package page ?  (index.html)
  default.include_package_page = false;
  
  ## Variable values (%title, %body_command...) for the index page.
  default.index_title = "The '%name' package";
  default.index_body_command = "";
  default.index_header = "";
  default.index_footer = "";
  
  ## Download link to be inserted on the main package page (index.html)
  ## Leave empty for no download link
  default.download_link = "";

  ## Create package licence page ?
  default.include_package_license = false;

  ## Create package news page ?
  default.include_package_news = false;

  ## Name of function directory (subdirectory of package directory).
  ## This directory will contain individual function pages.
  default.function_dir = "function";

  ## Handle to a function for processing "see also" links
  options.seealso = @html_see_also_with_prefix;

  ## Variable values (%title, %body_command...) for individual function pages,
  ## and for special pages too (index, overview...) if the corresponding
  ## page-specific option is empty.
  default.title = "%name";
  default.body_command = "";
  default.header = "\
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\
 \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n\
<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">\n\
<head>\n\
  <meta http-equiv=\"content-type\" content=\"text/html; charset=%charset\" />\n\
  <meta name=\"date\" content=\"%date\" />\n\
  <title>%title</title>\n\
</head>\n\
<body>";
  default.footer = "</body>\n</html>";

  ## Style sheet (mandatory if %css is used in the header)
  default.css = "";

  ## Encoding
  default.charset = "utf-8";
  
  ## Name of package documentation file (user manual). Leave empty if no
  ## documentation file is to be included. If not empty, the documentation
  ## file is assumed to be in the 'doc' subdirectory.
  default.package_doc = "";

  ## TODO: Warn about unknown options
  ##  (to be done once all known options are present in default)

  ## Provide default values for missing fields
  fn = fieldnames (default);
  for i = 1:(length (fn))
    if (! isfield (options, fn{i}))
      options.(fn{i}) = default.(fn{i});
    endif
  endfor

endfunction


function options = get_html_options_project (options, project_name)

  ## Generate options depending on project
  switch (lower (project_name))
    case "octave-forge"
      ## Basic HTML header
      options.header = "\
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n\
 \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n\
<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">\n\
  <head>\n\
  <meta http-equiv=\"content-type\" content=\"text/html; charset=%charset\" />\n\
  <meta name=\"date\" content=\"%date\"/>\n\
  <meta name=\"author\" content=\"The Octave-Forge Community\" />\n\
  <meta name=\"description\" content=\"Octave-Forge is a collection of packages\
   providing extra functionality for GNU Octave.\" />\n\
  <meta name=\"keywords\" lang=\"en\" content=\"Octave-Forge, Octave, extra packages\" />\n\
  <title>%title</title>\n\
  <link rel=\"stylesheet\" type=\"text/css\" href=\"%root%css\" />\n\
  <script src=\"%rootfixed.js\" type=\"text/javascript\"></script>\n\
  <script src=\"%rootjavascript.js\" type=\"text/javascript\"></script>\n\
  <link rel=\"shortcut icon\" href=\"%rootfavicon.ico\" />\n\
  </head>\n\
  <body %body_command>\n\
  <div id=\"top-menu\" class=\"menu\">\n\
   <table class=\"menu\">\n\
      <tr>\n\
        <td style=\"width: 90px;\" class=\"menu\" rowspan=\"2\">\n\
          <a name=\"top\">\n\
          <img src=\"%rootoct.png\" alt=\"Octave logo\" />\n\
          </a>\n\
        </td>\n\
        <td class=\"menu\" style=\"padding-top: 0.9em;\">\n\
          <big class=\"menu\">Octave-Forge</big><small class=\"menu\"> - Extra packages for GNU Octave</small>\n\
        </td>\n\
      </tr>\n\
      <tr>\n\
        <td class=\"menu\">\n\
\n\
 <a href=\"%rootindex.html\" class=\"menu\">Home</a> &middot;\n\
 <a href=\"%rootpackages.php\" class=\"menu\">Packages</a> &middot;\n\
 <a href=\"%rootdevelopers.html\" class=\"menu\">Developers</a> &middot;\n\
 <a href=\"%rootdocs.html\" class=\"menu\">Documentation</a> &middot;\n\
 <a href=\"%rootFAQ.html\" class=\"menu\">FAQ</a> &middot;\n\
 <a href=\"%rootbugs.html\" class=\"menu\">Bugs</a> &middot;\n\
 <a href=\"%rootarchive.html\" class=\"menu\">Mailing Lists</a> &middot;\n\
 <a href=\"%rootlinks.html\" class=\"menu\">Links</a> &middot;\n\
 <a href=\"http://octave.sourceforge.net/code.html\" class=\"menu\">Code</a>\n\
\n\
        </td>\n\
      </tr>\n\
    </table>\n\
  </div>\n\
<div id=\"left-menu\">\n\
  <h3>Navigation</h3>\n\
  <p class=\"left-menu\"><a class=\"left-menu-link\" href=\"%rootoperators.html\">Operators and Keywords</a></p>\n\
  <p class=\"left-menu\"><a class=\"left-menu-link\" href=\"%rootfunction_list.html\">Function List:</a></p>\n\
  <ul class=\"left-menu-list\">\n\
    <li class=\"left-menu-list\">\n\
      <a  class=\"left-menu-link\" href=\"%rootoctave/overview.html\">&#187; Octave core</a>\n\
    </li>\n\
    <li class=\"left-menu-list\">\n\
      <a  class=\"left-menu-link\" href=\"%rootfunctions_by_package.php\">&#187; by package</a>\n\
    </li>\n\
    <li class=\"left-menu-list\">\n\
      <a  class=\"left-menu-link\" href=\"%rootfunctions_by_alpha.php\">&#187; alphabetical</a>\n\
    </li>\n\
  </ul>\n\
  <p class=\"left-menu\"><a class=\"left-menu-link\" href=\"%rootdoxygen/html\">C++ API</a></p>\n\
</div>\n\
<div id=\"doccontent\">\n";

      ## CSS
      options.css = "octave-forge.css";

      ## Options for alphabetical lists
      options.include_alpha = true;

      ## Options for individual function pages
      options.body_command = 'onload="javascript:fix_top_menu (); javascript:show_left_menu ();"';
      options.index_footer = ...
        "<div id=\"sf_logo\">\n\
           <a href=\"http://sourceforge.net\">\
           <img src=\"http://sourceforge.net/sflogo.php?group_id=2888&amp;type=1\"\
            width=\"88\" height=\"31\" style=\"border: 0;\" alt=\"SourceForge.net Logo\"/>\
           </a>\n\
         </div>\n</div>\n</body>\n</html>\n";
      options.overview_footer = [ ...
        "<p>Package: <a href=\"index.html\">%package</a></p>\n" ...
        options.index_footer];
      options.footer = [ ...
        "<p>Package: <a href=\"%pkgrootindex.html\">%package</a></p>\n" ...
        options.index_footer];
      options.title = "Function Reference: %name";
      options.include_demos = true;
      options.seealso = @octave_forge_seealso;

      ## Options for overview page
      options.include_overview = true;
      options.overview_body_command = options.body_command;

      ## Options for package list page
      options.include_package_list_item = true;
      options.package_list_item = ...
"<h3 class=\"package_name\" id=\"%name\"><a class=\"package_name\" href=\"./%name/index.html\">%name</a></h3>\n\
<p class=\"package_desc\">%shortdescription</p>\n\
<p>\n\
<a class=\"package_link\" href=\"./%name/index.html\">details</a>\n\
<a class=\"download_link\" href=\"http://downloads.sourceforge.net/octave/%name-%version.%extension?download\">download</a>\n\
</p>\n";

      ## Options for index package
      options.index_title = "The '%name' Package";
      options.download_link = "http://downloads.sourceforge.net/octave/%name-%version.tar.gz?download";
      options.include_package_page = true;
      options.include_package_license = true;
      options.include_package_news = true;
      options.index_body_command = "onload=\"javascript:fix_top_menu ();\"";

    case "octave"
      options.header = "__HEADER__(`%title')";
      options.footer = "__OCTAVE_TRAILER__";
      options.title  = "Function Reference: %name";
      options.include_overview = true;

    otherwise
      error ("Unknown project name: %s", project_name);
  endswitch

endfunction
