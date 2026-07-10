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
## @deftypefn  {pkg-octave-doc} {@var{html_txt} =} __texi2html__ (@var{text}, @var{fcnname}, @var{pkgfcns})
##
## Private function to generate HTML text from texinfo.
##
## This is a native Octave implementation that converts the texinfo help
## @var{text} of a function or class member into the HTML fragment consumed by
## @code{function_texi2html} and @code{classdef_texi2html}.  It replaces the
## former dependency on the external @qcode{texi2html} command line tool.
## @var{fcnname} is used in error messages and @var{pkgfcns} (the package
## function list) is used to resolve @code{@@ref}/@code{@@xref}/@code{@@seealso}
## cross references to other pages.
##
## @end deftypefn

function html_txt = __texi2html__ (text, fcnname, pkgfcns)

  ## Normalise line endings.
  text = strrep (text, "\r\n", "\n");
  text = strrep (text, "\r", "\n");

  ## Strip a leading "-*- texinfo -*-" marker line, if present.
  midx = strfind (text, "-*- texinfo -*-");
  if (! isempty (midx))
    nl = strfind (text(midx(1):end), "\n");
    if (! isempty (nl))
      text = text(midx(1)+nl(1):end);
    else
      text = "";
    endif
  endif

  ## Resolve @tex / @ifnottex; math literals come back as placeholders.
  [text, texkeys, texvals] = i_handle_tex (text, fcnname);

  ## Delete standalone @noindent lines (transparent to layout).
  if (! isempty (strfind (text, "@noindent")))
    text = i_strip_lines (text, {"@noindent"});
  endif

  ## Split into lines, preserving empty ones.
  lines = strsplit (text, "\n", "collapsedelimiters", false);

  ## --- Header: one or more @deftypefn/@deftypefnx, or a single @deftp ---
  sigs = {};
  k = 1;
  nL = numel (lines);
  while (k <= nL)
    lt = strtrim (lines{k});
    if (isempty (lt) && isempty (sigs))
      ## skip blank lines preceding the signature (get_help_text prepends one)
      k += 1;
      continue;
    elseif (i_iscmd (lt, "@deftypefnx") || i_iscmd (lt, "@deftypefn") ...
        || i_iscmd (lt, "@deftp"))
      ## Join texinfo line-continuations: a signature that ends with "@"
      ## continues on the next line (Octave wraps long @deftypefn lines).
      full = deblank (lt);
      while (! isempty (full) && full(end) == "@" && k < nL)
        full = [full(1:end-1), strtrim(lines{k+1})];
        k += 1;
        full = deblank (full);
      endwhile
      sigs{end+1} = i_parse_sig (strtrim (full), pkgfcns);
      k += 1;
    else
      break;
    endif
  endwhile

  if (isempty (sigs))
    error ("__texi2html__: no texinfo found in %s docstring.", fcnname);
  endif

  ## Body runs until the closing @end deftypefn / @end deftp.
  body_lines = {};
  while (k <= nL)
    lt = strtrim (lines{k});
    if (i_iscmd (lt, "@end deftypefn") || i_iscmd (lt, "@end deftp"))
      break;
    endif
    body_lines{end+1} = lines{k};
    k += 1;
  endwhile

  ## Signature block.
  sig_html = "<dl>\n";
  for i = 1:numel (sigs)
    sig_html = [sig_html, sigs{i}, "\n"];
  endfor
  sig_html = [sig_html, "</dl>\n"];

  ## Pull out @seealso (rendered separately, placed last inside the div).
  [body_lines, seealso_html] = i_extract_seealso (body_lines, pkgfcns);

  ## Parse the body into a list of HTML blocks (first = summary paragraph).
  blocks = i_parse_body (body_lines, pkgfcns);

  if (isempty (blocks))
    summary = "<p>\n</p>\n";
    rest = "";
  else
    summary = blocks{1};
    rest = strjoin (blocks(2:end), "");
  endif

  html_txt = [sig_html, summary, "<div class=\"ms-5\">\n", ...
              rest, seealso_html, "</div>"];

  ## Restore protected @tex literals verbatim.
  for i = 1:numel (texkeys)
    html_txt = strrep (html_txt, texkeys{i}, texvals{i});
  endfor

endfunction

## ================================================================= helpers

## True if trimmed line LT begins with command CMD on a word boundary
## (so "@item" does not match "@itemize"/"@itemx").
function tf = i_iscmd (lt, cmd)
  L = numel (cmd);
  if (numel (lt) < L || ! strncmp (lt, cmd, L))
    tf = false;
  elseif (numel (lt) == L)
    tf = true;
  else
    c = lt(L+1);
    tf = ! (isalpha (c) || (c >= "0" && c <= "9"));
  endif
endfunction

function tf = i_isopener (lt)
  tf = (i_iscmd (lt, "@itemize") || i_iscmd (lt, "@enumerate") ...
        || i_iscmd (lt, "@table") || i_iscmd (lt, "@multitable") ...
        || i_iscmd (lt, "@example") || i_iscmd (lt, "@verbatim"));
endfunction

## HTML-escape only (used for code contexts and attribute-safe text).
function s = i_esc (s)
  s = strrep (s, "&", "&amp;");
  s = strrep (s, "<", "&lt;");
  s = strrep (s, ">", "&gt;");
  s = strrep (s, "\"", "&quot;");
endfunction

## Running-text escaping: HTML plus texinfo smart quotes and dashes.
function s = i_text (s)
  s = i_esc (s);
  s = strrep (s, "---", "&mdash;");
  s = strrep (s, "--", "&ndash;");
  s = strrep (s, "``", "&ldquo;");
  s = strrep (s, "''", "&rdquo;");
  s = strrep (s, "`", "&lsquo;");
  s = strrep (s, "'", "&rsquo;");
endfunction

function text = i_strip_lines (text, pats)
  lines = strsplit (text, "\n", "collapsedelimiters", false);
  keep = true (1, numel (lines));
  for i = 1:numel (lines)
    lt = strtrim (lines{i});
    for j = 1:numel (pats)
      if (strcmp (lt, pats{j}))
        keep(i) = false;
      endif
    endfor
  endfor
  text = strjoin (lines(keep), "\n");
endfunction

## --- @tex / @ifnottex resolution -----------------------------------------
function [text, keys, vals] = i_handle_tex (text, fcnname)
  keys = {};
  vals = {};
  n = 0;
  do
    b = strfind (text, "@tex");
    e = strfind (text, "@end tex");
    if (isempty (b) || isempty (e))
      break;
    endif
    b = b(1);
    e = e(1);
    block = text(b:e+7);              # "@tex ... @end tex"
    lit = i_tex_literals (block);
    if (isempty (lit))
      error ("__texi2html__: bad tex format in %s docstring.", fcnname);
    endif
    n += 1;
    key = ["\x01tex", num2str(n), "\x01"];
    keys{end+1} = key;
    vals{end+1} = lit;
    text = [text(1:b-1), key, text(e+8:end)];
  until (false)

  hastex = (n > 0);
  if (hastex)
    ## Drop @ifnottex ... @end ifnottex blocks entirely.
    do
      b = strfind (text, "@ifnottex");
      e = strfind (text, "@end ifnottex");
      if (isempty (b) || isempty (e))
        break;
      endif
      b = b(1);
      e = e(1) + 12;                  # end of "@end ifnottex"
      tail = text(e+1:end);
      if (! isempty (tail) && tail(1) == "\n")
        tail = tail(2:end);
      endif
      text = [text(1:b-1), tail];
    until (false)
  elseif (! isempty (strfind (text, "@ifnottex")))
    ## No @tex: keep @ifnottex content, just remove the wrapper lines.
    text = i_strip_lines (text, {"@ifnottex", "@end ifnottex"});
  endif
endfunction

function lit = i_tex_literals (block)
  lit = "";
  ## $$ ... $$ pairs
  idx = strfind (block, "$$");
  if (numel (idx) >= 2 && mod (numel (idx), 2) == 0)
    for i = 1:2:numel (idx)
      lit = [lit, block(idx(i):idx(i+1)+1)];
    endfor
  endif
  ## \( ... \) pairs
  ib = strfind (block, "\\(");
  ie = strfind (block, "\\)");
  if (! isempty (ib) && numel (ib) == numel (ie))
    for i = 1:numel (ib)
      lit = [lit, block(ib(i):ie(i)+1)];
    endfor
  endif
endfunction

## --- signature line ------------------------------------------------------
function dt = i_parse_sig (line, pkgfcns)
  p = strfind (line, "{");
  if (isempty (p))
    dt = ["<dt><code><h5 class=\"fs\">", i_text(strtrim(line)), ...
          "</code></h5></dt>"];
    return;
  endif
  p = p(1);
  [cat, p] = i_grab (line, p);
  while (p <= numel (line) && line(p) == " ")
    p += 1;
  endwhile
  ret = "";
  if (p <= numel (line) && line(p) == "{")
    [ret, p] = i_grab (line, p);
  endif
  rest = strtrim (line(p:end));
  sp = find (rest == " " | rest == "(", 1);
  if (isempty (sp))
    name = rest;
    args = "";
  else
    name = rest(1:sp-1);
    args = rest(sp:end);
  endif

  cat_html = i_inline (cat, pkgfcns);
  ret_html = i_inline (ret, pkgfcns);
  name_html = i_inline (name, pkgfcns);
  args_html = i_inline (args, pkgfcns);

  body = " ";
  if (! isempty (ret_html))
    body = [body, ret_html, " "];
  endif
  body = [body, "<b>", name_html, "</b>", args_html];

  dt = ["<dt><code><h5 class=\"fs\">", cat_html, ":", body, ...
        "</code></h5></dt>"];
endfunction

## --- @seealso extraction -------------------------------------------------
function [body_lines, html] = i_extract_seealso (body_lines, pkgfcns)
  html = "";
  txt = strjoin (body_lines, "\n");
  p = strfind (txt, "@seealso{");
  if (isempty (p))
    return;
  endif
  p = p(1);
  [names, ~] = i_grab (txt, p + 8);
  q = strfind (txt(p:end), "}");
  txt = [txt(1:p-1), txt(p+q(1):end)];
  body_lines = strsplit (txt, "\n", "collapsedelimiters", false);
  html = i_seealso_html (names, pkgfcns);
endfunction

function html = i_seealso_html (names, pkgfcns)
  names = strtrim (strsplit (names, ","));
  html = "<p> <strong>See also: </strong>\n";
  for i = 1:numel (names)
    s = strrep (names{i}, "@@", "@");
    if (any (strcmp (pkgfcns(:,1), s)))
      f = strrep (s, filesep, "_");
      link = ["  <a href=\"", f, ".html\">", s, "</a>"];
    else
      link = s;
    endif
    if (i < numel (names))
      html = [html, link, ", \n"];
    else
      html = [html, link, "\n"];
    endif
  endfor
  html = [html, "</p>\n"];
endfunction

## --- body scanning -------------------------------------------------------
## Scan a region of lines into a list of elements: each is a struct with
## fields .kind ("para"|"block") and .data (raw text | finished HTML).
function elems = i_scan (lines, pkgfcns)
  elems = struct ("kind", {}, "data", {});
  para = {};
  i = 1;
  N = numel (lines);
  while (i <= N)
    ln = lines{i};
    lead = i_lead (ln);
    if (isempty (lead))
      [elems, para] = i_flush (elems, para);
      i += 1;
    elseif (lead != "@")
      para{end+1} = ln;               # plain text line: no command scan needed
      i += 1;
    else
      lt = strtrim (ln);
    if (i_iscmd (lt, "@multitable"))
      [elems, para] = i_flush (elems, para);
      [blk, i] = i_parse_multitable (lines, i, pkgfcns);
      elems(end+1) = struct ("kind", "block", "data", blk);
    elseif (i_iscmd (lt, "@itemize"))
      [elems, para] = i_flush (elems, para);
      [blk, i] = i_parse_list (lines, i, pkgfcns, "ul", "@end itemize");
      elems(end+1) = struct ("kind", "block", "data", blk);
    elseif (i_iscmd (lt, "@enumerate"))
      [elems, para] = i_flush (elems, para);
      [blk, i] = i_parse_list (lines, i, pkgfcns, "ol", "@end enumerate");
      elems(end+1) = struct ("kind", "block", "data", blk);
    elseif (i_iscmd (lt, "@table"))
      [elems, para] = i_flush (elems, para);
      [blk, i] = i_parse_table (lines, i, pkgfcns);
      elems(end+1) = struct ("kind", "block", "data", blk);
    elseif (i_iscmd (lt, "@example"))
      [elems, para] = i_flush (elems, para);
      [blk, i] = i_parse_example (lines, i, pkgfcns);
      elems(end+1) = struct ("kind", "block", "data", blk);
    elseif (i_iscmd (lt, "@verbatim"))
      [elems, para] = i_flush (elems, para);
      [blk, i] = i_parse_verbatim (lines, i);
      elems(end+1) = struct ("kind", "block", "data", blk);
    elseif (i_iscmd (lt, "@subheading"))
      [elems, para] = i_flush (elems, para);
      title = strtrim (lt(numel("@subheading")+1:end));
      anchor = strrep (title, " ", "-");
      blk = ["<a name=\"", anchor, "\"></a>\n", ...
             "<h3 class=\"subheading\">", i_inline(title,pkgfcns), "</h3>\n\n"];
      elems(end+1) = struct ("kind", "block", "data", blk);
      i += 1;
    else
      para{end+1} = ln;
      i += 1;
    endif
    endif
  endwhile
  [elems, para] = i_flush (elems, para);
endfunction

## First non-whitespace character of a line ("" if blank/empty).  Cheaper
## than strtrim and lets scanners skip command checks on plain text lines.
function c = i_lead (ln)
  k = find (! isspace (ln), 1);
  if (isempty (k))
    c = "";
  else
    c = ln(k);
  endif
endfunction

function [elems, para] = i_flush (elems, para)
  if (! isempty (para))
    elems(end+1) = struct ("kind", "para", "data", strjoin (para, "\n"));
    para = {};
  endif
endfunction

## Top-level body: every paragraph is <p>-wrapped; returns a cell of HTML
## blocks so the caller can peel off the summary.
function blocks = i_parse_body (lines, pkgfcns)
  elems = i_scan (lines, pkgfcns);
  blocks = {};
  for i = 1:numel (elems)
    if (strcmp (elems(i).kind, "para"))
      blocks{end+1} = ["<p>", i_inline(elems(i).data, pkgfcns), "\n</p>\n"];
    else
      blocks{end+1} = elems(i).data;
    endif
  endfor
endfunction

## Nested region (list item / table cell): first paragraph renders inline,
## subsequent paragraphs are <p>-wrapped; returns a single HTML string.
function html = i_subregion (lines, pkgfcns)
  elems = i_scan (lines, pkgfcns);
  html = "";
  first = true;
  for i = 1:numel (elems)
    if (strcmp (elems(i).kind, "para"))
      if (first)
        html = [html, i_inline(elems(i).data, pkgfcns)];
      else
        html = [html, "\n<p>", i_inline(elems(i).data, pkgfcns), "\n</p>\n"];
      endif
    else
      html = [html, "\n", elems(i).data];
    endif
    first = false;
  endfor
endfunction

## --- @itemize / @enumerate (depth-aware, nestable) -----------------------
function [html, i] = i_parse_list (lines, i, pkgfcns, tag, endtok)
  i += 1;
  items = {};
  cur = {};
  have = false;
  depth = 0;
  N = numel (lines);
  while (i <= N)
    lead = i_lead (lines{i});
    if (isempty (lead) || lead != "@")
      if (have)
        cur{end+1} = lines{i};       # plain/blank content line
      endif
      i += 1;
      continue;
    endif
    lt = strtrim (lines{i});
    if (depth == 0 && i_iscmd (lt, endtok))
      i += 1;
      break;
    elseif (depth == 0 && i_iscmd (lt, "@item"))
      if (have)
        items{end+1} = cur;
      endif
      cur = {strtrim(lt(numel("@item")+1:end))};
      have = true;
    else
      if (i_isopener (lt))
        depth += 1;
      elseif (i_iscmd (lt, "@end"))
        depth -= 1;
      endif
      if (have)
        cur{end+1} = lines{i};
      endif
    endif
    i += 1;
  endwhile
  if (have)
    items{end+1} = cur;
  endif

  html = ["<", tag, ">\n"];
  for j = 1:numel (items)
    item = items{j};
    if (isempty (item{1}))
      ## bare "@item" with text on following lines
      html = [html, "<li>\n", i_subregion(item, pkgfcns), "\n</li>"];
    else
      html = [html, "<li> ", i_subregion(item, pkgfcns), "\n</li>"];
    endif
  endfor
  html = [html, "</", tag, ">\n\n"];
endfunction

## --- @table (depth-aware) ------------------------------------------------
function [html, i] = i_parse_table (lines, i, pkgfcns)
  fmt = strtrim (lines{i});
  fmt = strtrim (fmt(numel("@table")+1:end));
  i += 1;
  N = numel (lines);
  html = "<dl compact=\"compact\">\n";
  desc = {};
  open_desc = false;
  depth = 0;
  while (i <= N)
    lead = i_lead (lines{i});
    if (isempty (lead))
      if (open_desc)
        desc{end+1} = "";            # blank line within an open description
      endif
      i += 1;
      continue;
    elseif (lead != "@")
      desc{end+1} = lines{i};        # plain text: description content
      open_desc = true;
      i += 1;
      continue;
    endif
    lt = strtrim (lines{i});
    if (depth == 0 && i_iscmd (lt, "@end table"))
      i += 1;
      break;
    elseif (depth == 0 && i_iscmd (lt, "@itemx"))
      term = strtrim (lt(numel("@itemx")+1:end));
      html = [html, "<dt> ", i_table_term(fmt, term, pkgfcns), "</dt>\n"];
    elseif (depth == 0 && i_iscmd (lt, "@item"))
      if (open_desc)
        html = [html, "<dd>", i_subregion(desc, pkgfcns), "</dd>\n"];
        desc = {};
        open_desc = false;
      endif
      term = strtrim (lt(numel("@item")+1:end));
      html = [html, "<dt> ", i_table_term(fmt, term, pkgfcns), "</dt>\n"];
    elseif (isempty (lt))
      ## Blank line: part of a description only if one is already open;
      ## never start a description (avoids a stray empty <dd>).
      if (open_desc)
        desc{end+1} = "";
      endif
    else
      if (i_isopener (lt))
        depth += 1;
      elseif (i_iscmd (lt, "@end"))
        depth -= 1;
      endif
      desc{end+1} = lines{i};
      open_desc = true;
    endif
    i += 1;
  endwhile
  if (open_desc)
    html = [html, "<dd>", i_subregion(desc, pkgfcns), "</dd>\n"];
  endif
  html = [html, "</dl>\n\n"];
endfunction

function s = i_table_term (fmt, term, pkgfcns)
  switch (fmt)
    case "@code"
      s = ["<code>", i_inline(term,pkgfcns,true), "</code>"];
    case "@var"
      s = ["<var>", i_inline(term,pkgfcns), "</var>"];
    case "@samp"
      s = ["&lsquo;<samp>", i_inline(term,pkgfcns,true), "</samp>&rsquo;"];
    otherwise
      s = i_inline (term, pkgfcns);
  endswitch
endfunction

## --- @multitable (depth-aware rows; cells may nest blocks) ---------------
function [html, i] = i_parse_multitable (lines, i, pkgfcns)
  head = strtrim (lines{i});
  widths = {};
  ## Column widths come from @columnfractions, but only when the prototype
  ## (brace-template) form is not used -- "@multitable {c1} {c2} ..." takes
  ## precedence and yields no explicit widths.
  rest = strtrim (head(numel("@multitable")+1:end));
  cf = strfind (head, "@columnfractions");
  if (! isempty (rest) && rest(1) == "{")
    cf = [];
  endif
  if (! isempty (cf))
    nums = str2double (strsplit (strtrim (head(cf+16:end))));
    nums = nums(! isnan (nums));
    for c = 1:numel (nums)
      widths{c} = [num2str(floor(nums(c)*100 + 1e-9)), "%"];
    endfor
  endif
  i += 1;
  N = numel (lines);
  html = ["<div class=\"table-responsive\">\n", ...
          "<table class=\"table table-striped table-bordered table-sm\">\n"];
  rowlines = {};
  is_head = false;
  have_row = false;
  depth = 0;
  while (i <= N)
    lead = i_lead (lines{i});
    if (isempty (lead))
      if (have_row)
        if (depth == 0)
          rowlines{end+1} = "";
        else
          rowlines{end+1} = lines{i};
        endif
      endif
      i += 1;
      continue;
    elseif (lead != "@")
      if (have_row)
        rowlines{end+1} = lines{i};
      endif
      i += 1;
      continue;
    endif
    lt = strtrim (lines{i});
    if (depth == 0 && i_iscmd (lt, "@end multitable"))
      i += 1;
      break;
    elseif (depth == 0 && (i_iscmd (lt, "@headitem") || i_iscmd (lt, "@item")))
      if (have_row)
        html = [html, i_mt_row(rowlines, is_head, widths, pkgfcns)];
      endif
      is_head = i_iscmd (lt, "@headitem");
      if (is_head)
        rowlines = {strtrim(lt(numel("@headitem")+1:end))};
      else
        rowlines = {strtrim(lt(numel("@item")+1:end))};
      endif
      have_row = true;
    elseif (isempty (lt) && depth == 0)
      if (have_row)
        rowlines{end+1} = "";
      endif
    else
      if (i_isopener (lt))
        depth += 1;
      elseif (i_iscmd (lt, "@end"))
        depth -= 1;
      endif
      if (have_row)
        rowlines{end+1} = lines{i};
      endif
    endif
    i += 1;
  endwhile
  if (have_row)
    html = [html, i_mt_row(rowlines, is_head, widths, pkgfcns)];
  endif
  html = [html, "</table>\n</div>\n\n"];
endfunction

function h = i_mt_row (rowlines, is_head, widths, pkgfcns)
  ## First line holds the @tab-separated cells; extra lines belong to the
  ## last cell (possibly carrying nested block structure).
  first = rowlines{1};
  cells = strsplit (first, "@tab", "collapsedelimiters", false);
  ncell = numel (cells);
  celllines = cell (1, ncell);
  for c = 1:ncell
    celllines{c} = {strtrim(cells{c})};
  endfor
  for e = 2:numel (rowlines)
    celllines{ncell}{end+1} = rowlines{e};
  endfor

  if (is_head)
    tag = "th";
  else
    tag = "td";
  endif
  h = "";
  if (is_head)
    h = "<thead class=\"table-primary\">";
  endif
  h = [h, "<tr>"];
  for c = 1:ncell
    w = i_width_attr (widths, c);
    h = [h, "<", tag, w, ">", i_subregion(celllines{c}, pkgfcns), ...
         "</", tag, ">"];
  endfor
  h = [h, "</tr>"];
  if (is_head)
    h = [h, "</thead>"];
  endif
  h = [h, "\n"];
endfunction

function w = i_width_attr (widths, c)
  if (c <= numel (widths))
    w = [" width=\"", widths{c}, "\""];
  else
    w = "";
  endif
endfunction

## --- @example / @verbatim ------------------------------------------------
function [html, i] = i_parse_example (lines, i, pkgfcns)
  i += 1;
  N = numel (lines);
  code = {};
  while (i <= N)
    lt = strtrim (lines{i});
    if (i_iscmd (lt, "@end example"))
      i += 1;
      break;
    elseif (strcmp (lt, "@group") || strcmp (lt, "@end group"))
      ## drop grouping markers
    else
      code{end+1} = i_inline (lines{i}, pkgfcns, true);
    endif
    i += 1;
  endwhile
  body = strjoin (code, "\n");
  html = ["<table><tr><td>&nbsp;</td><td><pre class=\"example\">", ...
          body, "\n</pre></td></tr></table>\n\n"];
endfunction

function [html, i] = i_parse_verbatim (lines, i)
  i += 1;
  N = numel (lines);
  code = {};
  while (i <= N)
    lt = strtrim (lines{i});
    if (i_iscmd (lt, "@end verbatim"))
      i += 1;
      break;
    else
      code{end+1} = i_esc (lines{i});
    endif
    i += 1;
  endwhile
  html = ["<pre class=\"example\">", strjoin(code,"\n"), "\n</pre>\n\n"];
endfunction

## --- inline command processor --------------------------------------------
## CODE (optional, default false): when true, literal text is HTML-escaped
## only (no smart quotes) -- used inside @code, @example, etc.
function out = i_inline (s, pkgfcns, code)
  if (nargin < 3)
    code = false;
  endif
  n = numel (s);
  ## Fast path: no @-commands at all -> a single escaping pass.
  at = find (s == "@", 1);
  if (isempty (at))
    out = i_flushtext (s, code);
    return;
  endif
  ## Accumulate output pieces in a cell and concatenate once, and copy plain
  ## text between commands in bulk rather than character by character.
  parts = {};
  i = 1;
  while (i <= n)
    if (s(i) != "@")
      rel = find (s(i:n) == "@", 1);
      if (isempty (rel))
        parts{end+1} = i_flushtext (s(i:n), code);
        break;
      endif
      at = i + rel - 1;
      parts{end+1} = i_flushtext (s(i:at-1), code);
      i = at;
    endif
    ## s(i) is "@"
    if (i == n)
      parts{end+1} = "@";
      break;
    endif
    nc = s(i+1);
    if (nc == "@" || nc == "{" || nc == "}")
      parts{end+1} = nc;
      i += 2;
      continue;
    endif
    if (! (isalpha (nc)))
      ## non-alphabetic single-char command
      if (nc == "*")
        parts{end+1} = "<br>";               # forced line break
      elseif (nc == " " || nc == "\t")
        parts{end+1} = " ";                  # explicit space
      elseif (nc == "/" || nc == "-" || nc == ":")
        ## @/ line break, @- discretionary hyphen, @: no extra space: no output
      else
        parts{end+1} = nc;                   # @. @! @? -> the punctuation
      endif
      i += 2;
      continue;
    endif
    j = i + 1;
    while (j <= n && isalpha (s(j)))
      j += 1;
    endwhile
    cmd = s(i+1:j-1);
    if (j <= n && s(j) == "{")
      [content, kk] = i_grab (s, j);
      parts{end+1} = i_render (cmd, content, pkgfcns);
      i = kk;
    else
      parts{end+1} = i_render_bare (cmd);
      i = j;
    endif
  endwhile
  out = [parts{:}];
endfunction

function t = i_flushtext (s, code)
  if (isempty (s))
    t = "";
  elseif (code)
    t = i_esc (s);
  else
    t = i_text (s);
  endif
endfunction

function [content, nexti] = i_grab (s, i)
  depth = 0;
  n = numel (s);
  j = i;
  while (j <= n)
    c = s(j);
    if (c == "@" && j < n)
      j += 2;
      continue;
    elseif (c == "{")
      depth += 1;
    elseif (c == "}")
      depth -= 1;
      if (depth == 0)
        content = s(i+1:j-1);
        nexti = j + 1;
        return;
      endif
    endif
    j += 1;
  endwhile
  content = s(i+1:end);
  nexti = n + 1;
endfunction

function out = i_render (cmd, content, pkgfcns)
  switch (cmd)
    case {"dots", "result", "minus", "times", "bullet", "TeX", "LaTeX"}
      out = i_render_bare (cmd);
    case "var"
      out = ["<var>", i_inline(content,pkgfcns), "</var>"];
    case {"code", "qcode", "command", "option", "env", "file", "kbd"}
      out = ["<code>", i_inline(content,pkgfcns,true), "</code>"];
    case "math"
      ## Inside @math{...}, multiplication is written with an asterisk and is
      ## rendered as the times sign; the letter "x" is left untouched so it can
      ## be used as a variable name (e.g. @math{exp (-2 * x)}).  Authors must use
      ## "*" for multiplication -- a bare "x" is NOT treated as a times sign.
      inner = i_inline (content, pkgfcns, true);
      inner = strrep (inner, "*", "&times;");
      out = ["<math>", inner, "</math>"];
    case "strong"
      out = ["<strong>", i_inline(content,pkgfcns), "</strong>"];
    case "emph"
      out = ["<em>", i_inline(content,pkgfcns), "</em>"];
    case "cite"
      out = ["<cite>", i_inline(content,pkgfcns), "</cite>"];
    case "samp"
      out = ["&lsquo;<samp>", i_inline(content,pkgfcns,true), "</samp>&rsquo;"];
    case "sc"
      out = ["<small>", toupper(i_inline(content,pkgfcns)), "</small>"];
    case {"asis", "abbr", "w", "t", "dfn"}
      out = i_inline (content, pkgfcns);
    case "url"
      parts = strsplit (content, ",");
      u = strtrim (parts{1});
      if (numel (parts) > 1)
        disp_txt = i_inline (strtrim (parts{2}), pkgfcns);
      else
        disp_txt = i_esc (u);
      endif
      out = ["<a href=\"", u, "\">", disp_txt, "</a>"];
    case {"ref", "xref", "pxref"}
      out = i_render_ref (cmd, content, pkgfcns);
    otherwise
      out = i_inline (content, pkgfcns);
  endswitch
endfunction

function out = i_render_bare (cmd)
  switch (cmd)
    case "dots"
      out = "&hellip;";
    case "result"
      out = "&rArr;";
    case "minus"
      out = "-";
    case "times"
      out = "&times;";
    case "bullet"
      out = "";
    case "TeX"
      out = "TeX";
    case "LaTeX"
      out = "LaTeX";
    otherwise
      out = "";
  endswitch
endfunction

function out = i_render_ref (cmd, content, pkgfcns)
  switch (cmd)
    case "xref"
      prefix = "See ";
    case "pxref"
      prefix = "see ";
    otherwise
      prefix = "";
  endswitch
  names = strtrim (strsplit (content, ","));
  out = prefix;
  for i = 1:numel (names)
    s = strrep (names{i}, "@@", "@");
    if (any (strcmp (pkgfcns(:,1), s)))
      f = strrep (s, filesep, "_");
      link = ["<a href=\"", f, ".html\">", s, "</a>"];
    else
      link = s;
    endif
    if (i < numel (names))
      out = [out, link, ", \n"];
    else
      out = [out, link];
    endif
  endfor
endfunction
