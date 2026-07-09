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
## @deftypefn  {pkg-octave-doc} {@var{html} =} __demo_html__ (@var{cells})
##
## Assemble the notebook-style HTML of a DEMO from its evaluated cells.
##
## @var{cells} is the struct array produced by @code{__eval_demo__}, with fields
## @qcode{type}, @qcode{text}, @qcode{output}, and @qcode{images}.  The cells are
## laid out as a vertical stack of boxes:
##
## @itemize
## @item comment cells become prose, rendered by @code{__demo_markdown__};
##
## @item consecutive code cells that print nothing are merged into a single
## input box, so muted setup code reads as one block;
##
## @item as soon as a code cell prints, the pending input box is flushed and an
## output box is emitted directly beneath it, followed by any figures captured
## at that cell.
## @end itemize
##
## This places each statement's console output right after the statement that
## produced it, rather than aggregating all output at the end.
##
## @seealso{__eval_demo__, __demo_markdown__, build_DEMOS}
## @end deftypefn

function html = __demo_html__ (cells)

  if (nargin != 1 || ! isstruct (cells))
    print_usage ();
  endif

  code_style = ["overflow-x: auto; white-space: pre; padding: 0.6rem 0.8rem;", ...
                " margin: 0.3rem 0; border: 1px solid #cfe0e6;", ...
                " border-left: 4px solid #4a90a4; border-radius: 4px;", ...
                " background-color: #eef5f8;"];
  out_style = ["overflow-x: auto; white-space: pre; padding: 0.6rem 0.8rem;", ...
               " margin: 0.3rem 0 0.8rem 0; border: 1px solid #e2e2e2;", ...
               " border-left: 4px solid #b7b7b7; border-radius: 4px;", ...
               " background-color: #fafafa;"];

  html = "";
  codebuf = {};

  for i = 1:numel (cells)
    c = cells(i);

    if (strcmp (c.type, "comment"))
      [html, codebuf] = i_flush_code (html, codebuf, code_style);
      html = [html, __demo_markdown__(c.text)];
      continue;
    endif

    ## Code cell: accumulate, and flush when it produced output or a figure
    codebuf{end+1} = c.text;
    out = deblank (c.output);
    if (! isempty (out) || ! isempty (c.images))
      [html, codebuf] = i_flush_code (html, codebuf, code_style);
      if (! isempty (out))
        html = [html, "                <pre style=\"", out_style, "\">", ...
                i_escape(out), "</pre>\n"];
      endif
      for k = 1:numel (c.images)
        html = [html, i_image(c.images{k})];
      endfor
    endif
  endfor

  [html, codebuf] = i_flush_code (html, codebuf, code_style);

endfunction

## Emit the pending input box (if any) and clear the buffer.
function [html, codebuf] = i_flush_code (html, codebuf, code_style)
  if (! isempty (codebuf))
    code = strjoin (codebuf, "\n");
    html = [html, "                <pre style=\"", code_style, "\">", ...
            i_escape(code), "</pre>\n"];
    codebuf = {};
  endif
endfunction

## HTML-escape a block of code or output text.
function s = i_escape (s)
  s = strrep (s, "&", "&amp;");
  s = strrep (s, "<", "&lt;");
  s = strrep (s, ">", "&gt;");
endfunction

## Emit a centered figure thumbnail.
function h = i_image (path)
  h = ["                <div class=\"text-center\">\n", ...
       "                  <img src=\"", path, "\"", ...
       " class=\"rounded img-thumbnail\" alt=\"plotted figure\">\n", ...
       "                </div><p></p>\n"];
endfunction

%!shared cc
%! cc = struct ("type", {}, "text", {}, "output", {}, "images", {});

%!test
%! ## A comment cell becomes prose
%! c = struct ("type", "comment", "text", "## hi there", ...
%!             "output", "", "images", {{}});
%! h = __demo_html__ (c);
%! assert (! isempty (strfind (h, "<p>hi there</p>")));

%!test
%! ## Muted code merges into one input box; nothing after it
%! c(1) = struct ("type", "code", "text", "x = 1;", "output", "", "images", {{}});
%! c(2) = struct ("type", "code", "text", "y = 2;", "output", "", "images", {{}});
%! h = __demo_html__ (c);
%! assert (numel (strfind (h, "<pre")), 1);
%! assert (! isempty (strfind (h, "x = 1;\ny = 2;")));

%!test
%! ## A printing statement flushes the input box and adds an output box
%! c(1) = struct ("type", "code", "text", "x = 1;", "output", "", "images", {{}});
%! c(2) = struct ("type", "code", "text", "y = 2", "output", "y = 2\n", ...
%!               "images", {{}});
%! h = __demo_html__ (c);
%! assert (numel (strfind (h, "<pre")), 2);
%! ## Both statements share the input box, output box holds only the printout
%! ip = strfind (h, "x = 1;\ny = 2");
%! assert (! isempty (ip));

%!test
%! ## Interleaving: output appears between two code blocks
%! c(1) = struct ("type", "code", "text", "a = 1", "output", "a = 1\n", ...
%!               "images", {{}});
%! c(2) = struct ("type", "code", "text", "b = 2;", "output", "", "images", {{}});
%! h = __demo_html__ (c);
%! i_out = strfind (h, "a = 1</pre>");
%! i_b = strfind (h, "b = 2;");
%! assert (i_out(end) < i_b(1));

%!test
%! ## HTML metacharacters in output are escaped
%! c = struct ("type", "code", "text", "disp (1)", "output", "1 < 2 & 3 > 0", ...
%!             "images", {{}});
%! h = __demo_html__ (c);
%! assert (! isempty (strfind (h, "1 &lt; 2 &amp; 3 &gt; 0")));

%!test
%! ## An image is emitted after its code cell
%! c = struct ("type", "code", "text", "plot (1)", "output", "", ...
%!             "images", {{"assets/foo_101.png"}});
%! h = __demo_html__ (c);
%! assert (! isempty (strfind (h, "assets/foo_101.png")));
%! assert (! isempty (strfind (h, "img-thumbnail")));

%!error <Invalid call> __demo_html__ ()
%!error <Invalid call> __demo_html__ (1)
