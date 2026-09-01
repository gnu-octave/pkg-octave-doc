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
## registered as a keyword pointing at its own anchor within that page.
##
## A classdef is not rendered onto its category page.  It keeps the category
## its INDEX entry puts it in, and is given a page tree of its own beneath it,
## whatever its size:
##
## @itemize
## @item
## @file{<Class>.html} carries the class help text and a list of links to the
## pages below it.
## @item
## @file{<Class>_properties.html} carries one section per property, and is
## absent from a class that declares none.
## @item
## @file{<Class>_methods.html} carries one section per method.  A
## @emph{grouped} classdef, one that sorts its methods under
## @qcode{** Group Name **} banner blocks as @code{classdef_texi2html} reads
## them, takes one page per group instead, named after it and carrying that
## group's methods, in the order the class declares them.
## @end itemize
##
## The contents tree of the documentation browser therefore nests a class
## under its own category, and is entered rather than scrolled past among its
## neighbours, which is what a category holding a few dozen classdefs would
## otherwise ask of a reader.  A category page carries its plain functions and
## a list of links to the classes it owns.
##
## Functions are grouped by category rather than given a page each because
## every file inside a @qcode{.qch} is compressed on its own, so fragmenting
## what the pages share inflates the archive: for the @qcode{statistics}
## package the same documentation measures 0.57 MB at one page per category
## against 1.89 MB at one page per function.  The page tree a classdef is
## given costs a part of that difference and buys the navigation back.
##
## @strong{Demos are not included}, neither their code nor their figures.  A
## @qcode{.qch} is an offline reference to be shipped inside the package, where
## the rendered figures of a package the size of @qcode{statistics} would cost
## more than the rest of the documentation put together.  Demos remain
## available through @code{demo} and through the online pages that
## @code{package_texi2html} builds.
##
## @strong{A @code{@@tex} formula is rendered as its @code{@@ifnottex}
## alternative, and dropped when it has none.}  The documentation browser of
## the GUI runs no JavaScript, so the MathJax that typesets a formula in the
## online pages is not available to it, and the TeX would reach the reader as
## source.  This is what @code{makeinfo} does for every output that is not
## TeX, and what @code{help} prints in the terminal for the same docstring.
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
##
## @item @qcode{'Options'} @tab A @code{pkg_doc_options} object giving each
## rule the severity the package asks for, the defaults being used when none
## is given.  Unlike @code{package_texi2cache} and @code{check_texi_docs},
## which read @file{doc-options.json} from the package root they are run in,
## this reads no settings file: it works from the @strong{installed} package,
## and a file at a source root is not installed, only the contents of
## @file{inst} together with @file{doc} and @file{packinfo} being carried
## there.  So a package's own conventions reach this route by being handed to
## it, and the rules that are on by default, which are the ones wrong in any
## package, apply either way.
## @end multitable
##
## Every help text is checked as it is read, and what is found is reported
## with the name it belongs to and a line counted from the first line of that
## help text.  A finding never stops the build: a page is written from a help
## text whatever it says, since refusing would leave the package with no
## documentation over a defect the reader would have met anyway.
##
## Only the rules a help text can be judged by on its own are applied here.
## The rest measure the file a help text was written in, which this route
## never opens, working as it does from the installed package; @code{help} is
## its source and @code{check_texi_docs} is where those rules live.
##
## @seealso{package_texi2html, function_texi2html, classdef_texi2html,
## check_texi_docs, pkg_doc_options}
## @end deftypefn

function package_texi2qch (pkgname, varargin)

  if (nargin < 1)
    print_usage ();
  endif
  if (! (ischar (pkgname) && isrow (pkgname)))
    error ("package_texi2qch: PKGNAME must be a character vector.");
  endif

  ## Parse optional Name/Value paired arguments
  names = {'Generator', 'KeepHTML', 'Options'};
  dflts = {'', false, []};
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
  docopts = opts.Options;
  if (isempty (docopts))
    docopts = pkg_doc_options ();
  elseif (! isa (docopts, 'pkg_doc_options'))
    error (strcat ("package_texi2qch: 'Options' must be a pkg_doc_options", ...
                   " object."));
  endif
  findings = struct ('rule', {}, 'severity', {}, 'line', {}, 'message', {}, ...
                     'file', {});
  examined = 0;

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
  cat = struct ("name", {}, "page", {}, "fcns", {}, "clsidx", {});
  cls = struct ("name", {}, "page", {}, "props", {}, "proppage", {}, ...
                "subs", {});
  for i = 1:numel (pkg_cat)
    ci = numel (cat) + 1;
    cat(ci).name = pkg_cat{i}.category;
    cat(ci).page = [i_sanitize(pkg_cat{i}.category), ".html"];
    cat(ci).fcns = {};
    cat(ci).clsidx = [];
    for j = 1:numel (pkg_cat{i}.functions)
      fcn = pkg_cat{i}.functions{j};
      [MTHDS, PROPS, GROUPS, ISCLS] = i_class_members (fcn);
      if (! ISCLS)
        cat(ci).fcns{end+1} = fcn;
        continue;
      endif
      k = numel (cls) + 1;
      base = i_sanitize (fcn);
      cls(k).name = fcn;
      cls(k).page = [base, ".html"];
      cls(k).props = PROPS;
      if (isempty (PROPS))
        cls(k).proppage = "";
      else
        cls(k).proppage = [base, "_properties.html"];
      endif
      subs = struct ("title", {}, "page", {}, "methods", {});
      if (! isempty (GROUPS))
        for g = 1:numel (GROUPS)
          subs(g).title = GROUPS(g).name;
          subs(g).page = [base, "_", i_sanitize(GROUPS(g).name), ".html"];
          subs(g).methods = GROUPS(g).methods;
        endfor
      elseif (! isempty (MTHDS))
        subs(1).title = "Methods";
        subs(1).page = [base, "_methods.html"];
        subs(1).methods = MTHDS;
      endif
      cls(k).subs = subs;
      cat(ci).clsidx(end+1) = k;
    endfor
  endfor

  ## First pass: enumerate every documented name against the page and the
  ## anchor it is assigned to.  The map must be complete before anything is
  ## rendered, since the links inside a help text are retargeted against it.
  qchmap = cell (0, 3);
  for i = 1:numel (cat)
    for j = 1:numel (cat(i).fcns)
      fcn = cat(i).fcns{j};
      qchmap(end+1,:) = {fcn, cat(i).page, i_sanitize(fcn)};
    endfor
  endfor
  for k = 1:numel (cls)
    qchmap(end+1,:) = {cls(k).name, cls(k).page, i_sanitize(cls(k).name)};
    for p = 1:numel (cls(k).props)
      nm = [cls(k).name, ".", cls(k).props{p}];
      qchmap(end+1,:) = {nm, cls(k).proppage, i_sanitize(nm)};
    endfor
    for t = 1:numel (cls(k).subs)
      for m = 1:numel (cls(k).subs(t).methods)
        nm = [cls(k).name, ".", cls(k).subs(t).methods{m}];
        qchmap(end+1,:) = {nm, cls(k).subs(t).page, i_sanitize(nm)};
      endfor
    endfor
  endfor

  ## __texi2html__ links a name only when it appears in the first column
  pkgfcns = qchmap(:,1:2);

  ## Second pass: render one page per category, functions only.  The first
  ## sentence of every top-level name is kept as it is rendered, since the
  ## landing page lists them and nothing else reads a help text twice.
  tmpfiles = {};
  firsts = cell (0, 2);
  for i = 1:numel (cat)
    txt = i_page_head (cat(i).name, pkgname);
    for j = 1:numel (cat(i).fcns)
      [frag, first, found, ex] = i_render (cat(i).fcns{j}, "h2", pkgfcns, ...
                                           qchmap, docopts);
      findings = [findings, found];
      examined += ex;

      txt = [txt, frag];
      firsts(end+1,:) = {cat(i).fcns{j}, first};
    endfor
    if (! isempty (cat(i).clsidx))
      txt = [txt, "<h2>Classes</h2>\n<ul>\n"];
      for c = cat(i).clsidx
        txt = [txt, "<li><a href=\"", cls(c).page, "\">", cls(c).name, ...
               "</a></li>\n"];
      endfor
      txt = [txt, "</ul>\n"];
    endif
    tmpfiles{end+1} = i_finish (cat(i).page, txt);
  endfor

  ## A classdef owns a page of its own carrying its class help text and a
  ## link to each of its subpages, so that a class is entered rather than
  ## scrolled past among its neighbours.
  for k = 1:numel (cls)
    txt = i_page_head (cls(k).name, pkgname);
    [frag, first, found, ex] = i_render (cls(k).name, "h2", pkgfcns, ...
                                         qchmap, docopts);
    findings = [findings, found];
    examined += ex;

    txt = [txt, frag];
    firsts(end+1,:) = {cls(k).name, first};
    txt = [txt, "<h2>Contents</h2>\n<ul>\n"];
    if (! isempty (cls(k).proppage))
      txt = [txt, "<li><a href=\"", cls(k).proppage, "\">Properties</a>", ...
             "</li>\n"];
    endif
    for t = 1:numel (cls(k).subs)
      txt = [txt, "<li><a href=\"", cls(k).subs(t).page, "\">", ...
             cls(k).subs(t).title, "</a></li>\n"];
    endfor
    txt = [txt, "</ul>\n"];
    tmpfiles{end+1} = i_finish (cls(k).page, txt);

    ## The properties of the class, one subpage
    if (! isempty (cls(k).proppage))
      txt = i_page_head ([cls(k).name, " properties"], pkgname);
      for p = 1:numel (cls(k).props)
        nm = [cls(k).name, ".", cls(k).props{p}];
        [frag, ~, found, ex] = i_render (nm, "h2", pkgfcns, qchmap, docopts);
        txt = [txt, frag];
        findings = [findings, found];
        examined += ex;
      endfor
      tmpfiles{end+1} = i_finish (cls(k).proppage, txt);
    endif

    ## Its methods, one subpage for a flat classdef and one per banner group
    ## for a grouped one
    for t = 1:numel (cls(k).subs)
      txt = i_page_head ([cls(k).name, " ", cls(k).subs(t).title], pkgname);
      for m = 1:numel (cls(k).subs(t).methods)
        nm = [cls(k).name, ".", cls(k).subs(t).methods{m}];
        [frag, ~, found, ex] = i_render (nm, "h2", pkgfcns, qchmap, docopts);
        txt = [txt, frag];
        findings = [findings, found];
        examined += ex;
      endfor
      tmpfiles{end+1} = i_finish (cls(k).subs(t).page, txt);
    endfor
  endfor

  ## The landing page.  The root of the contents tree points here, so that
  ## double-clicking the package enters it at an overview rather than at
  ## whichever category happened to be listed first.
  indexpage = i_index_page (pkgname, desc{1}, cat, cls, qchmap, firsts);
  tmpfiles{end+1} = fullfile (pwd, indexpage);

  ## Write the Qt help project naming every page and every keyword
  qhpfile = fullfile (pwd, [pkgname, ".qhp"]);
  i_write_qhp (qhpfile, pkgname, cat, cls, qchmap, indexpage);
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

  ## Say what the help texts turned out to be, the pages having been built
  ## from them whatever they said
  __show_findings__ (findings, docopts, pkgname, examined, 'help texts');

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
    ## 2>&1 keeps the shell's report of a candidate that is not installed out
    ## of the terminal: system does not capture stderr on its own.
    [status, ~] = system (sprintf ("\"%s\" -v 2>&1", cand{i}));
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
function [MTHDS, PROPS, GROUPS, ISCLS] = i_class_members (name)
  MTHDS = {};
  PROPS = {};
  GROUPS = [];
  ISCLS = false;
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
  ISCLS = true;
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

## Render one documented name into a titled, anchored HTML block, and report
## the first sentence of its help text for the landing page to list it by.
function [html, first, findings, examined] = i_render (name, tag, pkgfcns, ...
                                                      qchmap, docopts)
  first = "";
  examined = 0;
  findings = struct ('rule', {}, 'severity', {}, 'line', {}, 'message', {}, ...
                     'file', {});
  ## The anchor and the heading are emitted whatever the help text turns out
  ## to be: the keyword was registered before rendering, so a name that is
  ## skipped here would leave the documentation browser with nowhere to land.
  idx = find (strcmp (qchmap(:,1), name), 1);
  html = ["<a name=\"", qchmap{idx,3}, "\"></a>\n<", tag, ">", name, ...
          "</", tag, ">\n"];
  [text, format] = get_help_text (name);
  if (strcmp (format, "texinfo"))
    examined = 1;
    ## The help text is checked as it was written, not as it is rendered: the
    ## TeX blocks are taken out below, which would move every line after them
    found = __texi_lint__ (text, docopts);
    for ii = 1:numel (found)
      found(ii).file = name;
    endfor
    if (! isempty (found))
      findings = [findings, found];
    endif
    try
      frag = __texi2html__ (i_untex (text), name, pkgfcns);
      body = qch_postprocess (frag, name, qchmap);
      first = get_text_first_sentence (body);
      html = [html, body, "\n"];
      return;
    catch
      ## fall through and show the help text as it stands
    end_try_catch
  endif
  html = [html, "<pre>", i_xml(strtrim (text)), "</pre>\n"];
endfunction

## Drop a @tex block, which this target cannot typeset.  The documentation
## browser of the GUI is a QTextBrowser, which runs no JavaScript, so the
## MathJax that renders the TeX literal of __texi2html__ in the online pages is
## not there.  Dropping the block leaves __texi2html__ to keep the @ifnottex
## alternative instead, which is what makeinfo does for every non-TeX output
## and what the author wrote it for.  A docstring carrying no alternative
## renders without the formula, exactly as `help' prints it in the terminal:
## the literal reaching the page as source is worse than its absence, all the
## more since a browser reads the '<' of a relation as the opening of a tag and
## swallows the rest, and since a formula whose author wrote no plain-text form
## for it is usually one that has none worth reading.
function text = i_untex (text)
  do
    b = strfind (text, "@tex");
    e = strfind (text, "@end tex");
    if (isempty (b))
      break;
    endif
    b = b(1);
    ## Only a terminator that follows the opening closes it: a docstring that
    ## carries them the other way round would otherwise never be consumed.
    e = e(e > b);
    if (isempty (e))
      break;
    endif
    e = e(1) + 7;                     # end of "@end tex"
    tail = text(e+1:end);
    if (! isempty (tail) && tail(1) == "\n")
      tail = tail(2:end);
    endif
    text = [text(1:b-1), tail];
  until (false)
endfunction

## The landing page of the package: what the online index page carries, minus
## the assets and the category selector, which needs a script to do anything.
## The name, version and description come from the package's own metadata, and
## every documented top-level name is listed under its category against the
## first sentence of its help text.
function page = i_index_page (pkgname, desc, cat, cls, qchmap, firsts)
  page = "index.html";
  txt = ["<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"utf-8\"/>\n", ...
         "<title>", pkgname, "</title>\n</head>\n<body>\n", ...
         "<h1>", pkgname, " ", desc.version, "</h1>\n"];
  if (! isempty (desc.date))
    txt = [txt, "<p>", i_xml(desc.date), "</p>\n"];
  endif
  if (! isempty (desc.description))
    txt = [txt, "<p>", i_xml(desc.description), "</p>\n"];
  endif
  txt = [txt, "<h2>Contents</h2>\n<ul>\n"];
  for i = 1:numel (cat)
    txt = [txt, "<li><a href=\"#", i_sanitize(cat(i).name), "\">", ...
           i_xml(cat(i).name), "</a></li>\n"];
  endfor
  txt = [txt, "</ul>\n"];
  for i = 1:numel (cat)
    txt = [txt, "<h2><a name=\"", i_sanitize(cat(i).name), "\"></a>", ...
           i_xml(cat(i).name), "</h2>\n<table>\n"];
    for j = 1:numel (cat(i).fcns)
      txt = [txt, i_index_row(cat(i).fcns{j}, qchmap, firsts)];
    endfor
    for c = cat(i).clsidx
      txt = [txt, i_index_row(cls(c).name, qchmap, firsts)];
    endfor
    txt = [txt, "</table>\n"];
  endfor
  i_write (fullfile (pwd, page), [txt, "</body>\n</html>\n"]);
endfunction

## One row of the landing page: a name against the first sentence of its help
## text, linking to the anchor that name owns.
function row = i_index_row (name, qchmap, firsts)
  idx = find (strcmp (qchmap(:,1), name), 1);
  href = [qchmap{idx,2}, "#", qchmap{idx,3}];
  fidx = find (strcmp (firsts(:,1), name), 1);
  if (isempty (fidx))
    first = "";
  else
    first = firsts{fidx,2};
  endif
  row = ["<tr><td><code><a href=\"", href, "\">", i_xml(name), ...
         "</a></code></td><td>", first, "</td></tr>\n"];
endfunction

## The opening of a category page.  It carries no navigation and no assets:
## the Qt browser supplies its own, and every byte here is shipped.
function txt = i_page_head (catname, pkgname)
  txt = ["<!DOCTYPE html>\n<html>\n<head>\n", ...
         "<meta charset=\"utf-8\"/>\n<title>", catname, "</title>\n", ...
         "</head>\n<body>\n<h1>", pkgname, ": ", catname, "</h1>\n"];
endfunction

## Close a page, write it to the working directory, and name the file.
function fname = i_finish (page, txt)
  fname = fullfile (pwd, page);
  i_write (fname, [txt, "</body>\n</html>\n"]);
endfunction

## Escape what an XML attribute may not carry verbatim.  A banner group title
## is free text and reaches the Qt help project as an attribute value.
function s = i_xml (s)
  s = strrep (s, "&", "&amp;");
  s = strrep (s, "<", "&lt;");
  s = strrep (s, ">", "&gt;");
  s = strrep (s, "\"", "&quot;");
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
function i_write_qhp (fname, pkgname, cat, cls, qchmap, indexpage)
  fid = fopen (fname, "wt");
  if (fid < 0)
    error ("package_texi2qch: cannot write '%s'.", fname);
  endif
  fputs (fid, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
  fputs (fid, "<QtHelpProject version=\"1.0\">\n");
  fprintf (fid, "  <namespace>octave.community.%s</namespace>\n", pkgname);
  fputs (fid, "  <virtualFolder>doc</virtualFolder>\n");
  fputs (fid, "  <filterSection>\n    <toc>\n");
  fprintf (fid, "      <section title=\"%s\" ref=\"%s\">\n", pkgname, ...
           indexpage);
  for i = 1:numel (cat)
    if (isempty (cat(i).clsidx))
      fprintf (fid, "        <section title=\"%s\" ref=\"%s\"/>\n", ...
               i_xml (cat(i).name), cat(i).page);
      continue;
    endif
    ## A classdef nests inside the category its INDEX entry puts it in, its
    ## properties and its methods nested under it in turn.
    fprintf (fid, "        <section title=\"%s\" ref=\"%s\">\n", ...
             i_xml (cat(i).name), cat(i).page);
    for c = cat(i).clsidx
      fprintf (fid, "          <section title=\"%s\" ref=\"%s\">\n", ...
               i_xml (cls(c).name), cls(c).page);
      if (! isempty (cls(c).proppage))
        fprintf (fid, ["            <section title=\"Properties\"", ...
                       " ref=\"%s\"/>\n"], cls(c).proppage);
      endif
      for t = 1:numel (cls(c).subs)
        fprintf (fid, "            <section title=\"%s\" ref=\"%s\"/>\n", ...
                 i_xml (cls(c).subs(t).title), cls(c).subs(t).page);
      endfor
      fputs (fid, "          </section>\n");
    endfor
    fputs (fid, "        </section>\n");
  endfor
  fputs (fid, "      </section>\n    </toc>\n    <keywords>\n");
  for i = 1:rows (qchmap)
    fprintf (fid, "      <keyword name=\"%s\" ref=\"%s#%s\"/>\n", ...
             i_xml (qchmap{i,1}), qchmap{i,2}, qchmap{i,3});
  endfor
  fputs (fid, "    </keywords>\n    <files>\n");
  fprintf (fid, "      <file>%s</file>\n", indexpage);
  for i = 1:numel (cat)
    fprintf (fid, "      <file>%s</file>\n", cat(i).page);
  endfor
  for k = 1:numel (cls)
    fprintf (fid, "      <file>%s</file>\n", cls(k).page);
    if (! isempty (cls(k).proppage))
      fprintf (fid, "      <file>%s</file>\n", cls(k).proppage);
    endif
    for t = 1:numel (cls(k).subs)
      fprintf (fid, "      <file>%s</file>\n", cls(k).subs(t).page);
    endfor
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
