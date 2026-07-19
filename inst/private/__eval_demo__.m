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
## @deftypefn  {pkg-octave-doc} {@var{cells} =} __eval_demo__ (@var{block}, @var{imgprefix}, @var{imgbase})
##
## Evaluate a DEMO block cell by cell and capture output and figures.
##
## @var{block} is the source of a single DEMO block.  It is split into cells by
## @code{__demo_segments__} and each code cell is evaluated in sequence in a
## single persistent workspace, so the notebook-style console output of each
## statement can be attached to the statement that produced it.
##
## @var{imgprefix} is the file-name prefix used for figures saved under the
## @qcode{assets/} folder and @var{imgbase} is the starting figure number.
##
## The returned @var{cells} is the struct array from @code{__demo_segments__}
## augmented with two fields: @qcode{output}, the console text captured for a
## code cell (empty for comment cells), and @qcode{images}, a cell array of the
## relative paths of any figures snapshotted at that cell.
##
## All local variables use a @qcode{__name__} form so a demo that assigns common
## names (e.g. @var{i}, @var{cells}) cannot clobber the evaluation state.
##
## @seealso{__demo_segments__, __demo_html__, build_DEMOS}
## @end deftypefn

function cells = __eval_demo__ (block, imgprefix, imgbase)

  if (nargin != 3 || ! ischar (block) || ! ischar (imgprefix))
    print_usage ();
  endif

  ## Copy inputs into private names; the demo runs in this workspace and must
  ## not be able to affect the control state through ordinary variable names.
  __cells__ = __demo_segments__ (block);
  __prefix__ = imgprefix;
  __imgn__ = imgbase;

  for __i__ = 1:numel (__cells__)
    __cells__(__i__).output = "";
    __cells__(__i__).images = {};
  endfor

  if (isempty (__cells__))
    cells = __cells__;
    return;
  endif

  ## Hide figures during evaluation and start from a clean slate
  __dfv__ = get (0, "defaultfigurevisible");
  set (0, "defaultfigurevisible", "off");
  close all;

  __snapped__ = [];    # handles of figures already captured
  __prevcur__ = [];    # current figure after the previous code cell
  __prevcode__ = 0;    # index of the previous code cell evaluated

  unwind_protect
    for __i__ = 1:numel (__cells__)
      if (! strcmp (__cells__(__i__).type, "code"))
        continue;
      endif

      ## Evaluate the cell, capturing everything it prints to the console
      try
        __cells__(__i__).output = evalc (__cells__(__i__).text);
      catch __err__
        __cells__(__i__).output = ["error: ", __err__.message];
        break;
      end_try_catch

      ## If the demo switched to a new figure, the previous one is finished:
      ## snapshot it now and attach it to the cell where it was last drawn.
      __cur__ = get (0, "currentfigure");
      if (! isempty (__prevcur__) && ! isequal (__cur__, __prevcur__)
          && ishghandle (__prevcur__)
          && ! any (double (__prevcur__) == __snapped__)
          && ! isempty (get (__prevcur__, "children")))
        __imgn__ += 1;
        __path__ = __snap_fig__ (__prevcur__, __prefix__, __imgn__);
        __tgt__ = __prevcode__;
        if (__tgt__ == 0)
          __tgt__ = __i__;
        endif
        __cells__(__tgt__).images{end+1} = __path__;
        __snapped__(end+1) = double (__prevcur__);
      endif

      __prevcur__ = __cur__;
      __prevcode__ = __i__;
    endfor

    ## Snapshot any figures still open at the end, in ascending handle order,
    ## attached to the last code cell that was evaluated.
    __figs__ = sort (double (get (0, "children")));
    for __f__ = 1:numel (__figs__)
      __fig__ = __figs__(__f__);
      if (! any (__fig__ == __snapped__) && ishghandle (__fig__)
          && ! isempty (get (__fig__, "children")))
        __imgn__ += 1;
        __path__ = __snap_fig__ (__fig__, __prefix__, __imgn__);
        if (__prevcode__ > 0)
          __cells__(__prevcode__).images{end+1} = __path__;
        endif
        __snapped__(end+1) = __fig__;
      endif
    endfor
  unwind_protect_cleanup
    close all;
    set (0, "defaultfigurevisible", __dfv__);
  end_unwind_protect

  cells = __cells__;

endfunction

## Save figure FIG as assets/PREFIX_N.png and return the relative path.
function path = __snap_fig__ (fig, prefix, n)
  name = sprintf ("%s_%d.svg", prefix, n);
  path = fullfile ("assets", name);
  print (fig, path, "-F:14","-S480,360");
endfunction

%!error <Invalid call> __eval_demo__ ()
%!error <Invalid call> __eval_demo__ ("x = 1")
%!error <Invalid call> __eval_demo__ (1, "p", 100)
