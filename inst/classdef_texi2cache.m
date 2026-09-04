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
## @deftypefn  {pkg-octave-doc} {} classdef_texi2cache (@var{clsname})
## @deftypefnx {pkg-octave-doc} {} classdef_texi2cache (@var{clsname}, @var{options})
## @deftypefnx {pkg-octave-doc} {@var{report} =} classdef_texi2cache (@dots{})
##
## Write a class and its documented members into this directory's doc-cache.
##
## @var{clsname} is a class, qualified by its package when it lives in one, as
## in @qcode{'prob.NormalDistribution'}.  Its own entry and one per member are
## written into the @file{doc-cache} of the @strong{current directory}, and the
## entries the class no longer has are dropped, so a method renamed inside a
## class needs only the class named once.
##
## The class file must live in the current directory, or in a @file{+pkg}
## directory below it.  A @file{+pkg} directory is never itself the place to
## stand: a cache inside one can be read by nothing, so a namespaced class is
## written from the directory holding the @file{+pkg}.
##
## The members are the ones the class documents: its public constructor, the
## methods declared in the class's own file, and the properties reported by
## @code{properties}, inherited ones included.  This is what
## @code{classdef_texi2html} publishes, so a class reads the same way online
## and in @code{lookfor}, and it is not an arbitrary choice: @code{help}
## resolves an inherited property on a subclass but not an inherited method, so
## these are exactly the members a cache entry can be built for.  Members of a
## @code{Hidden} or private block are left out, as are those carrying no
## texinfo help, each of the latter reported under @code{MissingDocstring} as
## it is skipped.
##
## @var{options} is a @code{pkg_doc_options} object.  Its
## @code{IndexLocation} property never decides what is written here: the class
## named is always cached, and an @file{INDEX} given only adds a warning when
## the class is not listed in it.
##
## An inherited property is cached, its help text belonging to the superclass
## that declares it, but only the rules a renderer can apply are run on it: the
## rules that measure a file are left to the run that covers the file it is
## written in.
##
## @var{report} is a struct with the fields @qcode{'cache'}, @qcode{'added'},
## @qcode{'updated'}, @qcode{'removed'}, @qcode{'changed'} and
## @qcode{'findings'}.  With no output requested the same information is
## printed.
##
## @seealso{package_texi2cache, folder_texi2cache, function_texi2cache,
## classdef_texi2html, pkg_doc_options}
## @end deftypefn

function report = classdef_texi2cache (clsname, options)

  ## Input validation
  if (nargin < 1 || nargin > 2)
    error ("classdef_texi2cache: invalid number of input arguments.");
  endif
  if (! (ischar (clsname) && isrow (clsname)))
    error ("classdef_texi2cache: CLSNAME must be a character vector.");
  endif
  if (nargin < 2)
    options = pkg_doc_options ();
  elseif (! isa (options, 'pkg_doc_options'))
    error (strcat ("classdef_texi2cache: OPTIONS must be a", ...
                   " pkg_doc_options object."));
  endif

  cachefile = fullfile (pwd (), 'doc-cache');
  report = struct ('cache', cachefile, 'added', {{}}, 'updated', {{}}, ...
                   'removed', {{}}, 'changed', false, 'findings', ...
                   struct ('rule', {}, 'severity', {}, 'line', {}, ...
                           'message', {}, 'file', {}));

  ## The class file must be here, or in a +pkg directory below
  parts = strsplit (clsname, '.');
  if (numel (parts) == 1)
    srcfile = [clsname '.m'];
  else
    srcfile = fullfile (['+' strjoin(parts(1:end-1), [filesep '+'])], ...
                        [parts{end} '.m']);
  endif
  if (! exist (fullfile (pwd (), srcfile), 'file'))
    error ("classdef_texi2cache: '%s' is not in this directory.", clsname);
  endif

  ## Read the definitions from the tree rather than from the session
  clear functions;
  [listed, pkgname, why] = __index_info__ (options);
  [entries, findings] = __class_entries__ ('classdef_texi2cache', clsname, ...
                                           srcfile, options, pkgname);

  ## An INDEX given never gates what is written here, it only reports
  if (! isempty (listed) && ! any (strcmp (clsname, listed)) ...
      && ! strcmp (options.IndexMissingEntry, 'off'))
    f = struct ('rule', 'IndexMissingEntry', ...
                'severity', options.IndexMissingEntry, 'line', 1, ...
                'message', sprintf ("'%s' is absent from INDEX", clsname), ...
                'file', srcfile);
    findings(end+1) = f;
  endif
  findings = [__index_notfound__(options, why), findings];
  report.findings = findings;

  ## Replace every entry this class owns, so a renamed member leaves with it
  [cache, header] = __cache_read__ (cachefile);
  owned = false (1, columns (cache));
  for ii = 1:columns (cache)
    nm = cache{1,ii};
    owned(ii) = strcmp (nm, clsname) ...
                || strncmp (nm, [clsname '.'], numel (clsname) + 1);
  endfor
  ownedCache = cache(:, owned);
  before = ownedCache(1,:);
  cache(:,owned) = [];
  after = entries(1,:);
  report.added = setdiff (after, before);
  report.removed = setdiff (before, after);
  kept = intersect (after, before);
  updated = {};
  for ii = 1:numel (kept)
    was = ownedCache(:, strcmp (before, kept{ii}));
    now = entries(:, strcmp (after, kept{ii}));
    if (! isequal (was, now))
      updated{end+1} = kept{ii};
    endif
  endfor
  report.updated = updated;
  cache = [cache, entries];
  report.changed = __cache_write__ (cachefile, cache, header, false);

  if (nargout == 0)
    __show_report__ (report, options);
    clear report;
  endif

endfunction

## The cases write two fixture classes into a temporary directory and cd into
## it, a base and a class deriving from it, since inheritance is what the
## member selection turns on.  Each case writes what it needs rather than
## sharing a helper, the function issuing clear functions and that removing a
## %!function block for good.  The last block removes the fixture.

%!test  # a class and every member it documents are cached
%! d = fullfile (tempdir (), 'pkg_octave_doc_cc_bist');
%! if (! isfolder (d))
%!   mkdir (d);
%! endif
%! stale = [dir(fullfile (d, '*.m')); dir(fullfile (d, 'doc-cache')); ...
%!          dir(fullfile (d, 'INDEX'))];
%! for ii = 1:numel (stale)
%!   delete (fullfile (d, stale(ii).name));
%! endfor
%! fid = fopen (fullfile (d, 'BistCacheBase.m'), 'w');
%! fprintf (fid, 'classdef BistCacheBase\n');
%! fprintf (fid, '  ## -*- texinfo -*-\n');
%! fprintf (fid, '  ## @deftp {bistpkg} BistCacheBase\n  ##\n');
%! fprintf (fid, '  ## A base class written for the tests here.\n  ##\n');
%! fprintf (fid, '  ## @end deftp\n  properties\n');
%! fprintf (fid, '    ## -*- texinfo -*-\n');
%! fprintf (fid, '    ## @deftp {BistCacheBase} {property} Inherited\n');
%! fprintf (fid, '    ##\n');
%! fprintf (fid, '    ## A property the derived class inherits from here.\n');
%! fprintf (fid, '    ##\n    ## @end deftp\n    Inherited = 1\n');
%! fprintf (fid, '  endproperties\n  methods (Access = public)\n');
%! fprintf (fid, '    ## -*- texinfo -*-\n');
%! fprintf (fid, '    ## @deftypefn {BistCacheBase} {} inheritedMethod (@var{obj})\n    ##\n');
%! fprintf (fid, '    ## A method the derived class inherits from here.\n');
%! fprintf (fid, '    ##\n    ## @end deftypefn\n');
%! fprintf (fid, '    function inheritedMethod (this)\n    endfunction\n');
%! fprintf (fid, '  endmethods\nendclassdef\n');
%! fclose (fid);
%! fid = fopen (fullfile (d, 'BistCacheSub.m'), 'w');
%! fprintf (fid, 'classdef BistCacheSub < BistCacheBase\n');
%! fprintf (fid, '  ## -*- texinfo -*-\n');
%! fprintf (fid, '  ## @deftp {bistpkg} BistCacheSub\n  ##\n');
%! fprintf (fid, '  ## A class deriving from the base class here.\n  ##\n');
%! fprintf (fid, '  ## @end deftp\n  properties\n');
%! fprintf (fid, '    ## -*- texinfo -*-\n');
%! fprintf (fid, '    ## @deftp {BistCacheSub} {property} Own\n    ##\n');
%! fprintf (fid, '    ## A property this class declares for itself.\n');
%! fprintf (fid, '    ##\n    ## @end deftp\n    Own = 2\n');
%! fprintf (fid, '  endproperties\n  methods (Access = public)\n');
%! fprintf (fid, '    ## -*- texinfo -*-\n');
%! fprintf (fid, '    ## @deftypefn {BistCacheSub} {} ownMethod (@var{obj})\n    ##\n');
%! fprintf (fid, '    ## A method this class declares for itself.\n');
%! fprintf (fid, '    ##\n    ## @end deftypefn\n');
%! fprintf (fid, '    function ownMethod (this)\n    endfunction\n');
%! fprintf (fid, '  endmethods\nendclassdef\n');
%! fclose (fid);
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   r = classdef_texi2cache ('BistCacheSub');
%!   s = load ('doc-cache');
%!   names = s.cache(1,:);
%!   assert (any (strcmp (names, 'BistCacheSub')));
%!   assert (any (strcmp (names, 'BistCacheSub.Own')));
%!   assert (any (strcmp (names, 'BistCacheSub.ownMethod')));
%!   assert (r.changed, true);
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # an inherited property is cached and an inherited method is not
%! d = fullfile (tempdir (), 'pkg_octave_doc_cc_bist');
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   s = load ('doc-cache');
%!   names = s.cache(1,:);
%!   assert (any (strcmp (names, 'BistCacheSub.Inherited')));
%!   assert (! any (strcmp (names, 'BistCacheSub.inheritedMethod')));
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # a second run over an unchanged class changes nothing
%! d = fullfile (tempdir (), 'pkg_octave_doc_cc_bist');
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   r = classdef_texi2cache ('BistCacheSub');
%!   assert (r.changed, false);
%!   assert (isempty (r.added));
%!   assert (isempty (r.removed));
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # a class declaring no constructor is given no constructor entry
%! d = fullfile (tempdir (), 'pkg_octave_doc_cc_bist');
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   r = classdef_texi2cache ('BistCacheSub');
%!   s = load ('doc-cache');
%!   assert (! any (strcmp (s.cache(1,:), 'BistCacheSub.BistCacheSub')));
%!   rules = {};
%!   if (! isempty (r.findings))
%!     rules = {r.findings.rule};
%!   endif
%!   assert (! any (strcmp (rules, 'MissingDocstring')));
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # a class declaring a constructor is given its entry
%! d = fullfile (tempdir (), 'pkg_octave_doc_cc_bist');
%! fid = fopen (fullfile (d, 'BistCacheCtor.m'), 'w');
%! fprintf (fid, 'classdef BistCacheCtor\n');
%! fprintf (fid, '  ## -*- texinfo -*-\n');
%! fprintf (fid, '  ## @deftp {bistpkg} BistCacheCtor\n  ##\n');
%! fprintf (fid, '  ## A class declaring a constructor of its own.\n  ##\n');
%! fprintf (fid, '  ## @end deftp\n  methods (Access = public)\n');
%! fprintf (fid, '    ## -*- texinfo -*-\n');
%! fprintf (fid, '    ## @deftypefn {BistCacheCtor} ');
%! fprintf (fid, '{@var{obj} =} BistCacheCtor ()\n    ##\n');
%! fprintf (fid, '    ## Construct an object of this class.\n');
%! fprintf (fid, '    ##\n    ## @end deftypefn\n');
%! fprintf (fid, '    function this = BistCacheCtor ()\n    endfunction\n');
%! fprintf (fid, '  endmethods\nendclassdef\n');
%! fclose (fid);
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   r = classdef_texi2cache ('BistCacheCtor');
%!   s = load ('doc-cache');
%!   assert (any (strcmp (s.cache(1,:), 'BistCacheCtor.BistCacheCtor')));
%!   rules = {};
%!   if (! isempty (r.findings))
%!     rules = {r.findings.rule};
%!   endif
%!   assert (! any (strcmp (rules, 'MissingDocstring')));
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # INDEX never gates the class named, it only reports
%! d = fullfile (tempdir (), 'pkg_octave_doc_cc_bist');
%! fid = fopen (fullfile (d, 'INDEX'), 'w');
%! fputs (fid, "bistpkg >> Bist Package\nDocumentation\n BistCacheBase\n");
%! fclose (fid);
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   o = pkg_doc_options ();
%!   o.IndexLocation = fullfile (d, 'INDEX');
%!   r = classdef_texi2cache ('BistCacheSub', o);
%!   assert (any (strcmp ({r.findings.rule}, 'IndexMissingEntry')));
%!   s = load ('doc-cache');
%!   assert (any (strcmp (s.cache(1,:), 'BistCacheSub')));
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # remove the fixture directory
%! d = fullfile (tempdir (), 'pkg_octave_doc_cc_bist');
%! leftover = [dir(fullfile (d, '*.m')); dir(fullfile (d, 'doc-cache')); ...
%!             dir(fullfile (d, 'INDEX'))];
%! for ii = 1:numel (leftover)
%!   delete (fullfile (d, leftover(ii).name));
%! endfor
%! rmdir (d);
%! assert (! isfolder (d));

## Test input validation
%!error<classdef_texi2cache: invalid number of input arguments.> ...
%! classdef_texi2cache ()
%!error<classdef_texi2cache: CLSNAME must be a character vector.> ...
%! classdef_texi2cache (5)
%!error<classdef_texi2cache: OPTIONS must be a pkg_doc_options object.> ...
%! classdef_texi2cache ('nosuchclass', 5)
%!error<classdef_texi2cache: 'nosuchclass_at_all' is not in this directory.> ...
%! classdef_texi2cache ('nosuchclass_at_all')
