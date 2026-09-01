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
## @deftypefn  {pkg-octave-doc} {} folder_texi2cache ()
## @deftypefnx {pkg-octave-doc} {} folder_texi2cache (@qcode{'-auto'})
## @deftypefnx {pkg-octave-doc} {} folder_texi2cache (@qcode{'-check'})
## @deftypefnx {pkg-octave-doc} {} folder_texi2cache (@dots{}, @var{options})
## @deftypefnx {pkg-octave-doc} {@var{report} =} folder_texi2cache (@dots{})
##
## Rebuild the doc-cache of the current directory.
##
## Every function and class in the current directory is written afresh, along
## with the members of each class and the contents of any @file{+pkg} or
## @file{@@class} directory below it, and any entry that no longer corresponds
## to a file is dropped.  A @file{doc-cache} is a per-directory file, so this
## is the whole of one, which is what makes it the unit worth having: a
## directory rebuilt this way is in the state a full package rebuild would
## leave it in.
##
## The current directory must be a function directory of a package, so a
## package root, a @file{+pkg} or @file{@@class} directory, and @file{private},
## @file{tests}, @file{demos} or @file{datasets} are all refused, the middle
## two because their cache could be read by nothing.
##
## @qcode{'-auto'} narrows the work to what @code{git} reports as changed
## within this directory, and is the form to reach for while working in one: a
## directory holding many classes takes minutes to rebuild whole and seconds to
## refresh for the two files just edited.  Where there is no @code{git} to ask,
## or the tree is not a repository, it is ignored with a warning and the whole
## directory is rebuilt, which is what would have been asked for had the
## question been answerable.  A file that moved between
## directories is only half of its own rename here, the departure seen in the
## directory it left and the arrival in the one it joined, so run it in both or
## reach for @code{package_texi2cache} instead.
##
## @qcode{'-check'} writes nothing and reports what would change, and may be
## given together with @qcode{'-auto'} to ask whether the files just edited are
## already accounted for.
##
## @var{options} is a @code{pkg_doc_options} object.  Unlike the per-item
## functions, an @file{INDEX} given through it @strong{decides what is cached}:
## only the names it lists are written, so the cache holds the package's public
## surface rather than whatever the directory happens to carry.  A name found
## here but absent from @file{INDEX} is skipped and reported.  An @file{INDEX}
## entry answering to no file is not reported at this scope, since a directory
## cannot tell one naming a file elsewhere from one naming nothing at all.
##
## @var{report} is a struct with the fields @qcode{'cache'}, @qcode{'added'},
## @qcode{'updated'}, @qcode{'removed'}, @qcode{'changed'} and
## @qcode{'findings'}.  With no output requested the same information is
## printed.
##
## @seealso{package_texi2cache, classdef_texi2cache, function_texi2cache,
## pkg_doc_options}
## @end deftypefn

function report = folder_texi2cache (varargin)

  ## Input validation
  auto = false;
  check = false;
  options = pkg_doc_options ();
  for ii = 1:numel (varargin)
    arg = varargin{ii};
    if (isa (arg, 'pkg_doc_options'))
      options = arg;
    elseif (ischar (arg) && isrow (arg) && strcmp (arg, '-auto'))
      auto = true;
    elseif (ischar (arg) && isrow (arg) && strcmp (arg, '-check'))
      check = true;
    else
      error (strcat ("folder_texi2cache: arguments are '-auto', '-check',", ...
                     " and a pkg_doc_options object."));
    endif
  endfor

  here = pwd ();
  __refuse_directory__ (here);

  ## Read the definitions from the tree rather than from the session
  clear functions;
  [listed, pkgname, why] = __index_info__ (options);
  seed = __index_notfound__ (options, why);

  ## '-auto' narrows the work to what git reports as changed, where it can be
  ## asked at all
  changed = {};
  if (auto)
    [changed, why] = __git_changed__ (here);
    if (! isempty (why))
      warning (strcat ("folder_texi2cache: %s, so '-auto' is ignored", ...
                       " and the whole directory is rebuilt."), why);
      auto = false;
    endif
  endif

  report = __folder_cache__ ('folder_texi2cache', here, options, listed, ...
                             pkgname, auto, changed, check);
  if (! isempty (seed))
    report.findings = [seed, report.findings];
  endif

  if (nargout == 0)
    __show_report__ (report, options);
    clear report;
  endif

endfunction

## Refuse a directory whose cache nothing could read, or that holds no
## functions of its own
function __refuse_directory__ (here)
  [~, base] = fileparts (here);
  if (! isempty (base) && (base(1) == '+' || base(1) == '@'))
    error (strcat ("folder_texi2cache: a cache inside '%s' can be read by", ...
                   " nothing; stand in the directory holding it."), base);
  endif
  if (any (strcmp (base, {'private', 'tests', 'demos', 'datasets'})))
    error ("folder_texi2cache: '%s' carries no help text.", base);
  endif
  if (exist (fullfile (here, 'DESCRIPTION'), 'file'))
    error (strcat ("folder_texi2cache: this is a package root, not a", ...
                   " function directory."));
  endif
endfunction

## The cases build a small function directory in a temporary place and cd into
## it.  Each writes what it needs rather than sharing a helper, the function
## issuing clear functions and that removing a %!function block for good.  The
## last block removes the fixture.

%!test  # a directory is cached whole, every shape of name included
%! d = fullfile (tempdir (), 'pkg_octave_doc_fd_bist');
%! if (isfolder (d))
%!   confirm_recursive_rmdir (false, 'local');
%!   rmdir (d, 's');
%! endif
%! mkdir (d);
%! mkdir (fullfile (d, '+ns'));
%! mkdir (fullfile (d, '@old'));
%! names = {fullfile(d, 'bistplain.m'), 'bistplain'; ...
%!          fullfile(d, '+ns', 'bistns.m'), 'bistns'; ...
%!          fullfile(d, '@old', 'bistmeth.m'), 'bistmeth'};
%! for ii = 1:rows (names)
%!   fid = fopen (names{ii,1}, 'w');
%!   fprintf (fid, '## -*- texinfo -*-\n');
%!   fprintf (fid, '## @deftypefn {bistpkg} {} %s ()\n##\n', names{ii,2});
%!   fprintf (fid, '## A function written for the folder tests.\n##\n');
%!   fprintf (fid, '## A body line that is distinctive enough to look for.\n');
%!   fprintf (fid, '##\n## @end deftypefn\n');
%!   fprintf (fid, 'function %s ()\nendfunction\n', names{ii,2});
%!   fclose (fid);
%! endfor
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   r = folder_texi2cache ();
%!   s = load ('doc-cache');
%!   cached = s.cache(1,:);
%!   assert (any (strcmp (cached, 'bistplain')));
%!   assert (any (strcmp (cached, 'ns.bistns')));
%!   assert (any (strcmp (cached, '@old/bistmeth')));
%!   assert (r.changed, true);
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # a second run changes nothing, and a check on a current tree agrees
%! d = fullfile (tempdir (), 'pkg_octave_doc_fd_bist');
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   r = folder_texi2cache ();
%!   assert (r.changed, false);
%!   r = folder_texi2cache ('-check');
%!   assert (r.changed, false);
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # a check reports what would change and writes nothing
%! d = fullfile (tempdir (), 'pkg_octave_doc_fd_bist');
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   before = fileread ('doc-cache');
%!   fid = fopen (fullfile (d, 'bistextra.m'), 'w');
%!   fprintf (fid, '## -*- texinfo -*-\n## @deftypefn {bistpkg} {} bistextra ()\n');
%!   fprintf (fid, '##\n## A function added after the cache.\n##\n');
%!   fprintf (fid, '## A body line that is distinctive enough to look for.\n');
%!   fprintf (fid, '##\n## @end deftypefn\n');
%!   fprintf (fid, 'function bistextra ()\nendfunction\n');
%!   fclose (fid);
%!   r = folder_texi2cache ('-check');
%!   assert (r.changed, true);
%!   assert (any (strcmp (r.added, 'bistextra')));
%!   assert (fileread ('doc-cache'), before);
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # INDEX decides what a whole scope caches
%! d = fullfile (tempdir (), 'pkg_octave_doc_fd_bist');
%! fid = fopen (fullfile (d, 'INDEX'), 'w');
%! fputs (fid, "bistpkg >> Bist Package\nDocumentation\n bistplain\n");
%! fclose (fid);
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   o = pkg_doc_options ();
%!   o.IndexLocation = fullfile (d, 'INDEX');
%!   r = folder_texi2cache (o);
%!   s = load ('doc-cache');
%!   cached = s.cache(1,:);
%!   assert (any (strcmp (cached, 'bistplain')));
%!   assert (! any (strcmp (cached, 'ns.bistns')));
%!   assert (any (strcmp ({r.findings.rule}, 'IndexMissingEntry')));
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # '-auto' outside a repository rebuilds everything instead of failing
%! d = fullfile (tempdir (), 'pkg_octave_doc_fd_bist');
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   delete ('doc-cache');
%!   warning ('off', 'all');
%!   unwind_protect
%!     r = folder_texi2cache ('-auto');
%!   unwind_protect_cleanup
%!     warning ('on', 'all');
%!   end_unwind_protect
%!   s = load ('doc-cache');
%!   assert (any (strcmp (s.cache(1,:), 'bistplain')));
%!   assert (any (strcmp (s.cache(1,:), 'ns.bistns')));
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # the directories whose cache nothing could read are refused
%! d = fullfile (tempdir (), 'pkg_octave_doc_fd_bist');
%! old = pwd ();
%! unwind_protect
%!   for sub = {'+ns', '@old'}
%!     cd (fullfile (d, sub{1}));
%!     fail ('folder_texi2cache ()', 'can be read by nothing');
%!   endfor
%!   mkdir (fullfile (d, 'private'));
%!   cd (fullfile (d, 'private'));
%!   fail ('folder_texi2cache ()', 'carries no help text');
%!   mkdir (fullfile (d, 'root'));
%!   fid = fopen (fullfile (d, 'root', 'DESCRIPTION'), 'w');
%!   fputs (fid, "Name: bistpkg\n");
%!   fclose (fid);
%!   cd (fullfile (d, 'root'));
%!   fail ('folder_texi2cache ()', 'package root, not a function directory');
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # remove the fixture directory
%! d = fullfile (tempdir (), 'pkg_octave_doc_fd_bist');
%! confirm_recursive_rmdir (false, 'local');
%! rmdir (d, 's');
%! assert (! isfolder (d));

## Test input validation
%!error<folder_texi2cache: arguments are '-auto', '-check', and a pkg_doc_options object.> ...
%! folder_texi2cache ('-nosuchflag')
%!error<folder_texi2cache: arguments are '-auto', '-check', and a pkg_doc_options object.> ...
%! folder_texi2cache (5)
