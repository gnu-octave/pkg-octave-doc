## Copyright (C) 2023-2026 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefn  {pkg-octave-doc} {@var{html} =} build_DEMOS (@var{fcnname})
## @deftypefnx {pkg-octave-doc} {@var{html} =} build_DEMOS (@var{fcnname}, @var{collapsed})
## @deftypefnx {pkg-octave-doc} {@var{html} =} build_DEMOS (@dots{}, @var{Name}, @var{Value})
##
## Build notebook-style HTML for the DEMO blocks of a function or class member.
##
## @code{build_DEMOS} collects every @code{%!demo} block of @var{fcnname} and
## returns @var{html}, a char string with the generated HTML for all of them.
## @var{fcnname} is a char string with the name of a function or, for a class
## member, a @qcode{"class/method"} path.  Each demo is wrapped in the
## @qcode{demos_template.html} card, titled @qcode{Example: N} and given the HTML
## anchor @qcode{@var{fcnname}-exampleN} (with every non-alphanumeric character of
## @var{fcnname}, such as the @qcode{.} of a @qcode{"Class.method"} name, mapped
## to @qcode{_} so the id is safe in a CSS selector).  A docstring can therefore
## link to one of its own demos with the
## short form @code{@@url@{#exampleN@}}: the HTML converter expands the bare
## @qcode{#exampleN} fragment to this fully-qualified anchor, which keeps the
## reference readable in the command-line @code{help} while staying unique on a
## page that carries several members' demos.
##
## The optional @var{collapsed} is a logical scalar.  When @qcode{true}, each
## example card renders collapsed by default (used for lumped classdef members to
## keep the page short); a viewer expands it with the card header, and a
## @qcode{#exampleN} link opens it automatically.  When omitted or @qcode{false},
## the card renders expanded.  When @var{fcnname} has no demos, @var{html} is
## returned empty.
##
## @subsubheading Optional Name/Value pairs
##
## @multitable @columnfractions 0.2 0.8
## @headitem @var{Name} @tab @var{Value}
##
## @item @qcode{'figformat'} @tab The file format the demo figures are printed
## in, either @qcode{'png'} (default) or @qcode{'svg'}.  @qcode{'png'} is
## printed at twice the nominal size so it stays sharp on a high-density
## display.  @qcode{'svg'} keeps the figures resolution independent, at the cost
## of very large files for figures rich in filled areas.
## @end multitable
##
## @subsubheading Notebook layout
##
## Each demo is rendered as an interleaved @emph{notebook} instead of a single
## code block trailed by its aggregated output.  The demo is split into cells
## and laid out as a vertical stack of boxes:
##
## @itemize
## @item @strong{Comment} lines become prose (see the Markdown subset below).
##
## @item @strong{Code} statements become input boxes.  Consecutive statements
## that print nothing are merged into a single box, so muted setup code reads as
## one block.
##
## @item @strong{Output} produced by a statement is shown in an output box
## directly beneath it, rather than at the end of the demo.  A statement prints
## when it is left unterminated by a semicolon or when it calls @code{disp},
## @code{printf}, and the like.
##
## @item @strong{Figures} are saved under the @qcode{assets/} folder of the
## working directory, shown right after the code that drew them.  They are named
## after their owner as its HTML page is, so the figures of
## @qcode{prob.NormalDistribution.pdf} are @qcode{prob.NormalDistribution.pdf-N}
## beside @qcode{prob.NormalDistribution.pdf.html}.  The figure number is
## separated with a @qcode{-}, since @qcode{_} already stands for the file
## separator of an old-style @qcode{"@@class/method"} name and a function name
## may itself contain one.
## @end itemize
##
## @subsubheading Markdown in comments
##
## Comment text uses a small subset of @strong{Markdown}, @emph{not} texinfo, so
## that the same demo stays readable in the terminal when it is run with the
## @code{demo} command.  The supported constructs are:
##
## @itemize
## @item inline code @qcode{`code`} rendered as @code{<code>};
##
## @item bold @qcode{**text**} and italic @qcode{*text*} emphasis;
##
## @item links @qcode{[text](url)};
##
## @item paragraphs, separated by a blank comment line;
##
## @item unordered lists, whose items start with a @qcode{- } or @qcode{* }
## marker, and ordered lists, whose items start with a @qcode{1. } marker.
## @end itemize
##
## All comment text is HTML-escaped before the markup is applied.  The following
## are deliberately @emph{not} supported: any texinfo markup; underscore
## emphasis @qcode{_text_}, which would mangle identifier names such as
## @code{a_b_c}; and @qcode{#} headings, which would clash with the Octave
## comment marker.
##
## @seealso{find_DEMOS, function_texi2html, classdef_texi2html}
## @end deftypefn

function html = build_DEMOS (fcnname, varargin)

  if (nargin < 1)
    print_usage ();
  endif

  if (! ischar (fcnname))
    print_usage ();
  endif

  ## Parse optional Name/Value paired arguments
  [opts, args] = parse_pairs ({'figformat'}, {'png'}, varargin);
  figformat = opts.figformat;
  if (! (ischar (figformat) && any (strcmpi (figformat, {'png', 'svg'}))))
    error ("build_DEMOS: FIGFORMAT must be 'png' or 'svg'.");
  endif
  figformat = lower (figformat);

  ## Whatever the pairs left behind is the optional COLLAPSED argument
  if (numel (args) > 1)
    print_usage ();
  elseif (numel (args) == 1)
    collapsed = args{1};
    if (! (islogical (collapsed) && isscalar (collapsed)))
      print_usage ();
    endif
  else
    collapsed = false;
  endif

  ## The work itself is done by __build_demos__, which the other doc-generating
  ## functions call directly: they have validated FIGFORMAT at their own entry
  ## point, so nothing is gained by parsing it again for every member of every
  ## class of a package build.
  html = __build_demos__ (fcnname, collapsed, figformat);

endfunction

%!error build_DEMOS ()
%!error build_DEMOS (1)
%!error build_DEMOS ("function_texi2html", 1)
%!error build_DEMOS ("function_texi2html", true, 1)
%!error <build_DEMOS: FIGFORMAT must be 'png' or 'svg'.>
%! build_DEMOS ("function_texi2html", 'figformat', 'gif');
%!error <build_DEMOS: FIGFORMAT must be 'png' or 'svg'.>
%! build_DEMOS ("function_texi2html", 'figformat', 5);
%!error <Invalid call> build_DEMOS ("function_texi2html", 'nosuch', 1)

%!test
%! assert (build_DEMOS ("function_texi2html", 'figformat', 'svg'), "");
%!test
%! assert (build_DEMOS ("function_texi2html", true, 'figformat', 'png'), "");
