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
## @deftypefn  {pkg-octave-doc} {} check_texi_docs ()
## @deftypefnx {pkg-octave-doc} {} check_texi_docs (@var{options})
## @deftypefnx {pkg-octave-doc} {@var{status} =} check_texi_docs (@dots{})
## @deftypefnx {pkg-octave-doc} {[@var{status}, @var{report}] =} check_texi_docs (@dots{})
##
## Check the texinfo help texts of a tree, writing nothing.
##
## Every help text below the current directory is parsed and reported on, and
## no file of any kind is produced.  It is the way to examine a package whose
## documentation is built as HTML, that route writing pages rather than
## reporting on what it rendered, and it is the fastest of the three: nothing
## is rendered and no definition is loaded, so a tree is read straight from
## disk.
##
## It runs from wherever it is called and works downwards, so a package root
## covers the whole package and @file{inst} covers only what is below it.  A
## @file{src} directory is passed over, a @code{DEFUN_DLD} help text living
## inside the compiled file rather than the source, as are @file{tests},
## @file{demos} and @file{datasets}, which carry none.
##
## Unlike the documentation builders, it checks @strong{everything it finds},
## a @code{Hidden} member and a private helper included.  Those are the help
## texts no reader ever meets and nothing else looks at, so they are the ones
## that rot unnoticed.
##
## @var{options} is a @code{pkg_doc_options} object, and without one the
## settings are read from @file{doc-options.json} in the current directory if
## there is one.  The @file{INDEX} of the current directory is read unless the
## object names another, which is what the category label rule is checked
## against; where no @file{INDEX} can be found that rule stands down rather
## than guess.
##
## @var{status} is the number of findings and is zero when nothing was found.
## @var{report} is a struct array of them, carrying @qcode{'rule'},
## @qcode{'severity'}, @qcode{'file'}, @qcode{'line'} and @qcode{'message'}.
## With no output requested they are printed.
##
## @seealso{package_texi2cache, package_texi2html, package_texi2qch,
## pkg_doc_options}
## @end deftypefn

function [status, report] = check_texi_docs (options)

  ## Input validation
  if (nargin == 1 && ! isa (options, 'pkg_doc_options'))
    error (strcat ("check_texi_docs: OPTIONS must be a pkg_doc_options", ...
                   " object."));
  endif

  here = pwd ();
  if (nargin == 0)
    config = fullfile (here, 'doc-options.json');
    if (exist (config, 'file'))
      options = pkg_doc_options (config);
    else
      options = pkg_doc_options ();
    endif
  endif
  why = '';
  if (! ischar (options.IndexLocation))
    index = fullfile (here, 'INDEX');
    if (exist (index, 'file'))
      options.IndexLocation = index;
    endif
  endif
  [~, pkgname, why] = __index_info__ (options);

  report = struct ('rule', {}, 'severity', {}, 'line', {}, 'message', {}, ...
                   'file', {});
  seed = __index_notfound__ (options, why);
  if (! isempty (seed))
    report = [report, seed];
  endif

  files = __texi_files__ (here);
  for ii = 1:numel (files)
    report = [report, __check_file__(files{ii}, here, options, pkgname)];
  endfor

  status = numel (report);
  if (nargout == 0)
    __show_findings__ (report, options, here);
    clear status;
  endif

endfunction

## Every help text in one file, checked against both sets of rules
function findings = __check_file__ (file, root, options, pkgname)

  findings = struct ('rule', {}, 'severity', {}, 'line', {}, 'message', {}, ...
                     'file', {});
  shown = file;
  if (strncmp (file, [root filesep], numel (root) + 1))
    shown = file(numel (root) + 2:end);
  endif

  txt = strrep (fileread (file), "\r\n", "\n");
  isclass = ! isempty (regexp (txt, '(?m)^\s*classdef($|[ \t<])', 'once'));
  [~, base] = fileparts (file);

  blocks = __class_blocks__ (file);
  if (isempty (blocks))
    if (! strcmp (options.MissingDocstring, 'off'))
      findings(1) = struct ('rule', 'MissingDocstring', ...
                            'severity', options.MissingDocstring, 'line', 1, ...
                            'message', 'the file carries no texinfo help', ...
                            'file', shown);
    endif
    return;
  endif

  for jj = 1:numel (blocks)
    lines = blocks(jj).lines;
    at = blocks(jj).line;

    ## The renderer is handed the text with its comment markers taken off,
    ## which is what the structural rules count their columns against
    plain = cell (size (lines));
    for kk = 1:numel (lines)
      plain{kk} = regexprep (lines{kk}, '^\s*##\s?', '');
    endfor

    found = __texi_lint__ (strjoin (plain, "\n"), options);

    ## A member belongs to a class; a subfunction of a plain file does not,
    ## so the rules about class members are not applied to it
    ctx = struct ('package', pkgname, 'class', '', 'member', '');
    if (isclass)
      ctx.class = __qualified__ (file, base);
      ctx.member = blocks(jj).member;
    endif
    ## A private helper reaches no published page, so the rules about what a
    ## label says to a reader do not apply to it
    ctx.published = isempty (strfind (file, [filesep 'private' filesep]));
    found = [found, __source_lint__(lines, options, ctx)];

    for kk = 1:numel (found)
      found(kk).line += at;
      found(kk).file = shown;
    endfor
    if (! isempty (found))
      findings = [findings, found];
    endif
  endfor

endfunction

## The name a class is known by, which carries the namespaces its file sits in
function name = __qualified__ (file, base)
  name = base;
  parts = strsplit (fileparts (file), filesep);
  ns = {};
  for ii = numel (parts):-1:1
    if (isempty (parts{ii}) || parts{ii}(1) != '+')
      break;
    endif
    ns = [parts(ii), ns];
  endfor
  for ii = numel (ns):-1:1
    name = [ns{ii}(2:end) '.' name];
  endfor
endfunction

## Every file below a directory that can carry a texinfo help text
function files = __texi_files__ (root)
  files = {};
  files = __gather__ (files, root);
endfunction

function files = __gather__ (files, here)
  d = dir (here);
  for ii = 1:numel (d)
    nm = d(ii).name;
    if (strcmp (nm, '.') || strcmp (nm, '..'))
      continue;
    endif
    full = fullfile (here, nm);
    if (d(ii).isdir)
      ## src holds sources whose help text is compiled into the oct-file, and
      ## the rest of these carry none at all
      if (nm(1) == '.' ...
          || any (strcmp (nm, {'src', 'tests', 'demos', 'datasets'})))
        continue;
      endif
      files = __gather__ (files, full);
    elseif (numel (nm) > 2 && strcmp (nm(end-1:end), '.m'))
      files{end+1} = full;
    endif
  endfor
endfunction

## The cases build a small tree in a temporary place and cd into it.  Nothing
## is written by the function, so each case asserts on what came back and the
## last one checks the tree was left as it was found.

%!test  # a sound tree yields nothing, and a defect is found with its place
%! d = fullfile (tempdir (), 'pkg_octave_doc_ck_bist');
%! if (isfolder (d))
%!   confirm_recursive_rmdir (false, 'local');
%!   rmdir (d, 's');
%! endif
%! mkdir (d);
%! mkdir (fullfile (d, 'private'));
%! mkdir (fullfile (d, 'src'));
%! fid = fopen (fullfile (d, 'INDEX'), 'w');
%! fputs (fid, "ckpkg >> Ck Package\nDocumentation\n cksound\n");
%! fclose (fid);
%! fid = fopen (fullfile (d, 'cksound.m'), 'w');
%! fprintf (fid, '## -*- texinfo -*-\n## @deftypefn {ckpkg} {} cksound ()\n');
%! fprintf (fid, '##\n## A help text with nothing wrong in it.\n##\n');
%! fprintf (fid, '## @end deftypefn\nfunction cksound ()\nendfunction\n');
%! fclose (fid);
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   assert (check_texi_docs (), 0);
%!   fid = fopen (fullfile (d, 'ckbad.m'), 'w');
%!   fprintf (fid, '## -*- texinfo -*-\n## @deftypefn {ckpkg} {} ckbad ()\n');
%!   fprintf (fid, '##\n## A help text with a defect in it.\n##\n');
%!   fprintf (fid, '## @itemize\n## @item one\n');
%!   fprintf (fid, '## @end itemize and text that should not be here\n');
%!   fprintf (fid, '##\n## @end deftypefn\nfunction ckbad ()\nendfunction\n');
%!   fclose (fid);
%!   [st, rep] = check_texi_docs ();
%!   assert (st > 0);
%!   at = find (strcmp ({rep.rule}, 'EndTrailingText'));
%!   assert (numel (at), 1);
%!   assert (rep(at).file, 'ckbad.m');
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # a private helper is read, but its label reaches no one and is let be
%! d = fullfile (tempdir (), 'pkg_octave_doc_ck_bist');
%! fid = fopen (fullfile (d, 'private', '__ckhelper__.m'), 'w');
%! fprintf (fid, '## -*- texinfo -*-\n');
%! fprintf (fid, '## @deftypefn {Private Function} {} __ckhelper__ ()\n');
%! fprintf (fid, '##\n## A private helper labelled by another convention.\n');
%! fprintf (fid, '##\n## @itemize\n## @item one\n');
%! fprintf (fid, '## @end itemize and text that should not be here\n');
%! fprintf (fid, '##\n## @end deftypefn\n');
%! fprintf (fid, 'function __ckhelper__ ()\nendfunction\n');
%! fclose (fid);
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   [~, rep] = check_texi_docs ();
%!   priv = strcmp ({rep.file}, fullfile ('private', '__ckhelper__.m'));
%!   assert (any (priv));
%!   assert (all (strcmp ({rep(priv).rule}, 'EndTrailingText')));
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # a class in a namespace is documented under its qualified name
%! d = fullfile (tempdir (), 'pkg_octave_doc_ck_bist');
%! mkdir (fullfile (d, '+ck'));
%! fid = fopen (fullfile (d, '+ck', 'CkClass.m'), 'w');
%! fprintf (fid, 'classdef CkClass\n');
%! fprintf (fid, '  ## -*- texinfo -*-\n  ## @deftp {ck} CkClass\n  ##\n');
%! fprintf (fid, '  ## A class living inside a namespace.\n  ##\n');
%! fprintf (fid, '  ## @end deftp\n  properties\n');
%! fprintf (fid, '    ## -*- texinfo -*-\n');
%! fprintf (fid, '    ## @deftp {ck.CkClass} {property} Prop\n    ##\n');
%! fprintf (fid, '    ## A property of the namespaced class.\n');
%! fprintf (fid, '    ##\n    ## @end deftp\n    Prop = 1\n');
%! fprintf (fid, '  endproperties\nendclassdef\n');
%! fclose (fid);
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   [~, rep] = check_texi_docs ();
%!   inclass = strcmp ({rep.file}, fullfile ('+ck', 'CkClass.m'));
%!   assert (! any (inclass));
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # src is passed over, and the tree is left exactly as it was found
%! d = fullfile (tempdir (), 'pkg_octave_doc_ck_bist');
%! fid = fopen (fullfile (d, 'src', 'ckbroken.m'), 'w');
%! fprintf (fid, '## -*- texinfo -*-\n## @deftypefn {nosuch} {} ckbroken ()\n');
%! fprintf (fid, '##\n## @itemize\n##\n## @end deftypefn\n');
%! fclose (fid);
%! old = pwd ();
%! unwind_protect
%!   cd (d);
%!   before = dir (d);
%!   [~, rep] = check_texi_docs ();
%!   assert (! any (strcmp ({rep.file}, fullfile ('src', 'ckbroken.m'))));
%!   assert (numel (dir (d)), numel (before));
%! unwind_protect_cleanup
%!   cd (old);
%! end_unwind_protect

%!test  # remove the fixture tree
%! d = fullfile (tempdir (), 'pkg_octave_doc_ck_bist');
%! confirm_recursive_rmdir (false, 'local');
%! rmdir (d, 's');
%! assert (! isfolder (d));

## Test input validation
%!error<check_texi_docs: OPTIONS must be a pkg_doc_options object.> ...
%! check_texi_docs ('-auto')
