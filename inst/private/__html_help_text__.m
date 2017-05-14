## Copyright (C) 2008 Soren Hauberg <soren@hauberg.org>
## Copyright (C) 2014, 2015 Julien Bect <jbect@users.sourceforge.net>
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} __html_help_text__ ()
## undocumented internal function
## @end deftypefn

function __html_help_text__ (outname, vpars)

  name = vpars.name;

  ## Get the help text of the function
  [text, format] = get_help_text (name);

  ## Take action depending on help text format
  switch (lower (format))
    case "plain text"
      text = sprintf ("<pre>%s</pre>\n", text);
    case "texinfo"
      [~, text] = __texi2html__ (text, vpars);
    case "not documented"
      text = sprintf ("<pre>Not documented</pre>\n");
    case "not found"
      error ("`%s' not found\n", name);
    otherwise
      error ("Internal error: unsupported help text format '%s' for '%s'",
             format, name);
  endswitch

  ## Read options.
  header = getopt ("header", vpars);
  title  = getopt ("title",  vpars);
  footer = getopt ("footer", vpars);

  ## Add demo:// links if requested
  if (getopt ("include_demos"))
    ## Determine if we have demos
    [code, idx] = test (name, "grabdemo");
    if (length (idx) > 1)
      ## Demos to the main text
      demo_text = "";

      outdir = fileparts (outname);
      imagedir = "images";
      full_imagedir = fullfile (outdir, imagedir);
      num_demos = length (idx) - 1;
      demo_num = 0;
      for k = 1:num_demos
        ## Run demo
        code_k = code (idx (k):idx (k+1)-1);
        try
          [output, images] = get_output (k, ...
            code_k, imagedir, full_imagedir, name);
        catch
          lasterr ()
          continue;
        end_try_catch
        has_text = !isempty (output);
        has_images = !isempty (images);
        if (length (images) > 1)
          ft = "figures";
        else
          ft = "figure";
        endif

        ## Create text
        demo_num ++;
        demo_header = sprintf ("<h2>Demonstration %d</h2>\n<div class=\"demo\">\n", demo_num);
        demo_footer = "</div>\n";

        demo_k{1} = "<p>The following code</p>\n";
        demo_k{2} = sprintf ("<pre class=\"example\">%s</pre>\n", code_k);
        if (has_text && has_images)
          demo_k{3} = "<p>Produces the following output</p>\n";
          demo_k{4} = sprintf ("<pre class=\"example\">%s</pre>\n", output);
          demo_k{5} = sprintf ("<p>and the following %s</p>\n", ft);
          demo_k{6} = sprintf ("<p>%s</p>\n", images_in_html (images));
        elseif (has_text) # no images
          demo_k{3} = "<p>Produces the following output</p>\n";
          demo_k{4} = sprintf ("<pre class=\"example\">%s</pre>\n", output);
        elseif (has_images) # no text
          demo_k{3} = sprintf ("<p>Produces the following %s</p>\n", ft);
          demo_k{6} = sprintf ("<p>%s</p>\n", images_in_html (images));
        else # neither text nor images
          demo_k{3} = sprintf ("<p>gives an example of how '%s' is used.</p>\n", name);
        endif

        demo_text = strcat (demo_text, demo_header, demo_k{:}, demo_footer);
      endfor

      text = strcat (text, demo_text);
    endif
  endif

  ## Write result to disk
  fid = fopen (outname, "w");
  if (fid < 0)
    error ("Could not open '%s' for writing", outname);
  endif
  fprintf (fid, "%s\n%s\n%s", header, text, footer);
  fclose (fid);

endfunction


function [text, images] = get_output (demo_num, ...
  code, imagedir, full_imagedir, fileprefix)
  
  ## Clear everything
  close all
  diary_file = "__diary__.txt";
  if (exist (diary_file, "file"))
    delete (diary_file);
  endif

  unwind_protect
    ## Hide figures only if gnuplot is in use
    ## (fltk doesn't currently support offscreen printing; see bug #33180)
    def = get (0, "defaultfigurevisible");
    if strcmp (graphics_toolkit, "gnuplot")
      set (0, "defaultfigurevisible", "off");
    endif

    ## Pager off
    more_val = page_screen_output (false);

    ## Evaluate the code
    diary (diary_file);
    eval (code);
    diary ("off");

    ## Read the results
    fid = fopen (diary_file, "r");
    diary_data = char (fread (fid).');
    fclose (fid);

    ## Remove 'diary ("off");' from the diary
    idx = strfind (diary_data, "diary (\"off\");");
    if (isempty (idx))
      text = diary_data;
    else
      text = diary_data (1:idx (end)-1);
    endif
    text = strtrim (text);

    ## Save figures
    if (!isempty (get (0, "currentfigure")) && !exist (full_imagedir, "dir"))
      [succ, msg] = mkdir (full_imagedir);
      if (!succ)
        error ("Unable to create directory %s:\n %s", full_imagedir, msg);
      endif
    endif

    ## For @class methods: Clean up fileprefix
    fileprefix = strrep (fileprefix, filesep (), '_');

    images = {};
    r = demo_num * 100;
    while (!isempty (get (0, "currentfigure")))
      r = r + 1;
      fig = gcf ();
      name = sprintf ("%s_%d.png", fileprefix, r);
      full_filename = fullfile (full_imagedir, name);
      filename = fullfile (imagedir, name);
      print (fig, full_filename);
      images{end+1} = filename;
      close (fig);
    endwhile

    ## Reverse image list, since we got them latest-first
    images = images (end:-1:1);

  unwind_protect_cleanup
    delete (diary_file);
    set (0, "defaultfigurevisible", def);
    page_screen_output (more_val);
  end_unwind_protect
endfunction

function text = images_in_html (images)
  header = "<table class=\"images\">\n<tr>\n";
  footer = "</tr></table>\n";
  headers = sprintf ("<th class=\"images\">Figure %d</th>\n", 1:numel (images));
  ims = sprintf ("<td class=\"images\"><img src=\"%s\" class=\"demo\"/></td>\n", images{:});
  text = strcat (header, headers, "</tr><tr>\n", ims, footer);
endfunction
