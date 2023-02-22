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
## @seealso{package_texi2html, find_GHurls, build_DEMOS}
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
    [text, format] = get_help_text (fcnname);

    ## Scan text for @tex and @end tex tags and replace their bodies with
    ## a random string to be replaced later on, since fprintf will not process
    ## this corectly
    is_tex = 0;
    tex_beg = strfind (text, "@tex");
    tex_end = strfind (text, "@end tex") + 7;
    if (! isempty (tex_beg) && ! isempty (tex_end))
      symbols = ['a':'z' 'A':'Z' '0':'9'];
      for j = numel (tex_beg):-1:1
        tex(j).str = {};
        tex(j).tex = text([tex_beg(j):tex_end(j)]);
        tex(j).rep = {symbols(randi (length (symbols), 1,length (symbols)))};
        text = strrep (text, tex(j).tex, ["\n",tex(j).rep{:}]);
        is_tex = 1;
        ## Keep tex literals
        tex_idx = strfind (tex(j).tex, "$$");
        if (mod (numel (tex_idx), 2) == 0)
          tex_num = 0;
          for i = 1:2:numel (tex_idx)
            tex_num += 1;
            tex_tmp = [tex(j).tex([tex_idx(i):tex_idx(i+1)+1])];
            #tex_tmp = strrep (tex_tmp, "\\", "\\\\");
            tex(j).str(tex_num) = {tex_tmp};
          endfor
        else
          error ("function_texi2html: bad tex format in %s docstring.", ...
                 fcnname);
        endif
      endfor
    endif

    notex_b = strfind (text, "@ifnottex");
    notex_e = strfind (text, "@end ifnottex") + 12;
    if (is_tex && ! isempty (notex_b) && ! isempty (notex_e))
      for j = numel (notex_b):-1:1
        ntex = text([notex_b(j):notex_e(j)]);
        text = strrep (text, ntex, "");
      endfor
    endif

    ## Check that 'texi2html' exists in system's PATH
    [status, msg] = unix ("texi2html --version");
    if (status)
      error ("function_texi2html: 'texi2html' command-line tool is missing.");
    elseif (! strcmp (strtrim (msg), "1.82"))
      error ("function_texi2html: 'texi2html' version must be exactly 1.82.");
    endif

    ## Fix texi tags that 'texi2html' cannot process or generates error
    ## @qcode -> @code
    text = strrep (text, "@qcode", "@code");
    ## @abbr  -> @asis
    text = strrep (text, "@abbr", "@asis");

    ## Fix file separator in function names with @
    fcnfile = strrep (fcnname, filesep, "_");

    ## Save text to file
    fid = fopen (fcnfile, "w");
    fprintf (fid, "%s", text);
    fclose (fid);

    [status, ~] = unix (sprintf ("texi2html %s > /dev/null 2>&1", fcnfile));
    if (status)
      error ("function_texi2html: unable to convert to html.");
    endif

    ## Read generated html file and erase both html and its source
    fid = fopen ([fcnfile ".html"]);
    fcn_text = fscanf (fid, "%c", Inf);
    fclose (fid);
    delete (fcnfile, [fcnfile ".html"]);

    ## Remove content before <body> tag and after <hr size="1">
    txt_beg = strfind (fcn_text, "<body ");
    txt_end = strfind (fcn_text, "<hr size=""1"">") - 1;
    fcn_text = fcn_text([txt_beg:txt_end]);

    ## Remove <body *> tag
    bd_tag = strfind (fcn_text, "\n");
    fcn_text([1:bd_tag(1)+2]) = [];

    ## Remove index tags from function syntax
    dta_idx = strfind (fcn_text, "<dt><a name=""");
    dt_aidx = strfind (fcn_text, "</a>");
    for i = numel (dta_idx):-1:1
      fcn_text([dta_idx(i)+5:dt_aidx(i)+4]) = [];
    endfor

    ## Fix </dd></dl> positions and add left margin after 1st sentence
    fcn_text = strrep (fcn_text, "<dd>", "</dl>\n");
    pbeg_idx = strfind (fcn_text, "<p>");
    pend_idx = strfind (fcn_text, "</p>");
    tmp_str1 = fcn_text([pbeg_idx(1):pend_idx(1)+4]);
    fcn_text = strrep (fcn_text, tmp_str1, [tmp_str1, "<div class=""ms-5"">\n"]);

    ## Replace tex literal if exists
    if (is_tex)
      for j = numel (tex):-1:1
        tex_tmp = [];
        for i = 1:numel (tex(j).str)
          tex_tmp = strcat (tex_tmp, tex(j).str(i){:}, "\n");
        endfor
        fcn_text = strrep (fcn_text, tex(j).rep{:}, tex_tmp);
      endfor
    endif

    ## Fix @seealso tag if it exists
    see_idx = strfind (fcn_text, "@seealso{");
    if (! isempty (see_idx))
      seealso = fcn_text([see_idx:end]);
      new_see = ["<strong>See also: </strong>\n"];
      fnames = seealso([10:strfind(seealso, "}")-1]);
      fnames = strsplit (fnames, ",");
      fnames = strtrim (fnames);
      f_num = numel (fnames);
      for i = 1:f_num
        str = fnames{i};
        if (any (strcmp (pkgfcns(:,1), str)))
          str1 = strrep (str, filesep, "_");
          new_str = ["  <a href=""",str1,".html"">",str,"</a>"];
        else
          new_str = str;
        endif
        if (i < f_num)
          new_see = [new_see, new_str, (", \n")];
        else
          new_see = [new_see, new_str, "\n</p>\n</div>"];
        endif
      endfor
      fcn_text = strrep (fcn_text, seealso, new_see);
    else
      fcn_text = strrep (fcn_text, "</dd></dl>", "\n</div>");
    endif

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

    ## Populate function template with package info
    fnc_template = fileread (fullfile ("_layouts", "function_template.html"));
    fnc_template = strrep (fnc_template, "{{PKG_ICON}}", info.PKG_ICON);
    fnc_template = strrep (fnc_template, "{{PKG_NAME}}", info.PKG_NAME);
    fnc_template = strrep (fnc_template, "{{PKG_TITLE}}", info.PKG_TITLE);
    fnc_template = strrep (fnc_template, "{{CAT_NAME}}", catname);
    fnc_template = strrep (fnc_template, "{{OCTAVE_LOGO}}", info.OCTAVE_LOGO);
    fnc_template = strrep (fnc_template, "{{FCN_NAME}}", fcnname);
    fnc_template = strrep (fnc_template, "{{FCN_TEXT}}", fcn_text);

    ## Populate default template
    default_template = fileread (fullfile ("_layouts", "default.html"));
    output_str = default_template;
    TITLE = sprintf ("%s: %s", info.PKG_TITLE, fcnname);
    output_str = strrep (output_str, "{{TITLE}}", TITLE);
    output_str = strrep (output_str, "{{BODY}}", fnc_template);

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
