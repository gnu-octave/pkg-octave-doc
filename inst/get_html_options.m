## Copyright (C) 2008 Soren Hauberg
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
##
## @item "docbrowser"
## Design corresponding to the pages in the documentation browser.
## @end table
## @seealso{generate_package_html, html_help_text}
## @end deftypefn

function options = get_html_options (project_name)
  ## Check input
  if (nargin == 0)
    error ("get_html_options: not enough input arguments");
  endif
  
  if (!ischar (project_name))
    error ("get_html_options: first input argument must be a string");
  endif
  
  ## Generate options depending on project
  switch (lower (project_name))
    case "octave-forge"
      ## Basic HTML header
      hh = "\
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n\
 \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n\
<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">\n\
  <head>\n\
  <meta http-equiv=\"content-type\" content=\"text/html; charset=iso-8859-1\" />\n\
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
 <a href=\"index.html\" class=\"menu\">Home</a> &middot;\n\
 <a href=\"packages.html\" class=\"menu\">Packages</a> &middot;\n\
 <a href=\"developers.html\" class=\"menu\">Developers</a> &middot;\n\
 <a href=\"docs.html\" class=\"menu\">Documentation</a> &middot;\n\
 <a href=\"doc/index.html\" class=\"menu\">Function Reference</a> &middot;\n\
 <a href=\"FAQ.html\" class=\"menu\">FAQ</a> &middot;\n\
 <a href=\"bugs.html\" class=\"menu\">Bugs</a> &middot;\n\
 <a href=\"archive.html\" class=\"menu\">Mailing Lists</a> &middot;\n\
 <a href=\"links.html\" class=\"menu\">Links</a> &middot;\n\
 <a href=\"http://sourceforge.net/svn/?group_id=2888\" class=\"menu\">SVN</a>\n\
\n\
        </td>\n\
      </tr>\n\
    </table>\n\
  </div>\n\
<div id=\"left-menu-span\">\n\
<!--[if IE]>\n\
<table id=\"left-menu\">\n\
  <tr><td>\n\
    <div id=\"menu-contents\">\n\
    </div>\n\
  </td></tr>\n\
</table>\n\
<![endif]-->\n\
</div>\n\
<div id=\"doccontent\">\n";

      ## CSS
      options.css = "octave-forge.css";
    
      ## Options for individual function pages
      options.pack_body_cmd = 'onload="javascript:fix_top_menu (); javascript:package_menu ();"';
      options.header = strrep (hh, "%date", date ());
      options.footer = "</div>\n</body>\n</html>\n";
      options.title = "Function Reference: %name";
      options.include_demos = true;
      
      ## Options for overview page
      #options.overview_header = strrep (strrep (hh, "%date", date ()), "%body_command", "");
      options.manual_body_cmd = 'onload="javascript:fix_top_menu (); javascript:manual_menu ();"';
    
      ## Options for index package
      options.download_link = "http://downloads.sourceforge.net/octave/%name-%version.tar.gz?download";
      
    case "octave"
      options.header = "__HEADER__(`%title')";
      options.footer = "__OCTAVE_TRAILER__";
      options.title = "Function Reference: %name";
      
    case "docbrowser"
      ## Basic HTML header
      hh = "\
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n\
 \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n\
<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">\n\
  <head>\n\
  <meta http-equiv=\"content-type\" content=\"text/html; charset=iso-8859-1\" />\n\
  <meta name=\"date\" content=\"%date\"/>\n\
  <meta name=\"author\" content=\"The Octave Community\" />\n\
  <title>%title</title>\n\
  <link rel=\"stylesheet\" type=\"text/css\" href=\"%css\" />\n\
  </head>\n\
<body>\n\
<div id=\"top\">Function Reference</div>\n\
<div id=\"doccontent\">\n";
      hh = strrep (hh, "%date", date ());
    
      ## Options for individual function pages
      css = "doc.css";
      options.header = strrep (hh, "%css", css);
      options.footer = "</div>\n</body>\n</html>\n";
      options.title = "Function: %name";
      options.include_demos = true;
          
      ## Options for overview page
      options.overview_header = strrep (hh, "%css", sprintf ("../%s", css));
      options.overview_title = "Overview: %name";
      
    otherwise
      error ("get_html_options: unknown project name: %s", project_name);
  endswitch

endfunction
