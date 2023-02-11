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
## @deftypefn  {pkg-octave-doc} {} package_texi2html (@var{fcnname}, @var{pkgfcns}, @var{info})
##
## Generate HTML page for a particular package.
##
## @seealso{function_texi2html}
## @end deftypefn

function package_texi2html (pkgname)

  if (! ischar (pkgname))
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

  ## Create "assets" folder (if it exists, remove it and create new)
  asset = "assets";
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

  ## Copy octave logo
  sd = fullfile (file_in_loadpath ("octave-logo.svg"));
  [status, msg, msgid] = copyfile (sd, asset, "f");
  if (status != 1)
    error ("package_texi2html: cannot copy octave logo to %s directory.", asset);
  endif
  octave_logo = strcat (asset, "/octave-logo.svg");

  ## Get package's logo from /doc folder from package's installation directory
  ## If no .svg or .png image available, use pkg default icon from _layouts
  pkg_info = pkg ("list", pkgname);
  sd = fullfile (pkg_info{1}.dir, "doc");
  if (exist (fullfile (sd, [pkgname, ".png"])) == 2)
    pkg_icon = [pkgname, ".png"];
    sd = fullfile (sd, pkg_icon);
    [status, msg, msgid] = copyfile (sd, asset, "f");
    if (status != 1)
      error ("package_texi2html: cannot copy %s logo to %s directory.", pkgname, asset);
    endif
    pkg_icon = strcat (asset, "/", pkg_icon);
  elseif (exist (fullfile (sd, [pkgname, ".svg"])) == 2)
    pkg_icon = [pkgname, ".png"];
    sd = fullfile (sd, pkg_icon);
    [status, msg, msgid] = copyfile (sd, asset, "f");
    if (status != 1)
      error ("package_texi2html: cannot copy %s logo to %s directory.", pkgname, asset);
    endif
    pkg_icon = strcat (asset, "/", pkg_icon);
  else
    sd = fullfile (file_in_loadpath ("pkg.png"));
    [status, msg, msgid] = copyfile (sd, asset, "f");
    if (status != 1)
      error ("package_texi2html: cannot copy default package logo to %s directory.", asset);
    endif
    pkg_icon = [pkgname, ".png"];
    old_name = fullfile ("assets", "pkg.png");
    new_name = fullfile ("assets", pkg_icon);
    [err, msg] = rename (old_name, new_name);
    if (err)
      error ("package_texi2html: cannot rename pkg.png file.");
    endif
    pkg_icon = strcat (asset, "/", pkg_icon);
  endif

  ## Get package info
  pkg_info = pkg ("list", pkgname);
  pkg_ver = pkg_info{1}.version;
  pkg_date = pkg_info{1}.date;
  pkg_title = pkg_info{1}.title;
  pkg_descr = pkg_info{1}.description;

  ## Copy specific info for function_texi2html
  info.PKG_ICON = pkg_icon;
  info.PKG_NAME = pkgname;
  info.PKG_TITLE = pkg_title;
  info.OCTAVE_LOGO = octave_logo;

  ## Populate index template with package info
  index_template = fileread (fullfile ("_layouts", "index_template.html"));
  index_template = strrep (index_template, "{{PKG_ICON}}", pkg_icon);
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

  ## Populate categories with functions
  fcn_idx = 0;
  fcn_list = "";
  for i = 1:numel (cat)
    catname = cat(i).name;
    tmp1 = ["           <h3 class=""category"">\n"];
    tmp2 = sprintf ("             <a name=""%s"">%s", cat(i).name, cat(i).name);
    tmp3 = ["</a>\n           </h3>\n"];
    fcn_list = [fcn_list tmp1 tmp2 tmp3];
    for j = 1:numel (cat(i).fcns)
      fcnname = cat(i).fcns{j};
      fcnfile = strrep (fcnname, filesep, "_");
      tmp1 = strcat (["           <div class=""lead"">\n"], ...
                     ["             <b>\n             <a href="""]);
      tmp2 = sprintf ("%s.html"">%s</a>\n", fcnfile, fcnname);
      tmp3 = strcat (["             </b>\n           </div>\n"]);
      fcn_list = [fcn_list tmp1 tmp2 tmp3];
      fnc1 = get_first_help_sentence (fcnname, 240);
      tmp1 = ["           <div class=""ftext"">\n"];
      tmp2 = sprintf ("             %s\n           </div>\n", fnc1);
      fcn_list = [fcn_list tmp1 tmp2];

      ## Add function to list
      fcn_idx += 1;
      pkgfcns(fcn_idx) = {cat(i).fcns{j}};
    endfor
  endfor
  index_template = strrep (index_template, "{{PKG_FUNCTION_LIST}}", fcn_list);

  ## Build individual function html
  for i = 1:numel (cat)
    info.CAT_NAME = cat(i).name;
    for j = 1:numel (cat(i).fcns)
      fcnname = cat(i).fcns{j};
      function_texi2html (fcnname, pkgfcns, info);
    endfor
  endfor

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
  fprintf (fid, output_str);
  fclose (fid);

endfunction
