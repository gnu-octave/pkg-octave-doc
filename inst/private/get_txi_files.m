## Copyright (C) 2008 Soren Hauberg <soren@hauberg.org>
## Copyright (C) 2014 Julien Bect <jbect@users.sourceforge.net>
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

function file_list = get_txi_files (srcdir)

  txi_dir = fullfile (srcdir, "doc", "interpreter");
  octave_texi = fullfile (txi_dir, "octave.texi");

  ## Pattern for finding @include lines in octave.texi
  pat = '^@include\s*(?<filename>\S*?)\.texi\s*$';

  ## List of *.texi files to be ignored
  ## Note: version.texi was renamed to version-octave.texi between 4.0 and 4.2
  ignore_list = {"macros", "version", "version-octave"};

  ## Open octave.texi for reading
  [fid, errmsg] = fopen (octave_texi, "rt");
  if (fid == -1)
    fprintf (stderr, "\nCannot open %s for reading.\n\n", octave_texi);
    error (errmsg);
  endif

  file_list = {};
  while (true)

    ## Read one more line
    line = fgetl (fid);
    if (line == -1)
      break;
    endif

    ## Pattern matching
    s = regexp (line, pat, "names");
    if (isempty (s))
      f = {};
    else
      f = s(1).filename;
    endif

    ## Add to the file list
    if (~ isempty (f)) && (~ any (strcmpi (f, ignore_list)))
      file_list{end+1} = fullfile (txi_dir, [f ".txi"]);
    endif

  endwhile

  fclose (fid);

endfunction
