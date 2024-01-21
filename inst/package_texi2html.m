## Copyright (C) 2023 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefn  {pkg-octave-doc} {} package_texi2html (@var{pkgname})
## @deftypefnx {pkg-octave-doc} {[@var{pkgfcns}, @var{info}] =} package_texi2html (@var{pkgname})
##
## Generate HTML pages for an entire package.
##
## @code{package_texi2html} takes a single input argument, @var{pkgname}, which
## is a char string with the package's name whose HTML documentation need to be
## generated.  The function considers the current working path as the root
## directory of the built pages.  It creates an @qcode{index.html} page with the
## available functions (and their subdivision into separate categories) of the
## package according to its INDEX file.  Although the INDEX file (if absent) is
## automatically generated during the package's installation, it is best
## practice to include one in the package's source so there is full comtrol of
## the categorization among the functions.  Individual functions HTML pages area
## generated with @code{function_texi2html}.
##
## The generated pages follow the template of the Octave Packages GitHub Pages
## based on bootstrap 5 and the generated HTML code is based on the
## @qcode{index_template.html} and @qcode{default.html} layouts.
##
## For packages whose repository is available at GitHub, individual URLs to each
## function's location within the reposity are retrieved and used to add a link
## to source code in each function's page.  This requires an internet connection
## and @code{git} installed and available to the system's @code{$PATH}.  If not
## available, the source code link is omitted and the functions' HTML pages are
## generated without it.
##
## For the @code{package_texi2html} to work, the @qcode{texi2html} command line
## tool, version 1.82, must be installed and available to the system's
## @code{$PATH}.
##
## Optionally, @code{package_texi2html} can return two output arguments, namely
## @var{pkgfcns} and @var{info}, which are necessary for the @code{find_GHurls}
## and @code{function_texi2html} functions.  In such case, the HTML pages
## generation is skipped.  This is useful for building individual function pages
## without the need to regenerate the package's entire documentation.
##
## Examples:
##
## @example
## [pkgfcns, info] = package_texi2html ("pkg-octave-doc");
## pkgfcns = find_GHurls (info.PKG_URL, pkgfcns);
## function_texi2html ("find_GHurls", pkgfcns, info);
## @end example
##
## Returning arguments:
##
## @itemize
## @item
## @var{pkgfcns} is a Nx2 cell array containing the package's available
## functions (1st column) and their respective category (2nd column).
##
## @item
## @var{info} is a structure with the following fields:
##
## @multitable @columnfractions 0.2 0.8
## @headitem Field Name @tab Description
## @item @qcode{PKG_URL} @tab The URL to the package's repository at GitHub.
##
## @item @qcode{PKG_ICON} @tab The relative reference to the package's logo
## image which must be either in .svg or .png format and it is located in the
## newly created @code{assets/} folder inside the working directory.
##
## @item @qcode{PKG_NAME} @tab The package's name (e.g. "pkg-octave-doc")
##
## @item @qcode{PKG_TITLE} @tab The package's title (e.g. "Octave Package
## Documentation")
##
## @item @qcode{OCTAVE_LOGO} @tab The relative reference to Octave's logo, also
## located inside the @qcode{assets/} folder.
## @end multitable
## @end itemize
##
## @seealso{function_texi2html, find_GHurls, build_DEMOS}
## @end deftypefn

function [varargout] = package_texi2html (pkgname)

  if (! ischar (pkgname))
    print_usage ();
  endif

  if (nargout != 0 && nargout != 2)
    print_usage ();
  endif

  ## Check package exists and it is loaded
  pkg_loaded = 0;
  [desc, flag] = pkg ("describe", pkgname);
  if (strcmp (flag{:}, "Not installed"))
    error ("package_texi2html: %s package is not installed.", pkgname);
  elseif (strcmp (flag{:}, "Not loaded"))
    pkg ("load", pkgname);
    [desc, flag] = pkg ("describe", pkgname);
    pkg_loaded = 1;
  endif

  ## Get categories of functions available
  pkg_cat = desc{1}.provides;
  for i = 1:numel (pkg_cat)
    cat(i).name = pkg_cat{i}.category;
    cat(i).fcns = pkg_cat{i}.functions;
  endfor

  ## Build function list from package index
  fcn_idx = 0;
  for i = 1:numel (cat)
    for j = 1:numel (cat(i).fcns)
      ## Add function to list
      fcn_idx += 1;
      pkgfcns(fcn_idx, 1) = {cat(i).fcns{j}};
      pkgfcns(fcn_idx, 2) = {cat(i).name};
    endfor
  endfor

  ## Get package info
  pkg_info = pkg ("list", pkgname);
  pkg_ver = pkg_info{1}.version;
  pkg_date = pkg_info{1}.date;
  pkg_title = pkg_info{1}.title;
  pkg_descr = pkg_info{1}.description;
  info.PKG_URL = pkg_info{1}.url;

  ## Check if package repository is at GitHub
  GH = strfind (info.PKG_URL, "https://github.com/");
  if (GH == 1)
    pkgfcns = find_GHurls (info.PKG_URL, pkgfcns);
  endif

  ## Default folder for images
  asset = "assets";

  ## Default path for Octave logo
  octave_logo = strcat (asset, "/octave-logo.svg");

  ## Get package's logo from /doc folder from package's installation directory
  ## If no .svg or .png image available, use pkg default icon from _layouts
  sd = fullfile (pkg_info{1}.dir, "doc");
  if (exist (fullfile (sd, [pkgname, ".png"])) == 2)
    pkg_icon = [pkgname, ".png"];
    icon_exists = true;
  elseif (exist (fullfile (sd, [pkgname, ".svg"])) == 2)
    pkg_icon = [pkgname, ".svg"];
    icon_exists = true;
  else
    sd = fullfile (file_in_loadpath ("pkg.png"));
    pkg_icon = [pkgname, ".png"];
    icon_exists = false;
  endif

  ## Copy specific info for other functions
  info.PKG_ICON = strcat (asset, "/", pkg_icon);
  info.PKG_NAME = pkgname;
  info.PKG_TITLE = pkg_title;
  info.OCTAVE_LOGO = octave_logo;

  ## If output arguments are requested, return them here and skip
  ## creating the "assets" folder or any HTML files.
  if (nargout > 0)
    varargout{1} = pkgfcns;
    if (nargout > 1)
      varargout{2} = info;
    endif
    ## Unload package if it was loaded from this function
    if (pkg_loaded)
      pkg ("unload", pkgname);
    endif
    return;
  endif

  ## Create "assets" folder (if it exists, remove it and create new)
  if (exist (asset) == 7)
    confirm_recursive_rmdir (0, "local");
    [status, msg, msgid] = rmdir (asset, "s");
    if (status != 1)
      error ("package_texi2html: cannot remove %s directory.", asset);
    endif
  endif
  [status, msg, msgid] = mkdir (asset);
  if (status != 1)
    error ("package_texi2html: cannot create %s directory.", asset);
  endif

  ## Copy package's logo from /doc folder from package's installation directory
  ## of the pkg default icon from _layouts and rename it appropriately
  if (icon_exists)
    sd = fullfile (sd, pkg_icon);
    [status, msg, msgid] = copyfile (sd, asset, "f");
    if (status != 1)
      error ("package_texi2html: cannot copy %s logo to %s directory.", ...
             pkgname, asset);
    endif
  else
    sd = fullfile (file_in_loadpath ("pkg.png"));
    [status, msg, msgid] = copyfile (sd, asset, "f");
    if (status != 1)
      error (strcat (["package_texi2html: cannot copy default package"], ...
                     sprintf (" logo to %s directory.", asset)));
    endif
    old_name = fullfile ("assets", "pkg.png");
    new_name = fullfile ("assets", pkg_icon);
    [err, msg] = rename (old_name, new_name);
    if (err)
      error ("package_texi2html: cannot rename pkg.png file.");
    endif
  endif

  ## Copy octave logo
  sd = fullfile (file_in_loadpath ("octave-logo.svg"));
  [status, msg, msgid] = copyfile (sd, asset, "f");
  if (status != 1)
    error ("package_texi2html: cannot copy octave logo to %s directory.", asset);
  endif

  ## Populate index template with package info
  index_template = fileread (fullfile ("_layouts", "index_template.html"));
  index_template = strrep (index_template, "{{PKG_ICON}}", info.PKG_ICON);
  index_template = strrep (index_template, "{{PKG_NAME}}", pkgname);
  index_template = strrep (index_template, "{{PKG_TITLE}}", pkg_title);
  index_template = strrep (index_template, "{{OCTAVE_LOGO}}", octave_logo);
  index_template = strrep (index_template, "{{PKG_VERSION}}", pkg_ver);
  index_template = strrep (index_template, "{{PKG_DATE}}", pkg_date);
  index_template = strrep (index_template, "{{PKG_DESCRIPTION}}", pkg_descr);

  ## Start building index page according to categories and their functions
  ## Add category selector
  cat_text = "";
  tmp = strcat (["           <p>Select Category:\n"], ...
                ["             <select name=""cat"""], ...
                [" onchange=""location = this.options[this."], ...
                ["selectedIndex].value;"">\n"]);
  cat_text = [cat_text tmp];
  for i = 1:numel (cat)
    tmp = sprintf ("             <option value=""#%s"">%s</option>\n", ...
                   cat(i).name, cat(i).name);
    cat_text = [cat_text tmp];
  endfor
  cat_text = [cat_text "             </select>\n           <\p>\n"];
  index_template = strrep (index_template, "{{CATEGORY_SELECTOR}}", cat_text);

  ## Fixed HTML strings
  tmp_0 = "           <h3 class=""category"">\n";
  tmp_1 = "</a>\n           </h3>\n";
  tmp_2 = "           <table class=""table table-striped"">\n";
  tmp_3 = "             <tbody>\n";
  tmp_4 = "               <tr>\n                 <td>\n";
  tmp_5 = "                   <b><code>\n                   <a href=""";
  tmp_6 = "                   </code></b>\n                 </td>\n";
  tmp_7 = "               </tr>\n";
  tmp_8 = "             </tbody>\n";
  tmp_9 = "           </table>\n";

  ## Populate categories with functions
  fcn_list = "";
  for i = 1:numel (cat)
    catname = cat(i).name;
    tmp_cat = sprintf ("             <a name=""%s"">%s", catname, catname);
    fcn_list = [fcn_list tmp_0 tmp_cat tmp_1 tmp_2 tmp_3];
    for j = 1:numel (cat(i).fcns)
      fcnname = cat(i).fcns{j};
      fcnfile = strrep (fcnname, filesep, "_");
      tmp_fcn = sprintf ("%s.html"">%s</a>\n", fcnfile, fcnname);
      fcn_list = [fcn_list tmp_4 tmp_5 tmp_fcn tmp_6];
      fcnfirst = get_first_help_sentence (fcnname, 240);
      tmp_fcn = sprintf ("                 <td>%s</td>\n", fcnfirst);
      fcn_list = [fcn_list tmp_fcn tmp_7];
      ## Build individual function of classdef html
      try
        MTDS = methods (fcnname);
        classdef_texi2html (MTDS, pkgfcns, info);
      catch
        function_texi2html (fcnname, pkgfcns, info);
      end_try_catch
    endfor
    fcn_list = [fcn_list tmp_8 tmp_9];
  endfor
  index_template = strrep (index_template, "{{PKG_FUNCTION_LIST}}", fcn_list);

  ## Unload package if it was loaded from this function
  if (pkg_loaded)
    pkg ("unload", pkgname);
  endif

  ## Populate default template
  default_template = fileread (fullfile ("_layouts", "default.html"));
  output_str = default_template;
  output_str = strrep (output_str, "{{TITLE}}", pkg_title);
  output_str = strrep (output_str, "{{BODY}}", index_template);

  ## Write to html file
  fid = fopen ("index.html", "w");
  fprintf (fid, "%s", output_str);
  fclose (fid);

endfunction

%!error package_texi2html (1)
%!error package_texi2html (1, 2)
%!error package_texi2html ({"statistics"})
%!error out1 = package_texi2html ("statistics")
%!error [out1, out2, out3] = package_texi2html ("statistics")
%!error [pkgfcns, info] = package_texi2html ("st@t1st1cs")
%!error package_texi2html ("st@t1st1cs")
