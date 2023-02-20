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
## Generate HTML code from the available DEMOS of a particular function.
##
## @itemize
## @item
## @var{fcnname} is a char string with the function's name.
##
## @item
## @var{html} is a char string with the generated HTML code based on the
## @qcode{demos_template.html} layout for every DEMO available in @var{fcnname}.
## @end itemize
##
## @seealso{find_DEMOS, function_texi2html, find_GHurls}
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

    ## Fixed HTML strings
    tmp_0 = "                  <table><tbody><tr>\n";
    tmp_1 = "                    <td>&nbsp;</td>\n";
    tmp_2 = "                    <td><pre class=""example"">\n";
    tmp_3 = "                    </pre></td></tr></tbody>\n";
    tmp_4 = "                  </table>\n";
    tmp_5 = "                  <div class=""text-center"">\n";
    tmp_6 = "                    <img src=""";
    tmp_7 = """ class=""rounded img-thumbnail""";
    tmp_8 = " alt=""plotted figure"">\n";
    tmp_9 = "                  </div><p></p>\n";

    ## For each demo
    for demo_num = 1:numel (demos)
      try
        ## Initialize HTML string for this demo
        demo_html = "";

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

          ## Format HTML string with demo code
          code = demos{demo_num};
          demo_html = [demo_html tmp_0 tmp_1 tmp_2 code "\n"];

          ## Evaluate DEMO code
          diary (diary_file);
          eval (code);
          diary ("off");

          ## Read __diary__.txt
          fid = fopen (diary_file);
          demo_text = fscanf (fid, "%c", Inf);
          fclose (fid);

          ## Format HTML string with demo output
          demo_html = [demo_html demo_text tmp_3 tmp_4];

          ## Save figures
          images = {};
          figure_num = demo_num * 100;
          while (! isempty (get (0, "currentfigure")))
            figure_num = figure_num + 1;
            fig = gcf ();
            name = sprintf ("%s_%d.png", fcnfile, figure_num);
            fullpath = fullfile ("assets", name);
            print (fig, fullpath);
            images{end+1} = fullpath;
            close (fig);
          endwhile

          ## Reverse image list, since we got them latest-first
          images = images (end:-1:1);

          ## Add reference to image (if applicable)
          if (! isempty (images))
            for i = 1:numel (images)
              demo_html = [demo_html tmp_5 tmp_6];
              demo_html = [demo_html sprintf("%s", images{i})];
              demo_html = [demo_html tmp_7 tmp_8 tmp_9];
            endfor
          endif

          ## Append demo demo_html to html
          full_demo_html = strrep (demos_template, "{{NUMBER}}", ...
                              sprintf ("%d", demo_num));
          full_demo_html = strrep (full_demo_html, "{{DEMO}}", ...
                              sprintf ("%s", demo_html));
          full_demo_html = [full_demo_html "\n"];
        unwind_protect_cleanup
          delete (diary_file);
          set (0, "defaultfigurevisible", dfv);
          PAGER(oldpager);
          page_screen_output(oldpso);
        end_unwind_protect

        html = [html full_demo_html];
      catch
        printf ("Unable to process demo %d from %s:\n %s\n", ...
                demo_num, fcnname, lasterr);
      end_try_catch
    endfor
  endif

endfunction

%!error find_DEMOS ()
%!error find_DEMOS (1)
%!error find_DEMOS ("function_texi2html", 1)

