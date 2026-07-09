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
## @deftypefn  {pkg-octave-doc} {@var{html} =} __demo_markdown__ (@var{text})
##
## Render the plain-text comment of a DEMO cell as HTML using a markdown subset.
##
## DEMO comments are dual-surface: they are shown verbatim in the console by the
## @code{demo} command and rendered online.  They therefore use a small subset
## of markdown (which stays legible as plain text) rather than texinfo.
##
## @var{text} is the raw comment-cell source, i.e. one or more lines each
## starting with a @qcode{#} or @qcode{%} comment marker.  The markers (and one
## following space) are stripped and the remaining lines are rendered as:
##
## @itemize
## @item paragraphs (consecutive non-empty lines flow together; an empty
## comment line separates paragraphs),
##
## @item unordered lists (lines beginning with @qcode{- } or @qcode{* }) and
## ordered lists (lines beginning with @qcode{1. }),
##
## @item inline @qcode{`code`}, @qcode{**bold**}, @qcode{*italic*}, and
## @qcode{[text](url)} links.
## @end itemize
##
## All text is HTML-escaped before markup is applied.
##
## @seealso{__demo_html__, __eval_demo__}
## @end deftypefn

function html = __demo_markdown__ (text)

  if (nargin != 1 || ! ischar (text))
    print_usage ();
  endif

  ## Split into lines and strip the leading comment marker plus one space
  lines = strsplit (text, "\n", "collapsedelimiters", false);
  for k = 1:numel (lines)
    lines{k} = regexprep (lines{k}, "^\\s*[#%]+ ?", "");
  endfor

  html = "";
  para = {};        # pending paragraph lines
  items = {};       # pending list items
  ltype = "";       # "ul" or "ol" while inside a list

  for k = 1:numel (lines)
    t = strtrim (lines{k});
    um = regexp (t, "^[-*] +(.*)$", "tokens");
    om = regexp (t, "^[0-9]+\\. +(.*)$", "tokens");

    if (! isempty (um))
      [html, para] = i_flush_para (html, para);
      if (! strcmp (ltype, "ul"))
        [html, items] = i_flush_list (html, items, ltype);
        ltype = "ul";
      endif
      items{end+1} = um{1}{1};
    elseif (! isempty (om))
      [html, para] = i_flush_para (html, para);
      if (! strcmp (ltype, "ol"))
        [html, items] = i_flush_list (html, items, ltype);
        ltype = "ol";
      endif
      items{end+1} = om{1}{1};
    elseif (isempty (t))
      [html, para] = i_flush_para (html, para);
      [html, items] = i_flush_list (html, items, ltype);
      ltype = "";
    else
      [html, items] = i_flush_list (html, items, ltype);
      ltype = "";
      para{end+1} = t;
    endif
  endfor

  [html, para] = i_flush_para (html, para);
  [html, items] = i_flush_list (html, items, ltype);

endfunction

## Emit a <p> for any pending paragraph lines and clear the buffer.
function [html, para] = i_flush_para (html, para)
  if (! isempty (para))
    txt = strjoin (para, " ");
    html = [html, "                <p>", i_inline(txt), "</p>\n"];
    para = {};
  endif
endfunction

## Emit a <ul>/<ol> for any pending list items and clear the buffer.
function [html, items] = i_flush_list (html, items, ltype)
  if (! isempty (items))
    html = [html, "                <", ltype, ">\n"];
    for k = 1:numel (items)
      html = [html, "                  <li>", i_inline(items{k}), "</li>\n"];
    endfor
    html = [html, "                </", ltype, ">\n"];
    items = {};
  endif
endfunction

## Render inline markdown (code, bold, italic, links) with HTML escaping.
function s = i_inline (s)

  ## Escape HTML metacharacters first
  s = strrep (s, "&", "&amp;");
  s = strrep (s, "<", "&lt;");
  s = strrep (s, ">", "&gt;");

  ## Extract inline code spans so their contents are left untouched
  codes = {};
  tok = regexp (s, "`([^`]+)`", "tokens");
  for k = 1:numel (tok)
    codes{k} = tok{k}{1};
    s = regexprep (s, "`([^`]+)`", sprintf ("\x00%d\x00", k), "once");
  endfor

  ## Bold before italic (so ** is not eaten by the single-* rule)
  s = regexprep (s, "\\*\\*([^*]+)\\*\\*", "<strong>$1</strong>");
  s = regexprep (s, "\\*([^*]+)\\*", "<em>$1</em>");

  ## Links: [text](url)
  s = regexprep (s, "\\[([^]]+)\\]\\(([^)]+)\\)", "<a href=\"$2\">$1</a>");

  ## Restore code spans as <code> elements
  for k = 1:numel (codes)
    s = strrep (s, sprintf ("\x00%d\x00", k), ...
                ["<code>", codes{k}, "</code>"]);
  endfor

endfunction

%!test
%! h = __demo_markdown__ ("## Hello world");
%! assert (h, "                <p>Hello world</p>\n");

%!test
%! ## Consecutive comment lines flow into one paragraph
%! h = __demo_markdown__ ("## first line\n## second line");
%! assert (h, "                <p>first line second line</p>\n");

%!test
%! ## An empty comment line separates paragraphs
%! h = __demo_markdown__ ("## para one\n##\n## para two");
%! assert (h, ["                <p>para one</p>\n", ...
%!             "                <p>para two</p>\n"]);

%!test
%! ## Inline code
%! h = __demo_markdown__ ("## call `fitcknn` first");
%! assert (h, "                <p>call <code>fitcknn</code> first</p>\n");

%!test
%! ## Bold and italic
%! h = __demo_markdown__ ("## this is **very** and *quite* good");
%! assert (h, ["                <p>this is <strong>very</strong> ", ...
%!             "and <em>quite</em> good</p>\n"]);

%!test
%! ## Link
%! h = __demo_markdown__ ("## see [docs](https://octave.org)");
%! assert (h, ["                <p>see ", ...
%!             "<a href=\"https://octave.org\">docs</a></p>\n"]);

%!test
%! ## HTML metacharacters are escaped
%! h = __demo_markdown__ ("## compare a < b & c > d");
%! assert (h, "                <p>compare a &lt; b &amp; c &gt; d</p>\n");

%!test
%! ## Markup inside a code span is not interpreted
%! h = __demo_markdown__ ("## use `a*b*c` here");
%! assert (h, "                <p>use <code>a*b*c</code> here</p>\n");

%!test
%! ## Unordered list
%! h = __demo_markdown__ ("## Steps:\n## - load\n## - fit");
%! assert (h, ["                <p>Steps:</p>\n", ...
%!             "                <ul>\n", ...
%!             "                  <li>load</li>\n", ...
%!             "                  <li>fit</li>\n", ...
%!             "                </ul>\n"]);

%!test
%! ## Ordered list
%! h = __demo_markdown__ ("## 1. one\n## 2. two");
%! assert (h, ["                <ol>\n", ...
%!             "                  <li>one</li>\n", ...
%!             "                  <li>two</li>\n", ...
%!             "                </ol>\n"]);

%!test
%! ## Percent-style comment markers are stripped too
%! h = __demo_markdown__ ("% a note");
%! assert (h, "                <p>a note</p>\n");

%!error <Invalid call> __demo_markdown__ ()
%!error <Invalid call> __demo_markdown__ (1)
