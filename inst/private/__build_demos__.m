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
## @deftypefn  {pkg-octave-doc} {@var{html} =} __build_demos__ (@var{fcnname}, @var{collapsed}, @var{figformat})
##
## Build notebook-style HTML for the DEMO blocks of a function or class member.
##
## This is the body of @code{build_DEMOS}, taking its three arguments already
## validated: @var{fcnname} a char string, @var{collapsed} a logical scalar, and
## @var{figformat} either @qcode{'png'} or @qcode{'svg'} in lower case.
##
## @code{build_DEMOS} is the documented entry point and validates on behalf of a
## caller from outside the package.  The doc-generating functions call this one
## instead, since each of them has already validated @var{figformat} where it
## entered the package; a package build reaches this point once per function and
## once per class member, and there is nothing to re-check at each of them.
##
## @seealso{build_DEMOS, __demo_notebook__, __reset_classes__, find_DEMOS}
## @end deftypefn

function html = __build_demos__ (fcnname, collapsed, figformat)

  if (nargin != 3)
    print_usage ();
  endif

  ## Get available demos from function
  html = "";
  demos = find_DEMOS (fcnname);

  if (isempty (demos))
    return;
  endif

  ## Figure file names follow the convention of the generated HTML pages: a "."
  ## is kept, whether it separates a package from a class or a class from a
  ## member, and "_" stands only for the file separator of an old-style
  ## "@class/method" name.  A member's figures therefore sit beside its page,
  ## e.g. prob.NormalDistribution.pdf-101.png next to
  ## prob.NormalDistribution.pdf.html.  __eval_demo__ appends "-N" for the
  ## figure number, which "_" cannot do: a function name may contain one.
  fcnfile = strrep (fcnname, filesep, "_");

  ## The anchor id cannot keep the ".": it breaks Bootstrap's collapse toggle,
  ## which resolves data-bs-target with querySelector and would read
  ## "#Class.method-example1" as id "Class" plus class "method-example1".
  fcnanchor = regexprep (fcnname, "[^A-Za-z0-9]", "_");

  ## Collapse state: a collapsed card starts closed, an expanded one open
  if (collapsed)
    show_cls = "";
    expanded = "false";
  else
    show_cls = " show";
    expanded = "true";
  endif

  ## Load demos template
  demos_template = fileread (fullfile ("_layouts", "demos_template.html"));

  ## For each demo, render notebook-style HTML and wrap it in the card template
  for demo_num = 1:numel (demos)
    try
      demo_html = __demo_notebook__ (demos{demo_num}, fcnfile, ...
                                     demo_num * 100, figformat);
      anchor = sprintf ("%s-example%d", fcnanchor, demo_num);
      full_demo_html = strrep (demos_template, "{{ANCHOR}}", anchor);
      full_demo_html = strrep (full_demo_html, "{{NUMBER}}", ...
                               sprintf ("%d", demo_num));
      full_demo_html = strrep (full_demo_html, "{{SHOW}}", show_cls);
      full_demo_html = strrep (full_demo_html, "{{EXPANDED}}", expanded);
      full_demo_html = strrep (full_demo_html, "{{DEMO}}", demo_html);
      html = [html full_demo_html "\n"];
    catch
      printf ("Unable to process demo %d from %s:\n %s\n", ...
              demo_num, fcnname, lasterr);
    end_try_catch

    ## Reset classdef dispatch state so a demo cannot poison the ones that
    ## follow it (all demos of a package build share one Octave process).  See
    ## https://octave.discourse.group/t/octave-core-classdef-dispatch-bug/7633
    __reset_classes__ ();
  endfor

endfunction
