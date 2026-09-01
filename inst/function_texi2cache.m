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
## @deftypefn  {pkg-octave-doc} {} function_texi2cache (@var{fcnname})
## @deftypefnx {pkg-octave-doc} {} function_texi2cache (@var{fcnname}, @var{options})
## @deftypefnx {pkg-octave-doc} {@var{report} =} function_texi2cache (@dots{})
##
## Write one function's entry into this directory's doc-cache.
##
## @var{fcnname} is a function, whether an m-file or a compiled one, a function
## inside a package as @qcode{'pkg.fcnname'}, or a method of an old-style class
## as @qcode{'@@cls/method'}, each spelled the way @code{help} takes it.  Its
## entry is written into the @file{doc-cache} of the @strong{current
## directory}, leaving every other entry in that file alone.  The file must
## live here, or in a @file{+pkg} or @file{@@class} directory below, neither of
## which can hold a cache of its own.
##
## A name that no longer resolves is treated as removed and its entry dropped,
## which is how a deleted or renamed function is cleared out of the cache it
## still sits in.
##
## A compiled function is read from its @file{.oct}, which must exist and be
## newer than its @file{.cc}, since that is the only place a @code{DEFUN_DLD}
## docstring lives.
##
## For a class, use @code{classdef_texi2cache}, which writes the class and all
## of its members together.
##
## @var{options} is a @code{pkg_doc_options} object.  Its @code{Index} property
## never decides what is written here: the function named is always cached, and
## an @file{INDEX} given only adds a warning when the function is not listed in
## it.
##
## The help text is read from the file rather than from the session:
## @code{clear functions} is issued first, and what the interpreter then
## answers must carry a distinctive run of the docstring in the file, so that
## neither a definition held from earlier nor a copy installed elsewhere can be
## cached unnoticed.
##
## @var{report} is a struct with the fields @qcode{'cache'}, @qcode{'added'},
## @qcode{'updated'}, @qcode{'removed'}, @qcode{'changed'} and
## @qcode{'findings'}.  With no output requested the same information is
## printed.
##
## @seealso{package_texi2cache, folder_texi2cache, classdef_texi2cache,
## function_texi2html, pkg_doc_options}
## @end deftypefn

function report = function_texi2cache (fcnname, options)

  ## Input validation
  if (nargin < 1 || nargin > 2)
    error ("function_texi2cache: invalid number of input arguments.");
  endif
  if (! (ischar (fcnname) && isrow (fcnname)))
    error ("function_texi2cache: FCNNAME must be a character vector.");
  endif
  if (nargin < 2)
    options = pkg_doc_options ();
  elseif (! isa (options, 'pkg_doc_options'))
    error (strcat ("function_texi2cache: OPTIONS must be a", ...
                   " pkg_doc_options object."));
  endif

  cachefile = fullfile (pwd (), 'doc-cache');
  report = struct ('cache', cachefile, 'added', {{}}, 'updated', {{}}, ...
                   'removed', {{}}, 'changed', false, 'findings', ...
                   struct ('rule', {}, 'severity', {}, 'line', {}, ...
                           'message', {}, 'file', {}));

  ## Locate the file the name belongs to, which must be in this directory
  srcfile = __locate_name__ (fcnname);

  [cache, header] = __cache_read__ (cachefile);
  known = {};
  if (! isempty (cache))
    known = cache(1,:);
  endif
  at = find (strcmp (known, fcnname), 1);

  ## A name that resolves to nothing is a removal
  if (isempty (srcfile))
    if (isempty (at))
      error ("function_texi2cache: '%s' is not in this directory.", fcnname);
    endif
    cache(:,at) = [];
    report.removed = {fcnname};
    report.changed = __cache_write__ (cachefile, cache, header, false);
    if (nargout == 0)
      __show_report__ (report, options);
      clear report;
    endif
    return;
  endif

  ## Read the help from the file rather than from the session
  clear functions;
  text = get_help_text (fcnname);
  srclines = __help_block__ (srcfile);
  __verify_help__ ('function_texi2cache', fcnname, srcfile, text, srclines);

  ## Build the entry, collecting what the renderer finds while it converts
  [rows, findings] = __cache_rows__ (fcnname, text, options);
  [listed, pkgname] = __index_info__ (options);
  ctx = struct ('package', pkgname, 'class', '', 'member', '');
  findings = [findings, __source_lint__(srclines, options, ctx)];
  for ii = 1:numel (findings)
    findings(ii).file = srcfile;
  endfor

  ## An INDEX given never gates what is written here, it only reports
  if (! isempty (listed) && ! any (strcmp (fcnname, listed)) ...
      && ! strcmp (options.IndexMissingEntry, 'off'))
    f = struct ('rule', 'IndexMissingEntry', ...
                'severity', options.IndexMissingEntry, 'line', 1, ...
                'message', sprintf ("'%s' is absent from INDEX", fcnname), ...
                'file', srcfile);
    findings(end+1) = f;
  endif
  report.findings = findings;

  ## Place the entry and write the file
  if (isempty (at))
    cache(:,end+1) = rows;
    report.added = {fcnname};
  else
    if (! isequal (cache(:,at), rows))
      report.updated = {fcnname};
    endif
    cache(:,at) = rows;
  endif
  report.changed = __cache_write__ (cachefile, cache, header, false);

  if (nargout == 0)
    __show_report__ (report, options);
    clear report;
  endif

endfunction

## Find the file a name belongs to, refusing one that lives somewhere else
function srcfile = __locate_name__ (name)
  srcfile = '';
  if (! isempty (strfind (name, '/')) || ! isempty (strfind (name, '\')))
    parts = strsplit (strrep (name, '\', '/'), '/');
    if (numel (parts) != 2 || parts{1}(1) != '@')
      error (strcat ("function_texi2cache: '%s' is not a name", ...
                     " help accepts."), name);
    endif
    stem = fullfile (parts{1}, parts{2});
  elseif (! isempty (strfind (name, '.')))
    parts = strsplit (name, '.');
    stem = fullfile (['+' strjoin(parts(1:end-1), [filesep '+'])], parts{end});
  else
    stem = name;
  endif
  for ext = {'.m', '.oct', '.mex'}
    candidate = [stem ext{1}];
    if (exist (fullfile (pwd (), candidate), 'file'))
      srcfile = candidate;
      break;
    endif
  endfor
  if (! isempty (srcfile) && strcmp (srcfile(end-3:end), '.oct'))
    cc = [srcfile(1:end-4) '.cc'];
    if (exist (cc, 'file'))
      a = dir (srcfile);
      b = dir (cc);
      if (a.datenum < b.datenum)
        error (strcat ("function_texi2cache: '%s' is older than its", ...
                       " source, build the package first."), srcfile);
      endif
    endif
  endif
endfunction

## The leading texinfo comment block of an m-file, as it appears in the file
function srclines = __help_block__ (srcfile)
  srclines = {};
  if (numel (srcfile) < 2 || ! strcmp (srcfile(end-1:end), '.m'))
    return;                              # a compiled docstring has no source
  endif
  lines = strsplit (strrep (fileread (srcfile), "\r\n", "\n"), "\n", ...
                    'CollapseDelimiters', false);
  at = 0;
  for ii = 1:numel (lines)
    marker = regexp (strtrim (lines{ii}), '^##\s*-\*-\s*texinfo', 'once');
    if (! isempty (marker))
      at = ii;
      break;
    endif
  endfor
  if (at == 0)
    return;
  endif
  for ii = at+1:numel (lines)
    if (isempty (regexp (lines{ii}, '^\s*##', 'once')))
      break;
    endif
    srclines{end+1} = lines{ii};
  endfor
endfunction





## The cases write a fixture into a temporary directory and cd into it, since
## the function writes the cache of the directory it stands in and the current
## one is the package tree while the suite runs.  Each case writes its own
## fixture rather than sharing a helper, because the function issues
## clear functions and that removes a %!function block for good, where a file
## on disk is simply read again.  The last block removes the fixture.

%!test  # an entry is written, with its three rows
%! d = fullfile (tempdir (), 'pkg_octave_doc_fc_bist');
%! if (! isfolder (d))
%!   mkdir (d);
%! endif
%! ## a run that failed earlier can leave the fixture behind, so clear it
%! stale = [dir(fullfile (d, '*.m')); dir(fullfile (d, 'doc-cache')); ...
%!          dir(fullfile (d, 'INDEX'))];
%! for ii = 1:numel (stale)
%!   delete (fullfile (d, stale(ii).name));
%! endfor
%! fid = fopen (fullfile (d, 'bistfcn.m'), 'w');
%! fprintf (fid, '## -*- texinfo -*-\n## @deftypefn {bistpkg} {} bistfcn ()\n');
%! fprintf (fid, '##\n## Do a thing to a number.\n##\n');
%! fprintf (fid, '## A body line that is distinctive enough to look for.\n');
%! fprintf (fid, '##\n## @end deftypefn\nfunction bistfcn ()\nendfunction\n');
%! fclose (fid);
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   r = function_texi2cache ('bistfcn');
%!   assert (r.added, {'bistfcn'});
%!   assert (r.changed, true);
%!   s = load ('doc-cache');
%!   assert (columns (s.cache), 1);
%!   assert (s.cache{1,1}, 'bistfcn');
%!   assert (s.cache{3,1}, 'Do a thing to a number.');
%!   assert (! isempty (strfind (s.cache{2,1}, 'distinctive enough')));
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # the header names the running Octave, and a second run changes nothing
%! d = fullfile (tempdir (), 'pkg_octave_doc_fc_bist');
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   r = function_texi2cache ('bistfcn');
%!   assert (r.changed, false);
%!   assert (isempty (r.added));
%!   fid = fopen ('doc-cache');
%!   line = fgetl (fid);
%!   fclose (fid);
%!   assert (line, sprintf ('# doc-cache created by Octave %s', version ()));
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # a docstring edited in this session is the one that is cached
%! d = fullfile (tempdir (), 'pkg_octave_doc_fc_bist');
%! fid = fopen (fullfile (d, 'bistfcn.m'), 'w');
%! fprintf (fid, '## -*- texinfo -*-\n## @deftypefn {bistpkg} {} bistfcn ()\n');
%! fprintf (fid, '##\n## A sentence written later on.\n##\n');
%! fprintf (fid, '## A body line that is distinctive enough to look for.\n');
%! fprintf (fid, '##\n## @end deftypefn\nfunction bistfcn ()\nendfunction\n');
%! fclose (fid);
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   r = function_texi2cache ('bistfcn');
%!   assert (r.updated, {'bistfcn'});
%!   s = load ('doc-cache');
%!   assert (s.cache{3,1}, 'A sentence written later on.');
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # INDEX never gates a named function, it only reports
%! d = fullfile (tempdir (), 'pkg_octave_doc_fc_bist');
%! fid = fopen (fullfile (d, 'INDEX'), 'w');
%! fputs (fid, "bistpkg >> Bist Package\nDocumentation\n bistfcn\n");
%! fclose (fid);
%! fid = fopen (fullfile (d, 'bistother.m'), 'w');
%! fprintf (fid, '## -*- texinfo -*-\n## @deftypefn {bistpkg} {} bistother ()\n');
%! fprintf (fid, '##\n## A function INDEX does not list.\n##\n');
%! fprintf (fid, '## A body line that is distinctive enough to look for.\n');
%! fprintf (fid, '##\n## @end deftypefn\nfunction bistother ()\nendfunction\n');
%! fclose (fid);
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   o = pkg_doc_options ();
%!   o.Index = fullfile (d, 'INDEX');
%!   r = function_texi2cache ('bistother', o);
%!   assert (r.added, {'bistother'});
%!   assert (numel (r.findings), 1);
%!   assert (r.findings(1).rule, 'IndexMissingEntry');
%!   r = function_texi2cache ('bistfcn', o);
%!   assert (isempty (r.findings));
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # a name that resolves to nothing drops its entry
%! d = fullfile (tempdir (), 'pkg_octave_doc_fc_bist');
%! delete (fullfile (d, 'bistother.m'));
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   r = function_texi2cache ('bistother');
%!   assert (r.removed, {'bistother'});
%!   assert (r.changed, true);
%!   s = load ('doc-cache');
%!   assert (columns (s.cache), 1);
%!   assert (s.cache{1,1}, 'bistfcn');
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # a structural defect is reported and does not stop the run
%! d = fullfile (tempdir (), 'pkg_octave_doc_fc_bist');
%! fid = fopen (fullfile (d, 'bistbad.m'), 'w');
%! fprintf (fid, '## -*- texinfo -*-\n## @deftypefn {bistpkg} {} bistbad ()\n');
%! fprintf (fid, '##\n## A function whose docstring is broken here.\n##\n');
%! fprintf (fid, '## @itemize\n## @item one\n');
%! fprintf (fid, '## @end itemize and text that should not be here\n');
%! fprintf (fid, '##\n## @end deftypefn\nfunction bistbad ()\nendfunction\n');
%! fclose (fid);
%! old = pwd ();
%! addpath (d);
%! unwind_protect
%!   cd (d);
%!   r = function_texi2cache ('bistbad');
%!   assert (r.added, {'bistbad'});
%!   assert (any (strcmp ({r.findings.rule}, 'EndTrailingText')));
%! unwind_protect_cleanup
%!   cd (old);
%!   rmpath (d);
%! end_unwind_protect

%!test  # remove the fixture directory
%! d = fullfile (tempdir (), 'pkg_octave_doc_fc_bist');
%! leftover = [dir(fullfile (d, '*.m')); dir(fullfile (d, 'doc-cache')); ...
%!             dir(fullfile (d, 'INDEX'))];
%! for ii = 1:numel (leftover)
%!   delete (fullfile (d, leftover(ii).name));
%! endfor
%! rmdir (d);
%! assert (! isfolder (d));

## Test input validation
%!error<function_texi2cache: invalid number of input arguments.> ...
%! function_texi2cache ()
%!error<function_texi2cache: FCNNAME must be a character vector.> ...
%! function_texi2cache (5)
%!error<function_texi2cache: OPTIONS must be a pkg_doc_options object.> ...
%! function_texi2cache ('nosuchname', struct ())
%!error<function_texi2cache: 'nosuchname_at_all' is not in this directory.> ...
%! function_texi2cache ('nosuchname_at_all')
