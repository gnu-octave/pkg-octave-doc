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
## @deftypefn {pkg-octave-doc} {@var{findings} =} __texi_lint__ (@var{text}, @var{opts})
##
## Private function reporting the structural defects of a texinfo help text.
##
## @var{text} is the texinfo help text of a function or class member, as
## @code{__texi2html__} receives it, and @var{opts} is a
## @code{pkg_doc_options} object whose properties give each rule its severity.
## A rule set to @qcode{'off'} is not checked.
##
## @var{findings} is a struct array, empty when nothing is found, carrying the
## fields @qcode{'rule'}, the property naming the rule; @qcode{'severity'};
## @qcode{'line'}, counted from the first line of @var{text}, which the caller
## maps back to a line of the file it read; and @qcode{'message'}.
##
## The five rules are the defects that a texinfo renderer cannot recover from
## and that @code{makeinfo} refuses outright, so @code{help} is already broken
## for a docstring carrying one.  They are checked here rather than inside
## @code{__texi2html__} so that the rendering path is not touched at all.
##
## @end deftypefn

function findings = __texi_lint__ (text, opts)

  ## Input validation
  if (nargin < 1 || nargin > 2)
    error ("__texi_lint__: invalid number of input arguments.");
  endif
  if (! (ischar (text) && (isrow (text) || isempty (text))))
    error ("__texi_lint__: TEXT must be a character vector.");
  endif
  if (nargin < 2)
    opts = pkg_doc_options ();
  elseif (! isa (opts, 'pkg_doc_options'))
    error ("__texi_lint__: OPTS must be a pkg_doc_options object.");
  endif

  findings = struct ('rule', {}, 'severity', {}, 'line', {}, 'message', {});
  if (isempty (text))
    return;
  endif

  ## Work on the text as the renderer receives it, keeping the line numbering
  ## of what was passed in.  Everything below runs over the whole text rather
  ## than line by line: a per-line loop costs more than every rule put
  ## together, and this is on by default for all three documentation routes.
  text = strrep (text, "\r\n", "\n");
  nl = find (text == "\n");
  lineStart = [1, nl + 1];
  nlines = numel (lineStart);

  ## Commands opening a block that an @end must close.  @deftypefnx and
  ## @deftypeopx continue a signature rather than opening anything.
  blocks = {'cartouche', 'copying', 'defun', 'deftp', 'deftypefn', ...
            'deftypefun', 'detailmenu', 'display', 'enumerate', 'example', ...
            'flushleft', 'flushright', 'format', 'group', 'ifhtml', ...
            'ifnothtml', 'ifnottex', 'iftex', 'itemize', 'menu', ...
            'multitable', 'quotation', 'smallexample', 'table', 'tex', ...
            'verbatim', 'vtable'};

  ## Characters that are a whole command on their own, so that an @ before one
  ## is an escape rather than a defect.  A newline joins them: an @ ending a
  ## line continues a signature onto the next.
  singles = ['@{} :.!?*-/|,^`''"=~', "\n", "\t"];
  isSingle = false (1, 256);
  isSingle(double (singles)) = true;
  isCmdStart = false (1, 256);
  isCmdStart(double (['a':'z', 'A':'Z'])) = true;

  ## Every escape sequence, found once.  An @ opens one unless it is itself
  ## the second character of an escape, which can only happen inside a run of
  ## consecutive @, so the question is a parity within the run and needs no
  ## walk of the text.
  consumed = false (1, numel (text));
  bareAt = [];
  ats = find (text == '@');
  if (! isempty (ats))
    opensRun = [true, diff(ats) != 1];
    firstOfRun = ats(opensRun);
    within = ats - firstOfRun(cumsum (opensRun));
    starters = ats(mod (within, 2) == 0);
    consumed(starters) = true;
    follow = starters(starters < numel (text)) + 1;
    consumed(follow) = true;
    if (! strcmp (opts.BareAt, 'off'))
      nxt = double (text(follow));
      bareAt = follow(! isCmdStart(nxt) & ! isSingle(nxt)) - 1;
    endif
  endif

  for ii = 1:numel (bareAt)
    pp = bareAt(ii);
    msg = sprintf (strcat ("a literal '@' precedes '%s' and is neither", ...
                           " doubled nor a command"), text(pp+1));
    findings(end+1) = makeFinding ('BareAt', opts.BareAt, ...
                                   lookup (lineStart, pp), msg);
  endfor

  ## Braces, counting only those no escape consumed
  if (! strcmp (opts.UnbalancedBrace, 'off'))
    isOpen = (text == '{') & ! consumed;
    isClose = (text == '}') & ! consumed;
    depth = cumsum (isOpen - isClose);
    below = find (depth < 0, 1);
    if (! isempty (below))
      findings(end+1) = makeFinding ('UnbalancedBrace', ...
                        opts.UnbalancedBrace, lookup (lineStart, below), ...
                        'a closing brace matches no opening brace');
    elseif (! isempty (depth) && depth(end) > 0)
      findings(end+1) = makeFinding ('UnbalancedBrace', ...
                        opts.UnbalancedBrace, nlines, ...
                        'an opening brace is never closed');
    endif
  endif

  ## The line-oriented rules need only the lines that open with a command, and
  ## one match over the whole text finds them all
  [mstart, mtok] = regexp (text, '^[ \t]*@(\w+)([^\n]*)', 'start', 'tokens', ...
                           'lineanchors');
  open = struct ('name', {}, 'line', {});
  for ii = 1:numel (mstart)
    cmd = mtok{ii}{1};
    rest = mtok{ii}{2};
    ln = lookup (lineStart, mstart(ii));

    if (strcmp (cmd, 'end'))
      tok = regexp (rest, '^\s+(\w+)(.*)$', 'tokens', 'once');
      if (! isempty (tok))
        if (! isempty (strtrim (tok{2})) ...
            && ! strcmp (opts.EndTrailingText, 'off'))
          msg = sprintf ('text follows @end %s on the same line', tok{1});
          findings(end+1) = makeFinding ('EndTrailingText', ...
                            opts.EndTrailingText, ln, msg);
        endif
        idx = find (strcmp ({open.name}, tok{1}), 1, 'last');
        if (! isempty (idx))
          open(idx) = [];
        endif
      endif
      continue;
    endif

    if (any (strcmp (cmd, blocks)))
      open(end+1) = struct ('name', cmd, 'line', ln);
    endif

    ## A signature broken across lines, which makeinfo does not accept
    if (! strcmp (opts.WrappedHeader, 'off') ...
        && (strcmp (cmd, 'deftypefn') || strcmp (cmd, 'deftypefnx')))
      if (sum (rest == '(') > sum (rest == ')') ...
          && ! strcmp (strtrim (rest)(end), '@'))
        findings(end+1) = makeFinding ('WrappedHeader', ...
                          opts.WrappedHeader, ln, ...
                          'a @deftypefn header is broken across lines');
      endif
    endif

  endfor

  ## What is left open at the end of the text
  if (! strcmp (opts.UnclosedBlock, 'off'))
    for ii = 1:numel (open)
      findings(end+1) = makeFinding ('UnclosedBlock', opts.UnclosedBlock, ...
                        open(ii).line, ...
                        sprintf ('@%s is never closed by @end %s', ...
                                 open(ii).name, open(ii).name));
    endfor
  endif

  ## Report in the order the defects appear
  if (! isempty (findings))
    [~, idx] = sort ([findings.line]);
    findings = findings(idx);
  endif

endfunction

## Build one finding
function out = makeFinding (rule, severity, line, message)
  out = struct ('rule', rule, 'severity', severity, 'line', line, ...
                'message', message);
endfunction


