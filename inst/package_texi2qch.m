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
## @deftypefn  {pkg-octave-doc} {} package_texi2qch (@var{pkgname})
## @deftypefnx {pkg-octave-doc} {} package_texi2qch (@var{pkgname}, @var{Name}, @var{Value})
##
## Generate a Qt compressed help file for an entire package.
##
## @code{package_texi2qch} takes a single input argument, @var{pkgname}, which
## is a char string with the package's name whose Qt help file needs to be
## generated, and writes @qcode{@var{pkgname}.qch} into the current working
## directory.  Octave's GUI reads such a file to populate its documentation
## tab: @code{pkg load} registers @file{doc/@var{pkgname}.qch} from the
## package's installation directory and @code{pkg unload} unregisters it, so
## the generated file must be placed in the package's @file{doc/} directory
## before the release tarball is built for it to have any effect.
##
## The help text of every function listed in the package's INDEX file is
## rendered to HTML, one page per INDEX category, and each function is
## registered as a keyword pointing at its own anchor within that page.  The
## help text of every classdef method and property is rendered and registered
## alongside the classdef itself.
##
## A @emph{grouped} classdef, one that sorts its methods under
## @qcode{** Group Name **} banner blocks and which
## @code{classdef_texi2html} renders as a set of pages rather than one,
## becomes a category of its own.  It is lifted out of the INDEX category it
## was listed under and given a page carrying its own help text, its
## properties, and its methods under a section per banner group, in the order
## the class declares them.  The contents tree of the documentation browser
## therefore shows such a class beside the categories rather than buried in
## one.  A flat classdef is left where its INDEX entry puts it.
##
## Grouping the pages by category rather than by function is deliberate.  Each
## file inside a @qcode{.qch} is compressed on its own, so a page per function
## discards what the pages share and inflates the result: for the
## @qcode{statistics} package the same documentation measures 0.57 MB at one
## page per category against 1.89 MB at one page per function, while no single
## page grows beyond a few hundred KB.
##
## @strong{Demos are not included}, neither their code nor their figures.  A
## @qcode{.qch} is an offline reference to be shipped inside the package, where
## the rendered figures of a package the size of @qcode{statistics} would cost
## more than the rest of the documentation put together.  Demos remain
## available through @code{demo} and through the online pages that
## @code{package_texi2html} builds.
##
## @code{package_texi2qch} requires the @code{qhelpgenerator} program of the Qt
## toolkit, which is located on the system's @code{$PATH} unless the
## @qcode{'generator'} option names it explicitly.  The program is looked up
## before any page is rendered and, if it cannot be found, an error is raised
## and nothing is written, rather than spending the build on documentation that
## cannot be packaged.
##
## Example:
##
## @example
## package_texi2qch ("statistics");
## @end example
##
## @subsubheading Optional Name/Value pairs
##
## @multitable @columnfractions 0.2 0.8
## @headitem @var{Name} @tab @var{Value}
##
## @item @qcode{'Generator'} @tab The @code{qhelpgenerator} executable, given
## as a char string.  By default the program is looked up on the system's
## @code{$PATH}.  Name it explicitly on a system carrying more than one Qt
## version, since a file built by one Qt major version may not register with a
## GUI linked against another.
##
## @item @qcode{'KeepHTML'} @tab A logical scalar specifying whether the
## intermediate HTML pages and the Qt help project file are kept beside the
## generated @qcode{.qch}, which is @qcode{false} by default.  They are useful
## for inspecting what was rendered before shipping it.
## @end multitable
##
## @seealso{package_texi2html, function_texi2html, classdef_texi2html}
## @end deftypefn

function package_texi2qch (pkgname, varargin)

  if (nargin < 1)
    print_usage ();
  endif
  if (! (ischar (pkgname) && isrow (pkgname)))
    error ("package_texi2qch: PKGNAME must be a character vector.");
  endif

  ## Parse optional Name/Value paired arguments
  names = {'Generator', 'KeepHTML'};
  dflts = {'', false};
  [opts, args] = parse_pairs (names, dflts, varargin);
  if (! isempty (args))
    print_usage ();
  endif
  if (! (ischar (opts.Generator) && (isempty (opts.Generator) ...
                                     || isrow (opts.Generator))))
    error ("package_texi2qch: 'Generator' must be a character vector.");
  endif
  if (! (isscalar (opts.KeepHTML) && (islogical (opts.KeepHTML) ...
                                      || isnumeric (opts.KeepHTML))))
    error ("package_texi2qch: 'KeepHTML' must be a logical scalar.");
  endif

  ## Resolve the Qt help generator before anything is rendered, so that a
  ## system without it costs nothing instead of failing after the work
  generator = i_find_generator (opts.Generator);

  ## Check package exists and it is loaded
  pkg_loaded = false;
  [desc, flag] = pkg ("describe", pkgname);
  if (strcmp (flag{:}, "Not installed"))
    error ("package_texi2qch: %s package is not installed.", pkgname);
  elseif (strcmp (flag{:}, "Not loaded"))
    pkg ("load", pkgname);
    [desc, flag] = pkg ("describe", pkgname);
    pkg_loaded = true;
  endif

  ## Get categories of functions available and the page each one owns.  A
  ## grouped classdef is a category in its own right, so it is lifted out of
  ## the INDEX category it was listed under and collected separately.
  pkg_cat = desc{1}.provides;
  cat = struct ("name", {}, "page", {}, "fcns", {});
  cls = struct ("name", {}, "page", {}, "groups", {}, "props", {});
  for i = 1:numel (pkg_cat)
    keep = {};
    for j = 1:numel (pkg_cat{i}.functions)
      fcn = pkg_cat{i}.functions{j};
      [MTHDS, PROPS, GROUPS] = i_class_members (fcn);
      if (! isempty (GROUPS))
        k = numel (cls) + 1;
        cls(k).name = fcn;
        cls(k).page = [i_sanitize(fcn), ".html"];
        cls(k).groups = GROUPS;
        cls(k).props = PROPS;
      else
        keep{end+1} = fcn;
      endif
    endfor
    if (! isempty (keep))
      k = numel (cat) + 1;
      cat(k).name = pkg_cat{i}.category;
      cat(k).page = [i_sanitize(cat(k).name), ".html"];
      cat(k).fcns = keep;
    endif
  endfor

  ## First pass: enumerate every documented name against the page and the
  ## anchor it is assigned to.  The map must be complete before anything is
  ## rendered, since the links inside a help text are retargeted against it.
  qchmap = cell (0, 3);
  for i = 1:numel (cat)
    for j = 1:numel (cat(i).fcns)
      fcn = cat(i).fcns{j};
      qchmap(end+1,:) = {fcn, cat(i).page, i_sanitize(fcn)};
      [MTHDS, PROPS] = i_class_members (fcn);
      for k = 1:numel (PROPS)
        nm = [fcn, ".", PROPS{k}];
        qchmap(end+1,:) = {nm, cat(i).page, i_sanitize(nm)};
      endfor
      for k = 1:numel (MTHDS)
        nm = [fcn, ".", MTHDS{k}];
        qchmap(end+1,:) = {nm, cat(i).page, i_sanitize(nm)};
      endfor
    endfor
  endfor
  for k = 1:numel (cls)
    qchmap(end+1,:) = {cls(k).name, cls(k).page, i_sanitize(cls(k).name)};
    for p = 1:numel (cls(k).props)
      nm = [cls(k).name, ".", cls(k).props{p}];
      qchmap(end+1,:) = {nm, cls(k).page, i_sanitize(nm)};
    endfor
    for g = 1:numel (cls(k).groups)
      for m = 1:numel (cls(k).groups(g).methods)
        nm = [cls(k).name, ".", cls(k).groups(g).methods{m}];
        qchmap(end+1,:) = {nm, cls(k).page, i_sanitize(nm)};
      endfor
    endfor
  endfor

  ## __texi2html__ links a name only when it appears in the first column
  pkgfcns = qchmap(:,1:2);

  ## Second pass: render one page per category
  tmpfiles = {};
  for i = 1:numel (cat)
    txt = i_page_head (cat(i).name, pkgname);
    for j = 1:numel (cat(i).fcns)
      fcn = cat(i).fcns{j};
      txt = [txt, i_render(fcn, "h2", pkgfcns, qchmap)];
      [MTHDS, PROPS] = i_class_members (fcn);
      for k = 1:numel (PROPS)
        txt = [txt, i_render([fcn, ".", PROPS{k}], "h3", pkgfcns, qchmap)];
      endfor
      for k = 1:numel (MTHDS)
        txt = [txt, i_render([fcn, ".", MTHDS{k}], "h3", pkgfcns, qchmap)];
      endfor
    endfor
    txt = [txt, "</body>\n</html>\n"];
    fname = fullfile (pwd, cat(i).page);
    i_write (fname, txt);
    tmpfiles{end+1} = fname;
  endfor

  ## One page per grouped classdef, its methods under a section per banner
  for k = 1:numel (cls)
    txt = i_page_head (cls(k).name, pkgname);
    txt = [txt, i_render(cls(k).name, "h2", pkgfcns, qchmap)];
    if (! isempty (cls(k).props))
      txt = [txt, "<h2>Properties</h2>\n"];
      for p = 1:numel (cls(k).props)
        nm = [cls(k).name, ".", cls(k).props{p}];
        txt = [txt, i_render(nm, "h3", pkgfcns, qchmap)];
      endfor
      for g = 1:numel (cls(k).groups)
        txt = [txt, "<h2>", cls(k).groups(g).name, "</h2>\n"];
        for m = 1:numel (cls(k).groups(g).methods)
          nm = [cls(k).name, ".", cls(k).groups(g).methods{m}];
          txt = [txt, i_render(nm, "h3", pkgfcns, qchmap)];
        endfor
      endfor
    endif
    txt = [txt, "</body>\n</html>\n"];
    fname = fullfile (pwd, cls(k).page);
    i_write (fname, txt);
    tmpfiles{end+1} = fname;
  endfor

  ## Write the Qt help project naming every page and every keyword
  qhpfile = fullfile (pwd, [pkgname, ".qhp"]);
  i_write_qhp (qhpfile, pkgname, cat, cls, qchmap);
  tmpfiles{end+1} = qhpfile;

  ## Compress the pages into the Qt help file
  qchfile = fullfile (pwd, [pkgname, ".qch"]);
  cmd = sprintf ("\"%s\" \"%s\" -o \"%s\"", generator, qhpfile, qchfile);
  [status, output] = system (cmd);
  if (status != 0)
    error ("package_texi2qch: %s failed: %s", generator, strtrim (output));
  endif

  ## Remove the intermediate files unless they were asked for
  if (! opts.KeepHTML)
    for i = 1:numel (tmpfiles)
      unlink (tmpfiles{i});
    endfor
  endif

  ## Leave the package as it was found
  if (pkg_loaded)
    pkg ("unload", pkgname);
  endif

endfunction

## Locate a usable Qt help generator, or say so and stop.
function gen = i_find_generator (given)
  if (! isempty (given))
    cand = {given};
  else
    cand = {'qhelpgenerator-qt6', 'qhelpgenerator-qt5', 'qhelpgenerator'};
  endif
  for i = 1:numel (cand)
    [status, ~] = system (sprintf ("\"%s\" -v", cand{i}));
    if (status == 0)
      gen = cand{i};
      return;
    endif
  endfor
  if (isempty (given))
    error (strcat ("package_texi2qch: no Qt help generator found.  Install", ...
                   " the Qt help tools, or name the program with the", ...
                   " 'Generator' option."));
  else
    error ("package_texi2qch: '%s' is not a usable Qt help generator.", given);
  endif
endfunction

## Reduce a name to the characters an anchor and a file name may carry.
function s = i_sanitize (s)
  s = regexprep (s, '[^A-Za-z0-9._-]', "_");
endfunction

## Return the methods and the properties of a classdef, or empty for anything
## else.  The classdef keyword is looked for in the file itself, since methods
## and properties answer for names that are not classes at all.
function [MTHDS, PROPS, GROUPS] = i_class_members (name)
  MTHDS = {};
  PROPS = {};
  GROUPS = [];
  fname = which (name);
  ## Only a classdef source can carry methods; anything else, a compiled
  ## function above all, is not worth reading and would not parse as text.
  if (isempty (fname) || numel (fname) < 2 || ! strcmp (fname(end-1:end), ".m"))
    return;
  endif
  try
    txt = fileread (fname);
  catch
    return;
  end_try_catch
  ## The classdef keyword is ASCII, and a source file carrying a byte that is
  ## not valid UTF-8 makes regexp refuse the whole string, so drop them first.
  txt(txt > 127) = " ";
  if (isempty (regexp (txt, '^\s*classdef\s', "once", "lineanchors")))
    return;
  endif
  try
    MTHDS = get_methods_ordered (name, methods (name));
  catch
    MTHDS = {};
  end_try_catch
  try
    PROPS = get_properties_ordered (name, properties (name));
  catch
    PROPS = {};
  end_try_catch
  ## A non-empty group list is what makes a classdef "grouped": see
  ## parse_method_groups, which returns empty when the source has no banner.
  try
    GROUPS = get_method_groups (name, MTHDS);
  catch
    GROUPS = [];
  end_try_catch
endfunction

## Render one documented name into a titled, anchored HTML block.
function html = i_render (name, tag, pkgfcns, qchmap)
  html = "";
  [text, format] = get_help_text (name);
  if (! strcmp (format, "texinfo"))
    return;
  endif
  try
    frag = __texi2html__ (text, name, pkgfcns);
  catch
    return;                 ## a help text that will not render is skipped
  end_try_catch
  frag = qch_postprocess (frag, name, qchmap);
  idx = find (strcmp (qchmap(:,1), name), 1);
  html = ["<a name=\"", qchmap{idx,3}, "\"></a>\n<", tag, ">", name, ...
          "</", tag, ">\n", frag, "\n"];
endfunction

## The opening of a category page.  It carries no navigation and no assets:
## the Qt browser supplies its own, and every byte here is shipped.
function txt = i_page_head (catname, pkgname)
  txt = ["<!DOCTYPE html>\n<html>\n<head>\n", ...
         "<meta charset=\"utf-8\"/>\n<title>", catname, "</title>\n", ...
         "</head>\n<body>\n<h1>", pkgname, ": ", catname, "</h1>\n"];
endfunction

## Write a character vector to a file, or say which file could not be written.
function i_write (fname, txt)
  fid = fopen (fname, "wt");
  if (fid < 0)
    error ("package_texi2qch: cannot write '%s'.", fname);
  endif
  fputs (fid, txt);
  fclose (fid);
endfunction

## Write the Qt help project file listing the pages and the keywords.
function i_write_qhp (fname, pkgname, cat, cls, qchmap)
  fid = fopen (fname, "wt");
  if (fid < 0)
    error ("package_texi2qch: cannot write '%s'.", fname);
  endif
  fputs (fid, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
  fputs (fid, "<QtHelpProject version=\"1.0\">\n");
  fprintf (fid, "  <namespace>octave.community.%s</namespace>\n", pkgname);
  fputs (fid, "  <virtualFolder>doc</virtualFolder>\n");
  fputs (fid, "  <filterSection>\n    <toc>\n");
  if (! isempty (cat))
    root = cat(1).page;
  else
    root = cls(1).page;
  endif
  fprintf (fid, "      <section title=\"%s\" ref=\"%s\">\n", pkgname, root);
  for i = 1:numel (cat)
    fprintf (fid, "        <section title=\"%s\" ref=\"%s\"/>\n", ...
             cat(i).name, cat(i).page);
  endfor
  ## A grouped classdef sits beside the categories, its banner groups nested
  ## under it, so the contents tree mirrors the class rather than hiding it.
  for k = 1:numel (cls)
    fprintf (fid, "        <section title=\"%s\" ref=\"%s\">\n", ...
             cls(k).name, cls(k).page);
    for g = 1:numel (cls(k).groups)
      fprintf (fid, "          <section title=\"%s\" ref=\"%s\"/>\n", ...
               cls(k).groups(g).name, cls(k).page);
    endfor
    fputs (fid, "        </section>\n");
  endfor
  fputs (fid, "      </section>\n    </toc>\n    <keywords>\n");
  for i = 1:rows (qchmap)
    fprintf (fid, "      <keyword name=\"%s\" ref=\"%s#%s\"/>\n", ...
             qchmap{i,1}, qchmap{i,2}, qchmap{i,3});
  endfor
  fputs (fid, "    </keywords>\n    <files>\n");
  for i = 1:numel (cat)
    fprintf (fid, "      <file>%s</file>\n", cat(i).page);
  endfor
  for k = 1:numel (cls)
    fprintf (fid, "      <file>%s</file>\n", cls(k).page);
  endfor
  fputs (fid, "    </files>\n  </filterSection>\n</QtHelpProject>\n");
  fclose (fid);
endfunction

%!error <Invalid call> package_texi2qch ()
%!error <package_texi2qch: PKGNAME must be a character vector.> ...
%! package_texi2qch (1)
%!error <package_texi2qch: 'Generator' must be a character vector.> ...
%! package_texi2qch ("statistics", 'Generator', 1)
%!error <package_texi2qch: 'KeepHTML' must be a logical scalar.> ...
%! package_texi2qch ("statistics", 'KeepHTML', "no")
%!error <Invalid call> package_texi2qch ("statistics", 'nosuch', 1)
