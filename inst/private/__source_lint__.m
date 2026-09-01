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
## @deftypefn {pkg-octave-doc} {@var{findings} =} __source_lint__ (@var{srclines}, @var{opts}, @var{ctx})
##
## Private function reporting the convention defects of a documented item.
##
## These are the rules a renderer cannot check, because it is handed text
## while they are about the file: how wide a source line is, what a category
## label names, and whether an item is documented at all.  The caller passes
## the source it has already read, so nothing is opened twice.
##
## @var{srclines} is a cell array holding the lines of the item's help text
## @strong{as they appear in the file}, comment markers and indentation
## included, since the width rule measures the file rather than the text the
## renderer receives.  It is empty when the item carries no help at all.
##
## @var{opts} is a @code{pkg_doc_options} object.  @var{ctx} describes what is
## being checked, with the fields @qcode{'package'}, the package's name;
## @qcode{'class'}, the class owning the item, empty for a plain function; and
## @qcode{'member'}, the member's name, empty when the block documents the
## class itself or a plain function.
##
## @var{findings} is a struct array of the same shape @code{__texi_lint__}
## returns, carrying @qcode{'rule'}, @qcode{'severity'}, @qcode{'line'},
## counted from the first line of @var{srclines}, and @qcode{'message'}.
##
## @end deftypefn

function findings = __source_lint__ (srclines, opts, ctx)

  ## Input validation
  if (nargin != 3)
    error ("__source_lint__: invalid number of input arguments.");
  endif
  if (! iscellstr (srclines))
    error ("__source_lint__: SRCLINES must be a cell array of strings.");
  endif
  if (! isa (opts, 'pkg_doc_options'))
    error ("__source_lint__: OPTS must be a pkg_doc_options object.");
  endif
  if (! isstruct (ctx) || ! all (isfield (ctx, {'package', 'class', 'member'})))
    error (strcat ("__source_lint__: CTX must be a struct with the fields", ...
                   " 'package', 'class', and 'member'."));
  endif

  findings = struct ('rule', {}, 'severity', {}, 'line', {}, 'message', {});

  ## An item with no help at all, which help itself reports as undocumented
  ## and which no cache entry can be built for
  if (isempty (srclines))
    if (! strcmp (opts.MissingDocstring, 'off'))
      findings(end+1) = newFinding ('MissingDocstring', ...
                        opts.MissingDocstring, 1, ...
                        'the item carries no help text');
    endif
    return;
  endif

  ## A label names either the class owning the item or the package itself,
  ## and nothing else.  A class documents itself under the package's name and
  ## its members under its own, which is what the two allowances are.
  ## With no package name to compare against, the rule cannot know what a
  ## label ought to be, so it stands down rather than guess
  allowed = {};
  if (! isempty (ctx.package))
    allowed{end+1} = ctx.package;
    if (! isempty (ctx.class))
      ## A class inside a namespace is documented under either spelling, the
      ## qualified one that help takes or the bare one the file is named for,
      ## and the class itself under whatever contains it, which is the
      ## namespace where there is one and the package where there is not
      allowed{end+1} = ctx.class;
      parts = strsplit (ctx.class, '.');
      if (numel (parts) > 1)
        allowed{end+1} = parts{end};
        allowed{end+1} = strjoin (parts(1:end-1), '.');
      endif
    endif
  endif

  ## A category label is checked because it reaches a reader on a published
  ## page.  A private helper has no page, and packages label theirs by their
  ## own conventions, so there is nothing there for the rule to protect.
  published = ! isfield (ctx, 'published') || ctx.published;

  isHeader = false (1, numel (srclines));
  for ii = 1:numel (srclines)
    ln = srclines{ii};

    tok = regexp (ln, '^\s*##\s*@def(?:typefnx?|tpx?)\s*\{([^}]*)\}', ...
                  'tokens', 'once');
    if (! isempty (tok))
      isHeader(ii) = true;
      if (! strcmp (opts.CategoryLabel, 'off') && ! isempty (allowed) ...
          && published)
        lab = strtrim (tok{1});
        if (! any (strcmp (lab, allowed)))
          msg = sprintf (strcat ("the category label '%s' names neither", ...
                                 " the class nor the package"), lab);
          findings(end+1) = newFinding ('CategoryLabel', ...
                            opts.CategoryLabel, ii, msg);
        endif
      endif
    elseif (! isempty (regexp (ln, '^\s*##\s*@def(?:typefnx?|tpx?)\s', 'once')))
      isHeader(ii) = true;
    endif

    ## @seealso belongs on a function or on a class, never on a member
    if (! isempty (ctx.member) && ! strcmp (opts.SeealsoInMember, 'off'))
      if (! isempty (regexp (ln, '^\s*##\s*@seealso\b', 'once')))
        findings(end+1) = newFinding ('SeealsoInMember', ...
                          opts.SeealsoInMember, ii, ...
                          '@seealso is in the help text of a class member');
      endif
    endif
  endfor

  ## Width, which a signature is allowed to exceed and a body line is not
  if (! ischar (opts.BodyColumns))
    over = find (cellfun (@numel, srclines) > opts.BodyColumns & ! isHeader);
    for ii = 1:numel (over)
      msg = sprintf ('the line is %d columns wide, past %d', ...
                     numel (srclines{over(ii)}), opts.BodyColumns);
      findings(end+1) = newFinding ('BodyColumns', 'warning', over(ii), msg);
    endfor
  endif

  ## Report in the order the defects appear
  if (! isempty (findings))
    [~, idx] = sort ([findings.line]);
    findings = findings(idx);
  endif

endfunction

## Build one finding
function out = newFinding (rule, severity, line, message)
  out = struct ('rule', rule, 'severity', severity, 'line', line, ...
                'message', message);
endfunction
