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
## @deftypefn  {pkg-octave-doc} {} package_texi2cache ()
## @deftypefnx {pkg-octave-doc} {} package_texi2cache (@qcode{'-auto'})
## @deftypefnx {pkg-octave-doc} {} package_texi2cache (@qcode{'-check'})
## @deftypefnx {pkg-octave-doc} {} package_texi2cache (@dots{}, @var{options})
## @deftypefnx {pkg-octave-doc} {@var{status} =} package_texi2cache (@dots{})
## @deftypefnx {pkg-octave-doc} {[@var{status}, @var{report}] =} package_texi2cache (@dots{})
##
## Regenerate the @file{doc-cache} files of a package from its source tree.
##
## A @file{doc-cache} is the file @code{lookfor} searches.  Octave builds one
## per directory, resolving every file by its bare name, so a class contributes
## a single entry and its methods and properties contribute none: they are
## invisible to @code{lookfor} and to everything built on it.  This writes them
## in, choosing exactly the members @code{classdef_texi2html} publishes, so a
## class reads the same way online and in a search.
##
## Run it at the package root, which is where @file{INDEX} lives.  Every cache
## below the root is written, one per directory that can be reached by the load
## path; a @file{+pkg} or @file{@@class} directory has none of its own, since
## nothing could read one, so its names are written into the cache of the
## nearest ordinary directory above it.
##
## @file{src} is written too, and its cache belongs to it: a build installs
## the compiled files into an architecture directory of their own, and the
## cache goes with them, which is why it is not folded into the cache of
## @file{inst}.  A @code{DEFUN_DLD} help text lives inside the compiled file,
## so an entry is written for one whose @file{.oct} is present and newer than
## its source, and a stale or missing one stops the run and asks for a build.
##
## @qcode{'-auto'} rebuilds only what changed, taking the work from
## @code{git}: everything that differs from @code{HEAD}, staged and unstaged
## alike, together with the untracked files, since a function written but never
## committed is invisible to a diff.  Where there is no @code{git} to ask, or
## the tree is not a repository, it is ignored with a warning and the whole
## package is rebuilt.
##
## @qcode{'-check'} writes nothing and reports what would change, so that a
## tree can be tested for a stale cache without touching it.  It may be given
## together with @qcode{'-auto'}, which asks the same question of the changed
## files alone.  Since every docstring is checked as it is parsed, this is also
## how a package is examined for broken texinfo without writing anything.
##
## @var{options} is a @code{pkg_doc_options} object.  Called without one, the
## settings are read from @file{doc-options.json} at the package root if it
## carries one, and are the defaults if it does not, so a package's own
## conventions are applied by anyone who builds its documentation.  The
## @file{INDEX} of the root is read unless the object names another, and it
## decides what is cached: only the names it lists are written.
##
## @var{status} is the number of cache files that changed, or under
## @qcode{'-check'} would change, and is therefore zero when the tree is
## current.  @var{report} is a struct array with one element per cache file
## touched, carrying the fields @qcode{'cache'}, @qcode{'added'},
## @qcode{'updated'}, @qcode{'removed'}, @qcode{'changed'} and
## @qcode{'findings'}.  With no output requested the same information is
## printed.
##
## This is the only form that reports an @file{INDEX} entry answering to no
## file, a single directory being unable to tell one naming a file elsewhere
## from one naming nothing at all.
##
## @seealso{folder_texi2cache, classdef_texi2cache, function_texi2cache,
## package_texi2html, pkg_doc_options, doc_cache_create, lookfor}
## @end deftypefn

function [status, report] = package_texi2cache (varargin)

  ## Input validation
  auto = false;
  check = false;
  options = [];
  for ii = 1:numel (varargin)
    arg = varargin{ii};
    if (isa (arg, 'pkg_doc_options'))
      options = arg;
    elseif (ischar (arg) && isrow (arg) && strcmp (arg, '-auto'))
      auto = true;
    elseif (ischar (arg) && isrow (arg) && strcmp (arg, '-check'))
      check = true;
    else
      error (strcat ("package_texi2cache: arguments are '-auto',", ...
                     " '-check', and a pkg_doc_options object."));
    endif
  endfor

  root = pwd ();
  if (! exist (fullfile (root, 'DESCRIPTION'), 'file'))
    error (strcat ("package_texi2cache: this is not a package root; run", ...
                   " it where DESCRIPTION and INDEX are."));
  endif

  ## A package's own settings travel with it, under a name the tool knows
  if (isempty (options))
    config = fullfile (root, 'doc-options.json');
    if (exist (config, 'file'))
      options = pkg_doc_options (config);
    else
      options = pkg_doc_options ();
    endif
  endif
  ## Only an unspecified location is filled in from the root: '' asks for no
  ## INDEX at all, which is a decision and not an omission
  why = '';
  if (! ischar (options.IndexLocation))
    index = fullfile (root, 'INDEX');
    if (exist (index, 'file'))
      options.IndexLocation = index;
    else
      why = 'this package carries no INDEX';
    endif
  endif

  ## Read the definitions from the tree rather than from the session
  clear functions;
  [listed, pkgname, badindex] = __index_info__ (options);
  if (! isempty (badindex))
    why = badindex;
  endif
  seed = __index_notfound__ (options, why);

  ## '-auto' narrows the work to what git reports as changed, where it can be
  ## asked at all
  changed = {};
  if (auto)
    [changed, why] = __git_changed__ (root);
    if (! isempty (why))
      warning (strcat ("package_texi2cache: %s, so '-auto' is ignored", ...
                       " and the whole package is rebuilt."), why);
      auto = false;
    endif
  endif

  dirs = __cache_dirs__ (root);
  if (isempty (dirs))
    error (strcat ("package_texi2cache: this package has neither an inst", ...
                   " nor a src directory."));
  endif

  status = 0;
  report = struct ('cache', {}, 'added', {}, 'updated', {}, 'removed', {}, ...
                   'changed', {}, 'findings', {});
  cached = {};
  for ii = 1:numel (dirs)
    [rep, names] = __folder_cache__ ('package_texi2cache', dirs{ii}, ...
                                     options, listed, pkgname, auto, ...
                                     changed, check);
    cached = [cached, names];
    if (rep.changed)
      status += 1;
    endif
    if (ii == 1 && ! isempty (seed))
      rep.findings = [seed, rep.findings];
    endif
    report(end+1) = rep;
  endfor

  ## An INDEX entry answering to no file, which only this scope can tell
  if (! isempty (listed) && ! strcmp (options.IndexOrphanEntry, 'off'))
    orphans = setdiff (listed, cached);
    for ii = 1:numel (orphans)
      msg = sprintf ("INDEX lists '%s', which answers to no file", ...
                     orphans{ii});
      f = struct ('rule', 'IndexOrphanEntry', ...
                  'severity', options.IndexOrphanEntry, 'line', 1, ...
                  'message', msg, 'file', options.IndexLocation);
      if (isempty (report))
        report = struct ('cache', options.IndexLocation, 'added', {{}}, ...
                         'updated', {{}}, 'removed', {{}}, 'changed', ...
                         false, 'findings', f);
      else
        report(1).findings(end+1) = f;
      endif
    endfor
  endif

  if (nargout == 0)
    for ii = 1:numel (report)
      __show_report__ (report(ii), options);
    endfor
    if (status == 1)
      printf ('1 cache file changed.\n');
    else
      printf ('%d cache files changed.\n', status);
    endif
    clear status;
  endif

endfunction

## Every directory below a package root that can hold a cache of its own, so
## the ones the load path reaches and none of the ones it does not.  A
## @file{src} directory is one of them: its compiled files are installed into
## an architecture directory of their own, which the load path reaches, and
## the cache written beside them here is the cache that is copied there.  It
## is not walked below, since only what a build produces is installed.
function dirs = __cache_dirs__ (root)
  dirs = {};
  base = fullfile (root, 'inst');
  if (isfolder (base))
    dirs = __walk__ ({base}, base);
  endif
  src = fullfile (root, 'src');
  if (isfolder (src))
    dirs{end+1} = src;
  endif
endfunction

function dirs = __walk__ (dirs, here)
  d = dir (here);
  for ii = 1:numel (d)
    nm = d(ii).name;
    if (! d(ii).isdir || strcmp (nm, '.') || strcmp (nm, '..'))
      continue;
    endif
    if (nm(1) == '+' || nm(1) == '@' ...
        || any (strcmp (nm, {'private', 'tests', 'demos', 'datasets'})))
      continue;
    endif
    sub = fullfile (here, nm);
    dirs{end+1} = sub;
    dirs = __walk__ (dirs, sub);
  endfor
endfunction

## The cases build a small package in a temporary place and cd to its root.
## Each writes what it needs rather than sharing a helper, the function issuing
## clear functions and that removing a %!function block for good.  The last
## block removes the fixture.

%!test  # a package is cached, one file per directory
%! d = fullfile (tempdir (), 'pkg_octave_doc_pk_bist');
%! if (isfolder (d))
%!   confirm_recursive_rmdir (false, 'local');
%!   rmdir (d, 's');
%! endif
%! mkdir (d);
%! mkdir (fullfile (d, 'inst'));
%! mkdir (fullfile (d, 'inst', 'Sub'));
%! mkdir (fullfile (d, 'inst', '+ns'));
%! fid = fopen (fullfile (d, 'DESCRIPTION'), 'w');
%! fputs (fid, "Name: bistpkg\nVersion: 1.0.0\n");
%! fclose (fid);
%! spec = {fullfile(d, 'inst', 'bisttop.m'), 'bisttop'; ...
%!         fullfile(d, 'inst', 'Sub', 'bistsub.m'), 'bistsub'; ...
%!         fullfile(d, 'inst', '+ns', 'bistpkgns.m'), 'bistpkgns'};
%! for ii = 1:rows (spec)
%!   fid = fopen (spec{ii,1}, 'w');
%!   fprintf (fid, '## -*- texinfo -*-\n');
%!   fprintf (fid, '## @deftypefn {bistpkg} {} %s ()\n##\n', spec{ii,2});
%!   fprintf (fid, '## A function written for the package tests.\n##\n');
%!   fprintf (fid, '## A body line that is distinctive enough to look for.\n');
%!   fprintf (fid, '##\n## @end deftypefn\n');
%!   fprintf (fid, 'function %s ()\nendfunction\n', spec{ii,2});
%!   fclose (fid);
%! endfor
%! fid = fopen (fullfile (d, 'INDEX'), 'w');
%! fputs (fid, "bistpkg >> Bist Package\nDocumentation\n bisttop\n bistsub\n");
%! fputs (fid, " ns.bistpkgns\n bistghost\n");
%! fclose (fid);
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   [st, rep] = package_texi2cache ();
%!   assert (st, 2);
%!   assert (numel (rep), 2);
%!   s = load (fullfile (d, 'inst', 'doc-cache'));
%!   assert (any (strcmp (s.cache(1,:), 'bisttop')));
%!   assert (any (strcmp (s.cache(1,:), 'ns.bistpkgns')));
%!   s = load (fullfile (d, 'inst', 'Sub', 'doc-cache'));
%!   assert (s.cache{1,1}, 'bistsub');
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # a current tree reports nothing to do
%! d = fullfile (tempdir (), 'pkg_octave_doc_pk_bist');
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   st = package_texi2cache ('-check');
%!   assert (st, 0);
%!   st = package_texi2cache ();
%!   assert (st, 0);
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # only this scope reports an INDEX entry answering to no file
%! d = fullfile (tempdir (), 'pkg_octave_doc_pk_bist');
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   [~, rep] = package_texi2cache ('-check');
%!   rules = {};
%!   for ii = 1:numel (rep)
%!     rules = [rules, {rep(ii).findings.rule}];
%!   endfor
%!   assert (any (strcmp (rules, 'IndexOrphanEntry')));
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # the settings of the package being documented are the ones applied
%! d = fullfile (tempdir (), 'pkg_octave_doc_pk_bist');
%! fid = fopen (fullfile (d, 'doc-options.json'), 'w');
%! fputs (fid, '{"BodyColumns": 20}');
%! fclose (fid);
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   [~, rep] = package_texi2cache ('-check');
%!   rules = {};
%!   for ii = 1:numel (rep)
%!     rules = [rules, {rep(ii).findings.rule}];
%!   endfor
%!   assert (any (strcmp (rules, 'BodyColumns')));
%!   delete (fullfile (d, 'doc-options.json'));
%!   [~, rep] = package_texi2cache ('-check');
%!   rules = {};
%!   for ii = 1:numel (rep)
%!     rules = [rules, {rep(ii).findings.rule}];
%!   endfor
%!   assert (! any (strcmp (rules, 'BodyColumns')));
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # turning the rule off stops the filtering, not just the message
%! d = fullfile (tempdir (), 'pkg_octave_doc_pk_bist');
%! fid = fopen (fullfile (d, 'inst', 'bistloose.m'), 'w');
%! fprintf (fid, '## -*- texinfo -*-\n');
%! fprintf (fid, '## @deftypefn {bistpkg} {} bistloose ()\n##\n');
%! fprintf (fid, '## A function INDEX does not list.\n##\n');
%! fprintf (fid, '## A body line that is distinctive enough to look for.\n');
%! fprintf (fid, '##\n## @end deftypefn\n');
%! fprintf (fid, 'function bistloose ()\nendfunction\n');
%! fclose (fid);
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   [~, rep] = package_texi2cache ('-check');
%!   assert (any (strcmp ({rep(1).findings.rule}, 'IndexMissingEntry')));
%!   assert (! any (strcmp (rep(1).added, 'bistloose')));
%!   o = pkg_doc_options ();
%!   o.IndexMissingEntry = 'off';
%!   [~, rep] = package_texi2cache ('-check', o);
%!   assert (! any (strcmp ({rep(1).findings.rule}, 'IndexMissingEntry')));
%!   assert (any (strcmp (rep(1).added, 'bistloose')));
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # an INDEX named but answering to nothing is reported, not passed over
%! d = fullfile (tempdir (), 'pkg_octave_doc_pk_bist');
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   o = pkg_doc_options ();
%!   o.IndexLocation = fullfile (d, 'no_such_INDEX');
%!   [~, rep] = package_texi2cache ('-check', o);
%!   assert (any (strcmp ({rep(1).findings.rule}, 'IndexNotFound')));
%!   assert (any (strcmp (rep(1).added, 'bistloose')));
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # asking for no INDEX is a decision, so it is honoured and silent
%! d = fullfile (tempdir (), 'pkg_octave_doc_pk_bist');
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   o = pkg_doc_options ();
%!   o.IndexLocation = '';
%!   [~, rep] = package_texi2cache ('-check', o);
%!   assert (! any (strcmp ({rep(1).findings.rule}, 'IndexMissingEntry')));
%!   assert (! any (strcmp ({rep(1).findings.rule}, 'IndexNotFound')));
%!   assert (any (strcmp (rep(1).added, 'bistloose')));
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # remove the fixture package
%! d = fullfile (tempdir (), 'pkg_octave_doc_pk_bist');
%! confirm_recursive_rmdir (false, 'local');
%! rmdir (d, 's');
%! assert (! isfolder (d));

## Test input validation
%!error<package_texi2cache: arguments are '-auto', '-check', and a pkg_doc_options object.> ...
%! package_texi2cache ('-nosuchflag')
## The root check is exercised from a temporary directory, never from the
## current one: the suite runs inside this package, which is a package root,
## so calling it here would build caches into the working tree.
%!test
%! d = fullfile (tempdir (), 'pkg_octave_doc_pk_noroot');
%! if (! isfolder (d))
%!   mkdir (d);
%! endif
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   fail ('package_texi2cache ()', 'this is not a package root');
%! unwind_protect_cleanup
%!   cd (old);
%!   rmdir (d);
%! end_unwind_protect
