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
## @deftypefn {pkg-octave-doc} {[@var{rows}, @var{findings}] =} __cache_rows__ (@var{name}, @var{text}, @var{opts})
##
## Private function building one doc-cache entry from a help text.
##
## @var{rows} is a @math{3x1} cell array holding @var{name}, the help text as
## plain text, and its first sentence, which are the three rows a
## @file{doc-cache} keeps for an entry.  @var{findings} are the structural
## defects of @var{text}, which the renderer reports while it is converting.
##
## Both rows come from a single render, which is what makes this cheaper than
## the route @code{doc_cache_create} takes: it calls @code{makeinfo} for the
## text and again, through @code{get_first_help_sentence}, for the sentence.
## Byte compatibility with a cache Octave built is not a goal, since Octave
## will never write one holding class members, and the second row is only ever
## searched with @code{strfind} rather than displayed.  The sentence is kept
## whole, uncapped, costing a fraction of a percent of a cache's size.
##
## @end deftypefn

function [rows, findings] = __cache_rows__ (name, text, opts)

  ## Input validation
  if (nargin != 3)
    error ("__cache_rows__: invalid number of input arguments.");
  endif
  if (! (ischar (name) && isrow (name)))
    error ("__cache_rows__: NAME must be a character vector.");
  endif
  if (! (ischar (text) && (isrow (text) || isempty (text))))
    error ("__cache_rows__: TEXT must be a character vector.");
  endif
  if (! isa (opts, 'pkg_doc_options'))
    error ("__cache_rows__: OPTS must be a pkg_doc_options object.");
  endif

  ## A cache entry links to nothing, so the cross-reference list is empty, but
  ## it must carry its two columns: the renderer indexes the first of them
  [html, findings] = __texi2html__ (text, name, cell (0, 2), opts);
  plain = htmlToText (html);
  summary = firstSentence (text);
  rows = {name; plain; summary};

endfunction

## Reduce a rendered fragment to the words it carries, which is all the second
## row is ever searched for
function out = htmlToText (html)
  out = regexprep (html, '<(script|style)[^>]*>.*?</\1>', ' ');
  out = regexprep (out, '<[^>]*>', ' ');
  out = strrep (out, '&lt;', '<');
  out = strrep (out, '&gt;', '>');
  out = strrep (out, '&quot;', '"');
  out = strrep (out, '&#39;', "'");
  out = strrep (out, '&nbsp;', ' ');
  out = strrep (out, '&amp;', '&');
  out = regexprep (out, '[ \t]+', ' ');
  out = regexprep (out, ' ?\n ?', "\n");
  out = regexprep (out, "\n{3,}", "\n\n");
  out = strtrim (out);
endfunction

## The first sentence of the summary, taken from the texinfo rather than from
## the rendered fragment, the summary being the first paragraph after the
## signature
function out = firstSentence (text)
  out = '';
  lines = strsplit (strrep (text, "\r\n", "\n"), "\n", ...
                    'CollapseDelimiters', false);
  ## Walk past the signature, which is one or more @deftypefn/@deftp lines
  ii = 1;
  while (ii <= numel (lines))
    ln = strtrim (lines{ii});
    if (isempty (ln) || ! isempty (regexp (ln, '^@def', 'once')))
      ii += 1;
    else
      break;
    endif
  endwhile
  ## Collect the paragraph that follows
  para = {};
  while (ii <= numel (lines) && ! isempty (strtrim (lines{ii})))
    para{end+1} = strtrim (lines{ii});
    ii += 1;
  endwhile
  if (isempty (para))
    return;
  endif
  out = stripTexinfo (strjoin (para, ' '));
  ## Cut at the first sentence end, a period followed by a space or the end
  pos = regexp (out, '\.(\s|$)', 'once');
  if (! isempty (pos))
    out = out(1:pos);
  endif
  out = strtrim (out);
endfunction

## Remove the texinfo markup from a short span, keeping what it wrapped
function out = stripTexinfo (str)
  out = str;
  for ii = 1:8
    prev = out;
    out = regexprep (out, '@(?:[a-zA-Z]+)\{([^{}]*)\}', '$1');
    if (strcmp (out, prev))
      break;
    endif
  endfor
  out = regexprep (out, '@[a-zA-Z]+\{\}', '');
  out = strrep (out, '@@', '@');
  out = strrep (out, '@{', '{');
  out = strrep (out, '@}', '}');
  out = regexprep (out, '[ \t]+', ' ');
endfunction
