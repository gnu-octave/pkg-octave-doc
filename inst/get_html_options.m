## Copyright (C) 2008 Soren Hauberg <soren@hauberg.org>
## Copyright (C) 2014-2017 Julien Bect <jbect@users.sourceforge.net>
## Copyright (C) 2016 Fernando Pujaico Rivera <fernando.pujaico.rivera@gmail.com>
## Copyright (C) 2017 Olaf Till <i7tiol@t-online.de>
## Copyright (C) 2022 Kai T. Ohlhus <k.ohlhus@gmail.com>
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
## Given the string "octave", the design corresponds to the pages at
## @t{https://octave.org}. The pages are meant to be processed with the
## @code{m4} preprocessor, using the macros for the site.
##
## @seealso{generate_package_html, html_help_text}
## @end deftypefn

function options = get_html_options (argin)

  ## If option strings need parameterization, specify them as
  ## anonymous functions: @ (opts, pars, vpars) ... . The 3 arguments
  ## will be structures with parameter names as field names. 'opts'
  ## will contain parameters set as fields of the 'options' structure
  ## itself (e.g. 'charset'). 'pars' will contain all other parameters
  ## except the variable parameters. 'vpars' will contain the variable
  ## parameters, which currently are: 'name', 'pkgroot', 'root' (the
  ## latter is redundant and always 'fullfile ("..", pkgroot)').
  ##
  ## Within the generate_html package, option values are requested by
  ## the private 'getopt()' function, which performs parameterization
  ## of options.
  ##
  ## Even within this function, options potentially accepting
  ## parameters, like the options 'title' and 'body_command', must be
  ## accessed with 'getopt (, vpars)', i.e. 'getopt ("title", vpars)'
  ## instead of just 'opts.title'.
  ##
  ## This organization avoids the use of replacement strings and
  ## enables realizing the effect of an option by looking at this file
  ## only.

  if (nargin != 1)
    print_usage ();
  endif

  if (isstruct (argin))
    options = get_html_options_default (argin);
  elseif (ischar (argin) && strcmpi (argin, "octave"))
      options.header = @ (opts, pars, vpars) ...
        sprintf ("__HEADER__(`%s')", getopt ("title", vpars));
      options.footer = "__OCTAVE_TRAILER__";
      options.title  = @ (opts, pars, vpars) ...
                         sprintf ("Function Reference: %", vpars.name);
      options.include_overview = true;
  else
    error ("Input argument must be a string or a structure");
  endif

endfunction


function options = get_html_options_default (options)

  default = struct ();

  ## Create data files for alphabetical function lists ?
  default.include_alpha = false;

  ## Extract demos ?  (this option is used in html_help_text)
  default.include_demos = true;

  ## Create overview page ?  (list of functions, sorted by category)
  default.include_overview = true;

  ## Filename for overview page (used only if include_overview is true)
  ## %name can be used to denote the name of the package
  default.overview_filename = "index.html";

  ## Overview page.
  default.overview_title = @ (opts, pars, vpars) ...
    sprintf ("List of Functions for the '%s' package", pars.package);
  default.overview_body_command = @ (opts, pars, vpars) ...
                                    getopt ("body_command", vpars);
  default.overview_header = @ (opts, pars, vpars) ...
                              getopt ("header", vpars);
  default.overview_footer = @ (opts, pars, vpars) ...
                              getopt ("footer", vpars);

  ## News page.
  default.news_title = ...
  @ (opts, pars, vpars) sprintf ("Recent changes for the '%s' package",
                                 pars.package);
  default.news_body_command = @ (opts, pars, vpars) ...
                                getopt ("body_command", vpars);
  default.news_header = @ (opts, pars, vpars) ...
                          getopt ("header", vpars);
  default.news_footer = @ (opts, pars, vpars) ...
                          getopt ("footer", vpars);

  ## Copying page.
  default.copying_title = ...
  @ (opts, pars, vpars) sprintf ("Copying conditions for the '%s' package",
                                 pars.package);
  default.copying_body_command = @ (opts, pars, vpars) ...
                                   getopt ("body_command", vpars);;
  default.copying_header = @ (opts, pars, vpars) ...
                             getopt ("header", vpars);
  default.copying_footer = @ (opts, pars, vpars) ...
                             getopt ("footer", vpars);

  ## Create short_package_description files ?  (used by packages.php)
  default.include_package_list_item = false;

  ## Filename for short_package_description
  ## (used only if include_package_list_item is true)
  default.pkg_list_item_filename = "short_package_description";

  ## Create main package page ?  (index.html)
  default.include_package_page = false;

  ## Index page.
  default.index_title = ...
  @ (opts, pars, vpars) sprintf ("The '%s' package", pars.package);
  default.index_body_command = @ (opts, pars, vpars) ...
                                 getopt ("body_command", vpars);;
  default.index_header = @ (opts, pars, vpars) ...
                           getopt ("header", vpars);
  default.index_footer = @ (opts, pars, vpars) ...
                           getopt ("footer", vpars);

  ## Download link to be inserted on the main package page (index.html)
  ## Leave empty for no download link
  default.download_link = "";
  default.older_versions_download = "";
  default.repository_link = "";

  ## Create package licence page ?
  default.include_package_license = false;

  ## Create package news page ?
  default.include_package_news = false;

  ## Name of function directory (subdirectory of package directory).
  ## This directory will contain individual function pages.
  default.function_dir = "function";

  ## Handle to a function for processing "see also" links
  default.seealso = @ (opts, pars, vpars) @html_see_also_with_prefix;

  ## Variable values (%title, %body_command...) for individual function pages,
  ## and for special pages too (index, overview...) if the corresponding
  ## page-specific option is empty.
  default.title = @ (opts, pars, vpars) sprintf ("%s", vpars.name);
  default.body_command = "";
  default.header = @ (opts, pars, vpars) sprintf ("\
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\
 \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n\
<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">\n\
<head>\n\
  <meta http-equiv=\"content-type\" content=\"text/html; charset=%s\" />\n\
  <meta name=\"date\" content=\"%s\" />\n\
  <meta name=\"generator\" content=\"generate_html %s\" />\n\
  <title>%s</title>\n\
</head>\n\
<body>",
                                           opts.charset,
                                           pars.gen_date, pars.ghv,
                                           getopt ("title", vpars));
  default.footer = "</body>\n</html>";

  ## Style sheet (mandatory if style sheet is accessed in the
  ## header). Set to struct() by default to throw an error if used
  ## in strings without explicitly having set it.
  default.css = struct ();

  ## Encoding
  default.charset = "utf-8";

  ## Name of package documentation file (user manual). Leave empty if no
  ## documentation file is to be included. If not empty, the documentation
  ## file is assumed to be in the 'doc' subdirectory.
  default.package_doc = "";
  default.package_doc_options = "";

  ## Name of directory with project website files.
  default.website_files = "";

  default.extension = "tar.gz";

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

