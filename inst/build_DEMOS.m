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

## The tests below reach the private demo pipeline through this public entry
## point: __demo_segments__ splits a demo block into cells, __eval_demo__ runs
## them and __demo_html__ with __demo_markdown__ render what they produced.
## None of the four can be named in a test block, which is evaluated in the
## scope of test.m rather than in this file's, so each case is a temporary
## function carrying one demo, rendered by name.  The fixture directory and the
## writer that fills it live on disk and on the load path because
## __reset_classes__ clears classes after every demo, and that wipes shared
## variables and %!function helpers alike.
##
## A rendered input cell carries the #eef5f8 background of __demo_html__'s code
## style and an output cell the #fafafa of its output style, which is how the
## cells of a demo are counted below.  An unevaluable cell is rendered as the
## text "error:", so its absence is asserted wherever a case exists to prove
## that a statement was kept whole.

%!test  # the fixture directory and the writer every case below calls
%! d = fullfile (tempdir (), "pkg_octave_doc_bist");
%! if (! isfolder (d))
%!   mkdir (d);
%! endif
%! fid = fopen (fullfile (d, "bist_demo_fixture.m"), "w");
%! fputs (fid, "function name = bist_demo_fixture (name, src)\n");
%! fputs (fid, "  d = fullfile (tempdir (), \"pkg_octave_doc_bist\");\n");
%! fputs (fid, "  fid = fopen (fullfile (d, [name, \".m\"]), \"w\");\n");
%! fputs (fid, "  fprintf (fid, \"function %s ()\\nendfunction\\n\", name);\n");
%! fputs (fid, "  fprintf (fid, \"%%!demo\\n\");\n");
%! fputs (fid, "  lines = strsplit (src, \"\\n\");\n");
%! fputs (fid, "  for i = 1:numel (lines)\n");
%! fputs (fid, "    fprintf (fid, \"%%! %s\\n\", lines{i});\n");
%! fputs (fid, "  endfor\n");
%! fputs (fid, "  fclose (fid);\n");
%! fputs (fid, "endfunction\n");
%! fclose (fid);
%! addpath (d);
%! assert (isfolder (d));

%!test  # muted statements merge into one input cell and print nothing
%! h = build_DEMOS (bist_demo_fixture ("bist_muted", "x = 1;\ny = 2;"));
%! assert (numel (strfind (h, "#eef5f8")), 1);
%! assert (isempty (strfind (h, "#fafafa")));

%!test  # a printing statement flushes the input cell and adds an output cell
%! h = build_DEMOS (bist_demo_fixture ("bist_print", "x = 1;\ny = 2"));
%! assert (numel (strfind (h, "#eef5f8")), 1);
%! assert (numel (strfind (h, "#fafafa")), 1);
%! assert (! isempty (strfind (h, "y = 2")));

%!test  # a comment is prose, and it precedes the code it introduces
%! h = build_DEMOS (bist_demo_fixture ("bist_comment", "## hello\nx = 1;"));
%! i_p = strfind (h, "<p>hello</p>");
%! i_c = strfind (h, "#eef5f8");
%! assert (! isempty (i_p));
%! assert (i_p(1) < i_c(1));

%!test  # a run of comment lines collapses into one paragraph
%! src = "## line one\n## line two\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_comment_run", src));
%! assert (! isempty (strfind (h, "<p>line one line two</p>")));

%!test  # an empty comment line separates two paragraphs
%! src = "## para one\n##\n## para two\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_comment_split", src));
%! assert (! isempty (strfind (h, "<p>para one</p>")));
%! assert (! isempty (strfind (h, "<p>para two</p>")));

%!test  # a line continuation keeps the statement whole
%! src = "y = 1 + ...\n    2";
%! h = build_DEMOS (bist_demo_fixture ("bist_continuation", src));
%! assert (! isempty (strfind (h, "y = 3")));
%! assert (isempty (strfind (h, "error:")));

%!test  # a newline inside brackets does not terminate the statement
%! h = build_DEMOS (bist_demo_fixture ("bist_brackets", "A = [1, 2\n3, 4]"));
%! assert (! isempty (strfind (h, "A =")));
%! assert (isempty (strfind (h, "error:")));

%!test  # a block construct is one cell
%! src = "for i = 1:3\n  x = i;\nendfor\nx";
%! h = build_DEMOS (bist_demo_fixture ("bist_for", src));
%! assert (numel (strfind (h, "#eef5f8")), 1);
%! assert (! isempty (strfind (h, "x = 3")));

%!test  # a bare 'end' terminates a block just as 'endfor' does
%! src = "for i = 1:2\n  x = i;\nend\nz = 9";
%! h = build_DEMOS (bist_demo_fixture ("bist_bare_end", src));
%! assert (! isempty (strfind (h, "z = 9")));
%! assert (isempty (strfind (h, "error:")));

%!test  # nested blocks close correctly
%! src = "if (true)\n  for k = 1:2\n    x = k;\n  endfor\nendif\nx";
%! h = build_DEMOS (bist_demo_fixture ("bist_nested", src));
%! assert (! isempty (strfind (h, "x = 2")));
%! assert (isempty (strfind (h, "error:")));

%!test  # a do-until block is one cell
%! src = "do\n  x = 1;\nuntil (true)\nx";
%! h = build_DEMOS (bist_demo_fixture ("bist_do_until", src));
%! assert (! isempty (strfind (h, "x = 1")));
%! assert (isempty (strfind (h, "error:")));

%!test  # a switch block is one cell
%! src = ["switch (1)\n  case 1\n    x = 1;\n", ...
%!        "  otherwise\n    x = 2;\nendswitch\nx"];
%! h = build_DEMOS (bist_demo_fixture ("bist_switch", src));
%! assert (! isempty (strfind (h, "x = 1")));
%! assert (isempty (strfind (h, "error:")));

%!test  # a trailing inline comment stays with its code
%! src = "x = 1  ## set x";
%! h = build_DEMOS (bist_demo_fixture ("bist_inline_comment", src));
%! assert (! isempty (strfind (h, "## set x")));
%! assert (isempty (strfind (h, "<p>set x</p>")));

%!test  # 'end' used as an index does not terminate a block
%! src = "v = [1, 2, 3];\nw = v(end)";
%! h = build_DEMOS (bist_demo_fixture ("bist_end_index", src));
%! assert (! isempty (strfind (h, "w = 3")));
%! assert (isempty (strfind (h, "error:")));

%!test  # a comment marker inside a string is not a comment
%! src = "disp (\"50% done\")";
%! h = build_DEMOS (bist_demo_fixture ("bist_pct_string", src));
%! assert (! isempty (strfind (h, "50% done")));
%! assert (isempty (strfind (h, "<p>done</p>")));

%!test  # a block keyword inside a string does not open a block
%! src = "s = \"for me\";\nx = 1";
%! h = build_DEMOS (bist_demo_fixture ("bist_keyword_string", src));
%! assert (! isempty (strfind (h, "x = 1")));
%! assert (isempty (strfind (h, "error:")));

%!test  # a transpose is not mistaken for the opening of a string
%! src = "v = [1, 2];\nw = v'\nz = 2";
%! h = build_DEMOS (bist_demo_fixture ("bist_transpose", src));
%! assert (! isempty (strfind (h, "w =")));
%! assert (! isempty (strfind (h, "z = 2")));

%!test  # a full-line comment inside an open bracket stays part of the statement
%! src = "x = [1, ...\n## mid\n2]";
%! h = build_DEMOS (bist_demo_fixture ("bist_comment_bracket", src));
%! assert (isempty (strfind (h, "<p>mid</p>")));
%! assert (isempty (strfind (h, "error:")));

%!test  # a call spanning continuations and nested braces is one cell
%! src = "v = max ([1, 2, ...\n         3, 4], [], ...\n         2)";
%! h = build_DEMOS (bist_demo_fixture ("bist_multiline_call", src));
%! assert (! isempty (strfind (h, "v = 4")));
%! assert (isempty (strfind (h, "error:")));

%!test  # a field named after a keyword does not open a block
%! src = "s.for = 1;\nx = 2";
%! h = build_DEMOS (bist_demo_fixture ("bist_field_keyword", src));
%! assert (! isempty (strfind (h, "x = 2")));
%! assert (isempty (strfind (h, "error:")));

%!test  # a block comment becomes one comment cell
%! src = "%{\nnot code here\n%}\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_block_comment", src));
%! assert (! isempty (strfind (h, "not code here")));
%! assert (numel (strfind (h, "#eef5f8")), 1);

%!test  # a percent-style comment line is prose too
%! src = "% a percent comment\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_percent_comment", src));
%! assert (! isempty (strfind (h, "<p>a percent comment</p>")));

%!test  # a demo with nothing in it renders no cell at all
%! h = build_DEMOS (bist_demo_fixture ("bist_empty", ""));
%! assert (isempty (strfind (h, "#eef5f8")));
%! assert (isempty (strfind (h, "#fafafa")));

%!test  # output is emitted between the two code cells that surround it
%! src = "a = 1\nb = 2;";
%! h = build_DEMOS (bist_demo_fixture ("bist_interleaved", src));
%! i_out = strfind (h, "#fafafa");
%! i_in = strfind (h, "#eef5f8");
%! assert (numel (i_in), 2);
%! assert (i_in(1) < i_out(1) && i_out(1) < i_in(2));

%!test  # HTML metacharacters in the output of a demo are escaped
%! src = "disp (\"1 < 2 & 3 > 0\")";
%! h = build_DEMOS (bist_demo_fixture ("bist_escape", src));
%! assert (! isempty (strfind (h, "1 &lt; 2 &amp; 3 &gt; 0")));

%!test  # a figure drawn by a demo is printed and shown as a thumbnail
%! d = fullfile (tempdir (), "pkg_octave_doc_bist");
%! f = bist_demo_fixture ("bist_figure", "plot (1:3);");
%! oldpwd = pwd ();
%! unwind_protect
%!   cd (d);
%!   if (! isfolder ("assets"))
%!     mkdir ("assets");
%!   endif
%!   h = build_DEMOS (f);
%! unwind_protect_cleanup
%!   cd (oldpwd);
%! end_unwind_protect
%! assert (! isempty (strfind (h, "img-thumbnail")));
%! assert (numel (dir (fullfile (d, "assets", "*.png"))), 1);

%!test  # a paragraph of demo prose is rendered from its Markdown
%! src = "## Hello world\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_md_plain", src));
%! assert (! isempty (strfind (h, "                <p>Hello world</p>")));

%!test  # inline code in demo prose
%! src = "## call `fitcknn` first\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_md_code", src));
%! assert (! isempty (strfind (h, "<p>call <code>fitcknn</code> first</p>")));

%!test  # bold and italic in demo prose
%! src = "## this is **very** and *quite* good\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_md_emph", src));
%! assert (! isempty (strfind (h, ["<p>this is <strong>very</strong> and ", ...
%!                                 "<em>quite</em> good</p>"])));

%!test  # a link in demo prose
%! src = "## see [docs](https://octave.org)\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_md_link", src));
%! assert (! isempty (strfind (h, ["<p>see <a href=\"https://octave.org\">", ...
%!                                 "docs</a></p>"])));

%!test  # HTML metacharacters in demo prose are escaped
%! src = "## compare a < b & c > d\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_md_escape", src));
%! assert (! isempty (strfind (h, "<p>compare a &lt; b &amp; c &gt; d</p>")));

%!test  # markup inside a code span of demo prose is not interpreted
%! src = "## use `a*b*c` here\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_md_span", src));
%! assert (! isempty (strfind (h, "<p>use <code>a*b*c</code> here</p>")));

%!test  # an unordered list in demo prose
%! src = "## Steps:\n## - load\n## - fit\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_md_ul", src));
%! assert (! isempty (strfind (h, "<ul>")));
%! assert (! isempty (strfind (h, "<li>load</li>")));
%! assert (! isempty (strfind (h, "<li>fit</li>")));

%!test  # an ordered list in demo prose
%! src = "## 1. one\n## 2. two\nx = 1;";
%! h = build_DEMOS (bist_demo_fixture ("bist_md_ol", src));
%! assert (! isempty (strfind (h, "<ol>")));
%! assert (! isempty (strfind (h, "<li>one</li>")));
%! assert (! isempty (strfind (h, "<li>two</li>")));

%!test  # remove the fixture directory
%! d = fullfile (tempdir (), "pkg_octave_doc_bist");
%! rmpath (d);
%! if (isfolder (fullfile (d, "assets")))
%!   delete (fullfile (d, "assets", "*"));
%!   rmdir (fullfile (d, "assets"));
%! endif
%! delete (fullfile (d, "*.m"));
%! rmdir (d);
%! assert (! isfolder (d));
