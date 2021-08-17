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
## @deftypefn {Function File} get_output ()
## undocumented internal function
## @end deftypefn

function [text, images] = get_output (demo_num, ...
  code, imagedir, full_imagedir, fileprefix)
  
### This function must not be a subfunction, since declaring variables
### in eval'ed code is not allowed (anymore). See
### http://savannah.gnu.org/bugs/?52632

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
