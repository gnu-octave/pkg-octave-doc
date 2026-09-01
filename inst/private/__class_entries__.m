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
## @deftypefn {pkg-octave-doc} {[@var{entries}, @var{findings}] =} __class_entries__ (@var{caller}, @var{clsname}, @var{srcfile}, @var{opts}, @var{pkgname})
##
## Private function building the doc-cache entries of a class.
##
## @var{entries} is a @math{3xN} cell array holding the class and one entry per
## member it documents: its constructor, the methods declared in its own file,
## and the properties @code{properties} reports, inherited ones included.  That
## is what @code{classdef_texi2html} publishes, and it is what @code{help} can
## answer for, an inherited property resolving on a subclass where an inherited
## method does not.
##
## A member of a @code{Hidden} or private block is never seen, @code{methods}
## and @code{properties} not reporting one, and a member carrying no texinfo
## help is reported rather than written.
##
## An inherited property is cached, but only the rules a renderer can apply are
## run on it: it is declared in another file, so the rules that measure a file
## are left to the run covering the file it belongs to.
##
## @end deftypefn

function [entries, findings] = __class_entries__ (caller, clsname, srcfile, ...
                                                  opts, pkgname)

  ## Input validation
  if (nargin != 5)
    error ("__class_entries__: invalid number of input arguments.");
  endif

  entries = cell (3, 0);
  findings = struct ('rule', {}, 'severity', {}, 'line', {}, 'message', {}, ...
                     'file', {});

  parts = strsplit (clsname, '.');
  stem = parts{end};
  blocks = __class_blocks__ (srcfile);

  try
    MTHDS = methods (clsname);
  catch
    error ("%s: '%s' is not a classdef.", caller, clsname);
  end_try_catch
  MTHDS(strcmp (MTHDS, stem)) = [];
  MTHDS = get_methods_ordered (clsname, MTHDS);
  PROPS = properties (clsname);
  PROPS = get_properties_ordered (clsname, PROPS);

  ## The class, its constructor, then its methods and its properties
  names = [{clsname}, {[clsname '.' stem]}];
  for ii = 1:numel (MTHDS)
    names{end+1} = [clsname '.' MTHDS{ii}];
  endfor
  for ii = 1:numel (PROPS)
    names{end+1} = [clsname '.' PROPS{ii}];
  endfor

  for ii = 1:numel (names)
    name = names{ii};
    member = '';
    if (ii > 1)
      member = name(numel (clsname) + 2:end);
    endif

    [text, format] = get_help_text (name);
    if (isempty (text) || ! strcmp (format, 'texinfo'))
      if (! strcmp (opts.MissingDocstring, 'off'))
        msg = sprintf ("'%s' carries no texinfo help", name);
        findings(end+1) = struct ('rule', 'MissingDocstring', ...
                                  'severity', opts.MissingDocstring, ...
                                  'line', 1, 'message', msg, 'file', srcfile);
      endif
      continue;
    endif

    ## The block documenting this member, which an inherited property does not
    ## have in this file because it is declared in another one
    srclines = {};
    atline = 0;
    for jj = 1:numel (blocks)
      if (strcmp (blocks(jj).member, member))
        srclines = blocks(jj).lines;
        atline = blocks(jj).line;
        break;
      endif
    endfor

    __verify_help__ (caller, name, srcfile, text, srclines);

    [rows, found] = __cache_rows__ (name, text, opts);
    if (! isempty (srclines))
      ctx = struct ('package', pkgname, 'class', stem, 'member', member);
      found = [found, __source_lint__(srclines, opts, ctx)];
    endif
    if (! isempty (found))
      for jj = 1:numel (found)
        found(jj).line += atline;
        found(jj).file = srcfile;
      endfor
      findings = [findings, found];
    endif
    entries(:,end+1) = rows;
  endfor

endfunction
