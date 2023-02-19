## Copyright (C) 2023 Andreas Bertsatos <abertsatos@biol.uoa.gr>
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
## @deftypefn  {pkg-octave-doc} {@var{html} =} build_DEMOS (@var{fcnname})
##
## Build HTML from available DEMOS in a particular function.
##
## @seealso{function_texi2html, find_GHurls}
## @end deftypefn

function html = build_DEMOS (fcnname)

  if (nargin != 1)
    print_usage ();
  endif

  if (! ischar (fcnname))
    print_usage ();
  endif

  ## Get available demos from function
  html = "";
  demos = find_DEMOS (fcnname);

  ## For @class methods: Clean up fileprefix
  fcnfile = strrep (fcnname, filesep, "_");

  if (! isempty (demos))

    ## Load demos template
    demos_template = fileread (fullfile ("_layouts", "demos_template.html"));

    ## For each demo
    for demo_num = 1:numel (demos)

      text = "";

      ## Prepare environment variables
      close all
      diary_file = "__diary__.txt";
      if (exist (diary_file, "file"))
        delete (diary_file);
      endif
      unwind_protect
        ## Get current values
        dfv = get (0, "defaultfigurevisible");
        set (0, "defaultfigurevisible", "off");
        oldpager = PAGER('/dev/null');
        oldpso = page_screen_output(1);
        oldpoi = page_output_immediately(1);

        ## Format HTML string with demo code
        code = demos{demo_num};
        text = [text "                  <table><tbody><tr>\n"];
        text = [text "                    <td>&nbsp;</td>\n"];
        text = [text "                    <td><pre class=""example"">\n"];
        text = [text code];

        ## Evaluate DEMO code
        diary (diary_file);
        eval (code);
        diary ("off");

        ## Read __diary__.txt
        fid = fopen (diary_file);
        demo_text = fscanf (fid, "%c", Inf);
        fclose (fid);
        #demo_text = strtrim (diary_text);

        ## Format HTML string
        newline = strfind (demo_text, "\n");
        for i = 1:numel (newline) - 1
          tmp = demo_text([newline(i):newline(i+1)-1]);
          text = strcat(text, sprintf("%s", tmp));
        endfor
        text = [text "                    </pre></td></tr></tbody>\n"];
        text = [text "                  </table>\n"];

        ## Save figures
        images = {};
        r = demo_num * 100;
        while (! isempty (get (0, "currentfigure")))
          r = r + 1;
          fig = gcf ();
          name = sprintf ("%s_%d.png", fcnfile, r);
          fullpath = fullfile ("assets", name);
          print (fig, fullpath);
          images{end+1} = fullpath;
          close (fig);
        endwhile

        ## Reverse image list, since we got them latest-first
        images = images (end:-1:1);

        if (! isempty (images))
          for i = 1:numel (images)
            text = [text "                  <div class=""text-center"">\n"];
            text = [text "                    <img src="""];
            text = [text sprintf("%s", images{i})];
            text = [text """ class=""rounded img-thumbnail"""];
            text = [text " alt=""plotted figure"">\n"];
            text = [text "                  </div><p></p>\n"];
          endfor
        endif

        ## Append demo text to html
        demo_html = strrep (demos_template, "{{NUMBER}}", ...
                            sprintf ("%d", demo_num));
        demo_html = strrep (demo_html, "{{DEMO}}", sprintf ("%s", text));
        demo_html = [demo_html "\n"];
      unwind_protect_cleanup
        delete (diary_file);
        set (0, "defaultfigurevisible", dfv);
        PAGER(oldpager);
        page_screen_output(oldpso);
        page_output_immediately(oldpoi);
      end_unwind_protect

      html = [html demo_html];
    endfor
  endif

endfunction

%!error find_DEMOS ()
%!error find_DEMOS (1)
%!error find_DEMOS ("function_texi2html", 1)

