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
## @deftypefn {pkg-octave-doc} {[@var{report}, @var{names}] =} __folder_cache__ (@var{caller}, @var{dirpath}, @var{opts}, @var{listed}, @var{pkgname}, @var{auto}, @var{changed}, @var{check})
##
## Private function rebuilding the doc-cache of one directory.
##
## This is the work @code{folder_texi2cache} does, and the work
## @code{package_texi2cache} does once per directory below a package root, so
## it is written once.  @var{dirpath} is entered while the cache is built and
## left again whatever happens, since a name resolves through the directory
## the interpreter is standing in.
##
## @var{listed} is every name @file{INDEX} carries, empty when none is in
## play, and decides what is cached: a name found here but absent from it is
## skipped and reported.  @var{auto} narrows the work to the files
## @var{changed} names, which may be none of them.  @var{check} writes nothing
## and only answers what would change.
##
## @var{names} is what this directory contributed to its cache, which a
## package rebuild collects to cross-reference against @file{INDEX} in the
## other direction.
##
## @end deftypefn

function [report, names] = __folder_cache__ (caller, dirpath, opts, listed, ...
                                             pkgname, auto, changed, check)

  ## Input validation
  if (nargin != 8)
    error ("__folder_cache__: invalid number of input arguments.");
  endif

  cachefile = fullfile (dirpath, 'doc-cache');
  report = struct ('cache', cachefile, 'added', {{}}, 'updated', {{}}, ...
                   'removed', {{}}, 'changed', false, 'findings', ...
                   struct ('rule', {}, 'severity', {}, 'line', {}, ...
                           'message', {}, 'file', {}));
  names = {};

  here = pwd ();
  unwind_protect
    cd (dirpath);
    items = __names_here__ (dirpath);

    touched = {};
    if (auto)
      keep = false (1, numel (items));
      for ii = 1:numel (items)
        keep(ii) = any (strcmp (changed, fullfile (dirpath, items(ii).file)));
        if (keep(ii))
          touched{end+1} = items(ii).name;
        endif
      endfor
      for ii = 1:numel (changed)
        nm = __name_for__ (dirpath, changed{ii});
        if (! isempty (nm) && ! any (strcmp (touched, nm)))
          touched{end+1} = nm;
        endif
      endfor
      items = items(keep);
    endif

    entries = cell (3, 0);
    findings = report.findings;
    for ii = 1:numel (items)
      name = items(ii).name;

      ## INDEX decides what a whole scope caches
      if (! isempty (listed) && ! any (strcmp (name, listed)))
        if (! strcmp (opts.IndexMissingEntry, 'off'))
          msg = sprintf ("'%s' is absent from INDEX and is not cached", name);
          findings(end+1) = struct ('rule', 'IndexMissingEntry', ...
                                    'severity', opts.IndexMissingEntry, ...
                                    'line', 1, 'message', msg, ...
                                    'file', items(ii).file);
        endif
        continue;
      endif

      if (items(ii).isclass)
        [rows, found] = __class_entries__ (caller, name, items(ii).file, ...
                                           opts, pkgname);
      else
        [rows, found] = __function_entry__ (caller, name, items(ii).file, ...
                                            opts, pkgname);
      endif
      if (! isempty (found))
        findings = [findings, found];
      endif
      if (! isempty (rows))
        entries = [entries, rows];
        names{end+1} = name;
      endif
    endfor
    report.findings = findings;

    ## A whole rebuild replaces the file; a narrowed one leaves the rest alone
    [cache, header] = __cache_read__ (cachefile);
    was = cache;
    before = {};
    if (! isempty (cache))
      before = cache(1,:);
    endif
    if (auto)
      keep = true (1, columns (cache));
      for ii = 1:columns (cache)
        keep(ii) = ! __owned_by__ (cache{1,ii}, touched);
      endfor
      cache = [cache(:,keep), entries];
    else
      cache = entries;
    endif

    after = {};
    if (! isempty (cache))
      after = cache(1,:);
    endif
    report.added = setdiff (after, before);
    report.removed = setdiff (before, after);

    ## An entry that stayed is updated only if its text moved on
    kept = intersect (after, before);
    updated = {};
    for ii = 1:numel (kept)
      old = was(:, strcmp (before, kept{ii}));
      new = cache(:, strcmp (after, kept{ii}));
      if (! isequal (old, new))
        updated{end+1} = kept{ii};
      endif
    endfor
    report.updated = updated;
    report.changed = __cache_write__ (cachefile, cache, header, check);

  unwind_protect_cleanup
    cd (here);
  end_unwind_protect

endfunction

## Whether a cache entry belongs to one of the names given, a class owning
## every entry whose name it prefixes
function tf = __owned_by__ (entry, names)
  tf = false;
  for ii = 1:numel (names)
    if (strcmp (entry, names{ii}) ...
        || strncmp (entry, [names{ii} '.'], numel (names{ii}) + 1))
      tf = true;
      return;
    endif
  endfor
endfunction

## The name this directory would give a file, whether it still exists or not,
## which is what lets a deleted file take its entries with it
function name = __name_for__ (here, path)
  name = '';
  if (! strncmp (path, [here filesep], numel (here) + 1))
    return;
  endif
  rel = path(numel (here) + 2:end);
  [sub, base, ext] = fileparts (rel);
  if (! any (strcmp (ext, {'.m', '.oct', '.mex'})))
    return;
  endif
  if (isempty (sub))
    name = base;
    return;
  endif
  parts = strsplit (strrep (sub, '\\', '/'), '/');
  if (parts{1}(1) == '@')
    if (numel (parts) == 1)
      name = [parts{1} '/' base];
    endif
    return;
  endif
  for ii = 1:numel (parts)
    if (parts{ii}(1) != '+')
      return;
    endif
    parts{ii} = parts{ii}(2:end);
  endfor
  name = [strjoin(parts, '.') '.' base];
endfunction

## Every name this directory contributes to its own cache, the contents of a
## +pkg or @class directory below it included
function items = __names_here__ (here)
  items = struct ('name', {}, 'file', {}, 'isclass', {});
  items = __collect__ (items, here, '', '');
endfunction

function items = __collect__ (items, root, sub, prefix)
  d = dir (fullfile (root, sub, '*'));
  for ii = 1:numel (d)
    nm = d(ii).name;
    if (strcmp (nm, '.') || strcmp (nm, '..'))
      continue;
    endif
    rel = fullfile (sub, nm);
    if (d(ii).isdir)
      if (nm(1) == '+')
        items = __collect__ (items, root, rel, [prefix nm(2:end) '.']);
      elseif (nm(1) == '@')
        items = __collect__ (items, root, rel, [nm '/']);
      endif
      continue;
    endif
    [~, base, ext] = fileparts (nm);
    if (! any (strcmp (ext, {'.m', '.oct', '.mex'})))
      continue;
    endif
    isclass = false;
    if (strcmp (ext, '.m'))
      txt = fileread (fullfile (root, rel));
      isclass = ! isempty (regexp (txt, '(?m)^\s*classdef($|[ \t<])', 'once'));
    endif
    items(end+1) = struct ('name', [prefix base], 'file', rel, ...
                           'isclass', isclass);
  endfor
endfunction
