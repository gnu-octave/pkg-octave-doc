## Copyright (C) 2024-2025 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefn  {pkg-octave-doc} {@var{html_txt} =} __texi2html__ (@var{text}, @var{fcnname}, @var{pkgfcns})
##
## Private function to generate HTML text from texinfo.
##
## @end deftypefn

function html_txt = __texi2html__ (text, fcnname, pkgfcns)

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
      ## now replace only the last occurrance of tex(j).tex in text
      text1 = text(1:tex_beg(j)-1);
      text2 = text(tex_end(j)+1:end);
      text = [text1, tex(j).rep{:}, text2];
      is_tex = 1;
      ## Keep tex literals
      tex_idx = strfind (tex(j).tex, "$$");
      tex_num = 0;
      if (numel (tex_idx) > 0) && (mod (numel (tex_idx), 2) == 0)
        for i = 1:2:numel (tex_idx)
          tex_num += 1;
          tex_tmp = [tex(j).tex([tex_idx(i):tex_idx(i+1)+1])];
          #tex_tmp = strrep (tex_tmp, "\\", "\\\\");
          tex(j).str(tex_num) = {tex_tmp};
        endfor
      endif
      tex_idx = strfind (tex(j).tex, "\\(");
      tex_idx_e = strfind (tex(j).tex, "\\)");
      if (numel (tex_idx) > 0 && numel (tex_idx) == numel (tex_idx_e))
        for i = 1:1:numel (tex_idx)
          tex_num += 1;
          tex_tmp = [tex(j).tex([tex_idx(i):tex_idx_e(i)+1])];
          tex(j).str(tex_num) = {tex_tmp};
        endfor
      endif
      if tex_num == 0
        error ("__texi2html__: bad tex format in %s docstring.", ...
               fcnname);
      endif
    endfor
  endif

  notex_b = strfind (text, "@ifnottex");
  notex_e = strfind (text, "@end ifnottex") + 12;
  if (is_tex && ! isempty (notex_b) && ! isempty (notex_e))
    for j = numel (notex_b):-1:1
      ## Replace only the last occurrance of current non-tex expression
      text1 = text(1:notex_b(j)-1);
      text2 = text(notex_e(j)+1:end);
      if (text2(1) == "\n")
        text2 = text2(2:end);
      endif
      text = [text1, text2];
    endfor
  endif

  ## Check that 'texi2html' exists in system's PATH
  [status, msg] = unix ("texi2html --version");
  if (status)
    error ("__texi2html__: 'texi2html' command-line tool is missing.");
  elseif (! strcmp (strtrim (msg), "1.82"))
    error ("__texi2html__: 'texi2html' version must be exactly 1.82.");
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
    error ("__texi2html__: unable to convert to html.");
  endif

  ## Read generated html file and erase both html and its source
  fid = fopen ([fcnfile ".html"]);
  html_txt = fscanf (fid, "%c", Inf);
  fclose (fid);
  delete (fcnfile, [fcnfile ".html"]);

  ## Remove content before <body> tag and after <hr size="1">
  txt_beg = strfind (html_txt, "<body ");
  txt_end = strfind (html_txt, "<hr size=""1"">") - 1;
  html_txt = html_txt([txt_beg:txt_end]);

  ## Remove <body *> tag
  bd_tag = strfind (html_txt, "\n");
  if (bd_tag(1)+2 > length (html_txt))
    error ("__texi2html__: no texinfo found.");
  endif
  html_txt([1:bd_tag(1)+2]) = [];

  ## Remove index tags from function syntax
  dta_idx = strfind (html_txt, "<dt><a name=""");
  dt_aidx = strfind (html_txt, "</a>");
  for i = numel (dta_idx):-1:1
    html_txt([dta_idx(i)+5:dt_aidx(i)+4]) = [];
  endfor

  ## Fix </dd></dl> positions and replace tags in function syntax list from:
  ## <dt><u>pkg:</u> <var>B</var> = <b>fcnname</b><i> (<var>A</var>)</i></dt>
  ## to:
  ## <h5><code>pkg: <var>B</var> = <b>fcnname</b> (<var>A</var>)</code></h5>
  html_txt = strrep (html_txt, "<dd>", "</dl>\n");
  html_txt = strrep (html_txt, "<dt><u>", "<h5 class=""fs""><code>");
  html_txt = strrep (html_txt, "</u>", "");
  html_txt = strrep (html_txt, "<i>", "");
  html_txt = strrep (html_txt, "</i></dt>", "</code></h5>");

  ## Add left margin after 1st sentence
  pbeg_idx = strfind (html_txt, "<p>");
  pend_idx = strfind (html_txt, "</p>");
  tmp_str1 = html_txt([pbeg_idx(1):pend_idx(1)+4]);
  html_txt = strrep (html_txt, tmp_str1, [tmp_str1, "<div class=""ms-5"">\n"]);

  ## Replace <em> and </em> tags with <math> and </math>, respectively.
  ## Evaluate each case whether it conforms to size dimensions and replace
  ## 'x' or '*' with '&times;'.
  ## alphanumeric chars
  html_txt = strrep (html_txt, "<em>", "<math>");
  html_txt = strrep (html_txt, "</em>", "</math>");
  math_beg = strfind (html_txt, "<math>") + 6;
  math_end = strfind (html_txt, "</math>") - 1;
  if (! isempty (math_beg) && ! isempty (math_end))
    times_idx = [];
    for j = numel (math_beg):-1:1
      math_txt = html_txt([math_beg(j):math_end(j)]);
      char_idx = [strchr(math_txt, "x") strchr(math_txt, "*")];
      if (! isempty (char_idx))
        char_idx = math_beg(j) + char_idx - 1;
        times_idx = [times_idx char_idx];
      endif
    endfor
    times_idx = sort (times_idx);
    for j = numel (times_idx):-1:1
      html_txt = strcat (html_txt([1:times_idx(j)-1]), "&times;", ...
                         html_txt([times_idx(j)+1:end]));
    endfor
  endif

  ## Replace tex literal if exists
  if (is_tex)
    for j = numel (tex):-1:1
      tex_tmp = [];
      for i = 1:numel (tex(j).str)
        tex_tmp = strcat (tex_tmp, tex(j).str(i){:});
      endfor
      html_txt = strrep (html_txt, tex(j).rep{:}, tex_tmp);
    endfor
  endif

  ## References @ref, @xref, and @pxref (@seealso handled seprately at end)
  ## If a legacy class member is referred to, it has to be entered with a
  ## double '@@', like, e.g. @xref{@@class/member} in order to avoid errors
  ## in makeinfo.

  ref_strings = {"@xref{","@pxref{","@ref{"};
  new_ref = {"See ","see ",""};
  ref_len = zeros (1, length(ref_strings));
  ref_regexp = "(";
  for i = 1:length (ref_strings)
    if (i == 1)
      sep = "";
    else
      sep = "|";
    endif
    ref_len(i) = length (ref_strings{i});
    ref_regexp = [ ref_regexp, sep, ref_strings{i} ];
  endfor
  ref_regexp = [ ref_regexp, ")" ];

  [ref_idx,~,~,matched_strings] = regexp (html_txt, ref_regexp);
  for i = length(ref_idx):-1:1
    text_idx = ref_idx(i);                      # index in help text
    matched_idx = find (strcmp (ref_strings, matched_strings{i}))(1); # matched ref index
    text_from_ref = html_txt([text_idx:end]);   # get all text from ref on
    ref_text = new_ref{matched_idx};            # get the new ref text
    remaining = strfind(text_from_ref, "}")(1); # get closing brace
    remaining_text = text_from_ref([remaining+1:end]);  # get text after closing brace
    fnames = text_from_ref([ref_len(matched_idx)+1:remaining-1]); # get referred function names
    fnames = strrep (fnames, "@@", "@");        # restore correct class character
    fnames = strsplit (fnames, ",");
    fnames = strtrim (fnames);
    f_num = numel (fnames);
    ## Create html links for all functions
    for j = 1:f_num
      str = fnames{j};
      if (any (strcmp (pkgfcns(:,1), str)))
        str1 = strrep (str, filesep, "_");
        new_str = ["<a href=""",str1,".html"">",str,"</a>"];
      else
        new_str = str;
      endif
      if (j < f_num)
        ref_text = [ref_text, new_str, (", \n")];
      else
        ref_text = [ref_text, new_str];
      endif
    endfor
    ## Replace the ref-command by the html code including links
    html_txt = strrep (html_txt, text_from_ref, [ref_text, remaining_text]);
  endfor

  ## Fix @seealso tag if it exists
  see_idx = strfind (html_txt, "@seealso{");
  if (! isempty (see_idx))
    seealso = html_txt([see_idx:end]);
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
    html_txt = strrep (html_txt, seealso, new_see);
  else
    html_txt = strrep (html_txt, "</dd></dl>", "\n</div>");
  endif

endfunction
