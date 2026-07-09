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
## @deftypefn  {pkg-octave-doc} {@var{seg} =} __demo_segments__ (@var{code})
##
## Split a DEMO code block into an ordered sequence of comment and code cells.
##
## @var{code} is a char string holding the source of a single DEMO block, as
## returned by @code{find_DEMOS}.  @__demo_segments__ returns @var{seg}, a struct
## array with two fields:
##
## @itemize
## @item @qcode{type} is either @qcode{"comment"} for a run of consecutive
## full-line comments or @qcode{"code"} for a single complete statement.
##
## @item @qcode{text} is the exact source substring of the cell, with its
## original line breaks preserved and no trailing newline.
## @end itemize
##
## A @qcode{"code"} cell is a @emph{complete} unit: it never splits a multi-line
## bracketed literal, a line continued with @qcode{...}, or a block construct
## (@code{if}/@code{for}/@code{while}/@code{switch}/@code{do}/@code{try}/
## @code{unwind_protect} @dots{} @code{end}).  This lets a caller evaluate the
## cells one by one in a persistent workspace and interleave each cell's console
## output right after the statement that produced it.  Full-line comments become
## their own cells (prose); trailing inline comments stay with their code.
##
## Blank lines are dropped.  Block comments (@qcode{%@{} @dots{} @qcode{%@}} or
## the @qcode{#} variant) are emitted as a single comment cell.
##
## @end deftypefn

function seg = __demo_segments__ (code)

  if (nargin != 1 || ! ischar (code))
    print_usage ();
  endif

  ## Normalize line endings and split into physical lines, keeping blank lines
  code = strrep (code, "\r\n", "\n");
  code = strrep (code, "\r", "\n");
  lines = strsplit (code, "\n", "collapsedelimiters", false);

  seg = struct ("type", {}, "text", {});

  ## Cross-line lexer state
  bd = 0;              # bracket depth: () [] {}
  kd = 0;              # block-keyword depth: if/for/... end
  cont = false;        # previous line ended with a '...' continuation
  bcomment = false;    # inside a %{ ... %} block comment

  mode = "";           # "", "code", or "comment" for the pending cell
  buf = {};            # accumulated lines of the pending cell

  for k = 1:numel (lines)
    line = lines{k};
    trimmed = strtrim (line);

    ## Inside a block comment: swallow lines until the closing %} or #}
    if (bcomment)
      buf{end+1} = line;
      if (strcmp (trimmed, "%}") || strcmp (trimmed, "#}"))
        seg(end+1) = struct ("type", "comment", "text", strjoin (buf, "\n"));
        buf = {};
        mode = "";
        bcomment = false;
      endif
      continue;
    endif

    ## Inside an open code statement: append the line and keep lexing
    if (bd > 0 || kd > 0 || cont)
      buf{end+1} = line;
      [bd, kd, cont, complete] = lex_line (line, bd, kd);
      if (complete)
        seg(end+1) = struct ("type", "code", "text", strjoin (buf, "\n"));
        buf = {};
        mode = "";
      endif
      continue;
    endif

    ## At a statement boundary: classify the line
    if (isempty (trimmed))
      ## Blank line: end any pending comment run, then drop the line
      if (strcmp (mode, "comment"))
        seg(end+1) = struct ("type", "comment", "text", strjoin (buf, "\n"));
        buf = {};
        mode = "";
      endif
      continue;
    endif

    ## Block-comment opener on its own line
    if (strcmp (trimmed, "%{") || strcmp (trimmed, "#{"))
      if (strcmp (mode, "comment"))
        seg(end+1) = struct ("type", "comment", "text", strjoin (buf, "\n"));
        buf = {};
        mode = "";
      endif
      bcomment = true;
      mode = "comment";
      buf = {line};
      continue;
    endif

    if (trimmed(1) == "#" || trimmed(1) == "%")
      ## Full-line comment: accumulate into the current comment run
      if (! strcmp (mode, "comment"))
        mode = "comment";
        buf = {};
      endif
      buf{end+1} = line;
      continue;
    endif

    ## Start of a code statement: flush any pending comment run first
    if (strcmp (mode, "comment"))
      seg(end+1) = struct ("type", "comment", "text", strjoin (buf, "\n"));
      buf = {};
    endif
    mode = "code";
    buf = {line};
    [bd, kd, cont, complete] = lex_line (line, bd, kd);
    if (complete)
      seg(end+1) = struct ("type", "code", "text", strjoin (buf, "\n"));
      buf = {};
      mode = "";
    endif
  endfor

  ## Flush any trailing cell (e.g. a block left unterminated by malformed source)
  if (! isempty (buf))
    if (strcmp (mode, "comment"))
      seg(end+1) = struct ("type", "comment", "text", strjoin (buf, "\n"));
    else
      seg(end+1) = struct ("type", "code", "text", strjoin (buf, "\n"));
    endif
  endif

endfunction

## Lex a single physical line, updating the bracket depth @var{bd} and the
## block-keyword depth @var{kd} carried across lines.  Returns the updated
## depths, whether the line ends with a '...' continuation, and whether the
## statement is now @var{complete} (all depths closed and no continuation).
function [bd, kd, cont, complete] = lex_line (line, bd, kd)

  openers = {"if", "for", "parfor", "while", "switch", "do", "function", ...
             "try", "unwind_protect"};
  closers = {"end", "endif", "endfor", "endparfor", "endwhile", "endswitch", ...
             "endfunction", "end_try_catch", "end_unwind_protect", "until"};

  cont = false;
  n = numel (line);
  i = 1;
  prev_val = false;    # previous token can end a value (=> next ' is transpose)
  prev_dot = false;    # previous token was a lone '.' (field access)

  while (i <= n)
    c = line(i);

    if (c == "'" && ! prev_val)
      ## Single-quoted char string (with '' escape)
      i++;
      while (i <= n)
        if (line(i) == "'")
          if (i < n && line(i+1) == "'")
            i += 2;
            continue;
          else
            i++;
            break;
          endif
        endif
        i++;
      endwhile
      prev_val = true;
      prev_dot = false;

    elseif (c == "'")
      ## Transpose operator
      i++;
      prev_val = true;
      prev_dot = false;

    elseif (c == "\"")
      ## Double-quoted string (with backslash escapes)
      i++;
      while (i <= n)
        if (line(i) == "\\")
          i += 2;
          continue;
        elseif (line(i) == "\"")
          i++;
          break;
        endif
        i++;
      endwhile
      prev_val = true;
      prev_dot = false;

    elseif (c == "#" || c == "%")
      ## Trailing comment: nothing further on this line matters
      break;

    elseif (c == "." && i + 2 <= n && line(i+1) == "." && line(i+2) == ".")
      ## Line continuation: the rest of the line is ignored
      cont = true;
      break;

    elseif (c == "." && i < n && line(i+1) == "'")
      ## Non-conjugate transpose '.''
      i += 2;
      prev_val = true;
      prev_dot = false;

    elseif (c == "(" || c == "[" || c == "{")
      bd++;
      i++;
      prev_val = false;
      prev_dot = false;

    elseif (c == ")" || c == "]" || c == "}")
      bd = max (bd - 1, 0);
      i++;
      prev_val = true;
      prev_dot = false;

    elseif (isalnum (c) || c == "_")
      ## Read a full word (identifier, keyword, or number token)
      j = i;
      while (j <= n && (isalnum (line(j)) || line(j) == "_"))
        j++;
      endwhile
      word = line(i:j-1);
      ## Only bare, top-level keywords that are not field accesses affect depth
      if (bd == 0 && ! prev_dot && (isalpha (word(1)) || word(1) == "_"))
        if (any (strcmp (word, openers)))
          kd++;
        elseif (any (strcmp (word, closers)))
          kd = max (kd - 1, 0);
        endif
      endif
      i = j;
      prev_val = true;
      prev_dot = false;

    elseif (c == ".")
      ## Field-access dot (or decimal point)
      i++;
      prev_dot = true;
      prev_val = false;

    elseif (c == " " || c == "\t")
      ## Whitespace does not reset value context (keeps a' as transpose)
      i++;

    else
      ## Any other operator or punctuation
      i++;
      prev_val = false;
      prev_dot = false;
    endif
  endwhile

  complete = (bd == 0 && kd == 0 && ! cont);

endfunction

%!test
%! seg = __demo_segments__ ("x = 1;\ny = 2\n");
%! assert (numel (seg), 2);
%! assert ({seg.type}, {"code", "code"});
%! assert (seg(1).text, "x = 1;");
%! assert (seg(2).text, "y = 2");

%!test
%! seg = __demo_segments__ ("## hello\nx = 1\n");
%! assert ({seg.type}, {"comment", "code"});
%! assert (seg(1).text, "## hello");
%! assert (seg(2).text, "x = 1");

%!test
%! ## A run of comment lines collapses into one comment cell
%! seg = __demo_segments__ ("## line one\n## line two\nx = 1\n");
%! assert (numel (seg), 2);
%! assert (seg(1).type, "comment");
%! assert (seg(1).text, "## line one\n## line two");

%!test
%! ## A blank line splits two comment paragraphs and is dropped
%! seg = __demo_segments__ ("## a\n\n## b\nx = 1\n");
%! assert ({seg.type}, {"comment", "comment", "code"});
%! assert (seg(1).text, "## a");
%! assert (seg(2).text, "## b");

%!test
%! ## Line continuation keeps the statement whole
%! seg = __demo_segments__ ("y = 1 + ...\n    2\n");
%! assert (numel (seg), 1);
%! assert (seg(1).type, "code");
%! assert (seg(1).text, "y = 1 + ...\n    2");

%!test
%! ## Newline inside brackets does not terminate the statement
%! seg = __demo_segments__ ("A = [1, 2\n3, 4]\n");
%! assert (numel (seg), 1);
%! assert (seg(1).text, "A = [1, 2\n3, 4]");

%!test
%! ## A block construct is a single code cell
%! seg = __demo_segments__ ("for i = 1:3\n  disp (i)\nendfor\n");
%! assert (numel (seg), 1);
%! assert (seg(1).type, "code");

%!test
%! ## Bare 'end' terminates a block just like 'endfor'
%! seg = __demo_segments__ ("for i = 1:3\n  disp (i)\nend\nz = 9\n");
%! assert (numel (seg), 2);
%! assert ({seg.type}, {"code", "code"});

%!test
%! ## Nested blocks close correctly
%! code = "if (true)\n  for k = 1:2\n    disp (k)\n  endfor\nendif\n";
%! seg = __demo_segments__ (code);
%! assert (numel (seg), 1);

%!test
%! ## do-until block
%! seg = __demo_segments__ ("do\n  x = 1;\nuntil (true)\n");
%! assert (numel (seg), 1);

%!test
%! ## switch/case block
%! code = "switch (1)\n  case 1\n    disp (1)\n  otherwise\n    disp (2)\nendswitch\n";
%! seg = __demo_segments__ (code);
%! assert (numel (seg), 1);

%!test
%! ## Trailing inline comment stays with the code cell
%! seg = __demo_segments__ ("x = 1  ## set x\n");
%! assert (numel (seg), 1);
%! assert (seg(1).type, "code");
%! assert (seg(1).text, "x = 1  ## set x");

%!test
%! ## 'end' used as an index is not a block terminator (bracket depth > 0)
%! seg = __demo_segments__ ("v = x(end)\ny = 2\n");
%! assert (numel (seg), 2);
%! assert ({seg.type}, {"code", "code"});

%!test
%! ## A comment keyword inside a string is not a comment
%! seg = __demo_segments__ ("disp (\"50% done\")\n");
%! assert (numel (seg), 1);
%! assert (seg(1).type, "code");

%!test
%! ## A block keyword inside a string does not open a block
%! seg = __demo_segments__ ("s = \"for me\";\nx = 1\n");
%! assert (numel (seg), 2);
%! assert ({seg.type}, {"code", "code"});

%!test
%! ## Transpose is not mistaken for a string opener
%! seg = __demo_segments__ ("y = x'\nz = 2\n");
%! assert (numel (seg), 2);
%! assert ({seg.type}, {"code", "code"});

%!test
%! ## Full-line comment inside an open bracket stays part of the statement
%! seg = __demo_segments__ ("x = [1, ...\n## mid\n2]\n");
%! assert (numel (seg), 1);
%! assert (seg(1).type, "code");

%!test
%! ## A multi-line function call with continuations and nested braces
%! code = ["legend ({'A', 'B', ...\n", ...
%!         "        'C', 'D'}, ...\n", ...
%!         "        'location', 'north')\n"];
%! seg = __demo_segments__ (code);
%! assert (numel (seg), 1);
%! assert (seg(1).type, "code");

%!test
%! ## Field access does not trip keyword detection (s.for)
%! seg = __demo_segments__ ("s.for = 1;\nx = 2\n");
%! assert (numel (seg), 2);
%! assert ({seg.type}, {"code", "code"});

%!test
%! ## Block comment becomes a single comment cell
%! seg = __demo_segments__ ("%{\nnot code = here\n%}\nx = 1\n");
%! assert ({seg.type}, {"comment", "code"});
%! assert (seg(2).text, "x = 1");

%!test
%! ## Percent-style full-line comments are recognized too
%! seg = __demo_segments__ ("% a percent comment\nx = 1\n");
%! assert ({seg.type}, {"comment", "code"});

%!test
%! ## Empty input yields an empty struct array
%! seg = __demo_segments__ ("");
%! assert (isempty (seg));
%! assert (isstruct (seg));

%!error <Invalid call> __demo_segments__ ()
%!error <Invalid call> __demo_segments__ (1)
