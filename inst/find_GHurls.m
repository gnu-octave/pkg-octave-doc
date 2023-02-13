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
## @deftypefn  {pkg-octave-doc} {@var{fcnurls} =} find_GHurls (@var{pkgurl}, @var{pkgfcns})
##
## Retrieve unique URLs to every function's location within the package's GitHub
## repository.
##
## @seealso{function_texi2html}
## @end deftypefn

function pkgfcns = find_GHurls (pkgurl, pkgfcns)

  if (! ischar (pkgurl))
    print_usage ();
  endif

  ## Check if package repository is at GitHub
  GH = strfind (pkgurl, "https://github.com/");
  if (GH != 1)
    error ("find_sourcecode: package repository must be at GitHub.");
  endif

  ## Clone repository in a temp directory
  tmpDIR = tempname();
  [status, ~] = unix (sprintf ("git clone %s.git %s > /dev/null 2>&1", ...
                               pkgurl, tmpDIR));
  if (status)
    warning ("package_texi2html: unable to clone %s.git.", pkgurl);
    warning ("Link to source code in HTML pages will be omitted.");
    return;
  endif

  ## Find files and folders' contents in repository root
  fcnurls = dir (fullfile (tmpDIR, "**/*.*"));
  fcnurls = struct2cell (fcnurls)';

  subforders = true;
  level = 0;
  while (subforders)

    ## Find each function's index in cell array and retrieve url to source code
    for i = 1:size (pkgfcns, 1)

      ## Check for .m, .cc, or cpp files (m, oct, mex, respectively)
      if (exist (pkgfcns{i,1}) == 2)
        fcnname = strsplit (pkgfcns{i,1}, filesep){end};
        fcnfilename = [fcnname, ".m"];
        fcn_idx = find (strcmp (fcnurls(:,1), fcnfilename));
      else
        fcnname = strsplit (pkgfcns{i,1}, filesep){end};
        fcnfilename = [fcnname, ".cc"];
        fcn_idx = find (strcmp (fcnurls(:,1), fcnfilename));
        if (isempty (fcn_idx))
        fcnname = strsplit (pkgfcns{i,1}, filesep){end};
          fcnfilename = [fcnname, ".cpp"];
          fcn_idx = find (strcmp (fcnurls(:,1), fcnfilename));
        endif
      endif

      ## Check that function exists in this directory level
      if (! isempty (fcn_idx))
        base_fd = strsplit (fcnurls{fcn_idx,2}, filesep)([end-level:end]);
        path_fd = fullfile ("tree/main", base_fd(:){:});
        full_fd = fullfile (path_fd, fcnfilename);
        fcn_url = strcat (pkgurl, "/", full_fd);
        pkgfcns(i,3) = fcn_url;
      endif

    endfor

    ## Find folders in root for next level and regenerate the dir list
    newfolders = fcnurls(find (cell2mat (fcnurls(:,5))),1);
    dirfolders = fcnurls(find (cell2mat (fcnurls(:,5))),2);
    if (! isempty (newfolders))
      level += 1;
      fcnurls = {};
      for i = 1:numel (newfolders)
        tmp = dir (fullfile (dirfolders{i}, newfolders{i}, "*.*"));
        tmp = struct2cell (tmp)';
        fcnurls = [fcnurls; tmp];
      endfor
    else
      subforders = false;
    endif

  endwhile

endfunction

