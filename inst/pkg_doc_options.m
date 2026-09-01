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

classdef pkg_doc_options
  ## -*- texinfo -*-
  ## @deftp {pkg-octave-doc} pkg_doc_options
  ##
  ## Settings for the documentation builders of a package.
  ##
  ## A @code{pkg_doc_options} object carries the location of a package's
  ## @file{INDEX} file, how much a run prints, and the severity of each rule the
  ## documentation builders check a docstring against.  Every property is
  ## public, so the object is itself the list of what a maintainer may
  ## configure, and each carries its own help text describing what it controls.
  ##
  ## @code{@var{opts} = pkg_doc_options ()} returns an object holding the
  ## default settings.  @code{@var{opts} = pkg_doc_options (@var{filename})}
  ## reads a JSON file over those defaults, taking a bare name in the current
  ## directory or an absolute path anywhere.  Anything in it this release
  ## cannot use, whether a key that is not a property or a value a property
  ## will not take, is reported and passed over, and the rest of the file is
  ## read: a settings file outlives the release that wrote it, and one written
  ## for a later release must not stop a documentation build under an earlier
  ## one.
  ##
  ## It is a value class, so an assignment returns a modified copy:
  ##
  ## @example
  ## @group
  ## opts = pkg_doc_options ();
  ## opts.BodyColumns = 80;
  ## opts.SeealsoInMember = 'error';
  ## @end group
  ## @end example
  ##
  ## @code{save_to_json} writes the settings back, storing only the properties
  ## that differ from the defaults, so a rule added in a later release cannot be
  ## pinned to an old value by a file already written.
  ##
  ## A severity is @qcode{'error'}, @qcode{'warning'} or @qcode{'off'}.  It says
  ## how a finding is reported and never whether a run continues: a docstring
  ## defect is reported, counted and returned, and the run goes on.
  ##
  ## @seealso{package_texi2cache, folder_texi2cache, classdef_texi2cache,
  ## function_texi2cache}
  ## @end deftp

  properties

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} WrappedHeader
    ##
    ## A @code{@@deftypefn} header wrapped across lines
    ##
    ## Severity of a @code{@@deftypefn} or @code{@@deftypefnx} header broken
    ## across two or more lines, which @code{makeinfo} does not accept and which
    ## therefore breaks @code{help} for the whole docstring.  Defaults to
    ## @qcode{'error'}.
    ##
    ## @end deftp
    WrappedHeader = 'error'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} EndTrailingText
    ##
    ## Body text on an @code{@@end} line
    ##
    ## Severity of an @code{@@end} command carrying body text on the same line,
    ## as in @code{@@end itemize and more text}, which is not a valid closing
    ## command.  Defaults to @qcode{'error'}.
    ##
    ## @end deftp
    EndTrailingText = 'error'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} BareAt
    ##
    ## A literal @code{@@} that is neither doubled nor a command
    ##
    ## Severity of a literal @code{@@} that is neither doubled nor the start of
    ## a known texinfo command, as an anonymous function written inside
    ## @code{@@code} without doubling it.  Defaults to @qcode{'error'}.
    ##
    ## @end deftp
    BareAt = 'error'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} UnbalancedBrace
    ##
    ## A brace that never closes, or closes too often
    ##
    ## Severity of an unbalanced brace in a docstring, which swallows the text
    ## following it or ends a command early.  Defaults to @qcode{'error'}.
    ##
    ## @end deftp
    UnbalancedBrace = 'error'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} UnclosedBlock
    ##
    ## A block opened and never ended
    ##
    ## Severity of a block command, such as @code{@@itemize} or
    ## @code{@@example}, opened and never closed by a matching @code{@@end}.
    ## Defaults to @qcode{'error'}.
    ##
    ## @end deftp
    UnclosedBlock = 'error'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} CategoryLabel
    ##
    ## A category label naming no class in the package
    ##
    ## Severity of a category label that names no class in the package, or that
    ## is not an identifier at all, as a literal format specifier left in the
    ## text.  Defaults to @qcode{'warning'}.
    ##
    ## @end deftp
    CategoryLabel = 'warning'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} MissingDocstring
    ##
    ## A public member carrying no docstring
    ##
    ## Severity of a public function or class member with no help text, for
    ## which @code{help} answers that it is undocumented and which no cache
    ## entry can be built for.  Defaults to @qcode{'warning'}.
    ##
    ## @end deftp
    MissingDocstring = 'warning'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} BodyColumns
    ##
    ## Width limit of a docstring body line
    ##
    ## Width limit of a docstring body line, specified as a positive integer
    ## giving the column past which a line is reported, or as @qcode{'off'}, the
    ## default, which does not check the width at all.  A @code{@@deftypefn} or
    ## @code{@@deftypefnx} header is never measured, being allowed to run over.
    ##
    ## This is a house rule of the packages maintained alongside this one rather
    ## than a defect, which is why it is off unless a package asks for it.
    ##
    ## @end deftp
    BodyColumns = 'off'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} SeealsoInMember
    ##
    ## @code{@@seealso} in the help of a class member
    ##
    ## Severity of a @code{@@seealso} command in the help text of a class
    ## member.  Defaults to @qcode{'off'}, this being a house rule of the
    ## packages maintained alongside this one rather than a defect.
    ##
    ## @end deftp
    SeealsoInMember = 'off'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} IndexLocation
    ##
    ## Location of the package's @file{INDEX} file
    ##
    ## Location of the package's @file{INDEX} file, specified as a character
    ## vector holding an absolute path, as @qcode{''} to use no @file{INDEX}
    ## even where one exists, or as @code{[]}, the default, to leave it
    ## unspecified.
    ##
    ## The three states are distinct because @file{INDEX} decides what a whole
    ## scope caches: left unspecified, @code{package_texi2cache} reads the
    ## @file{INDEX} of the package root it is standing in, whereas @qcode{''}
    ## switches that off and caches whatever the tree holds.
    ##
    ## @end deftp
    IndexLocation = []

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} IndexMissingEntry
    ##
    ## A name in the tree absent from @file{INDEX}
    ##
    ## Severity of a documented name found in the tree but absent from the
    ## package's @file{INDEX}, which leaves it out of the published
    ## documentation and, where @file{INDEX} decides what is cached, out of the
    ## doc-cache as well.  Defaults to @qcode{'warning'}.
    ##
    ## @end deftp
    IndexMissingEntry = 'warning'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} IndexOrphanEntry
    ##
    ## An @file{INDEX} entry answering to no file
    ##
    ## Severity of an @file{INDEX} entry that answers to no file in the package,
    ## which is reported only by a run covering the whole package, a single
    ## directory being unable to tell such an entry from one naming a file
    ## elsewhere.  Defaults to @qcode{'warning'}.
    ##
    ## @end deftp
    IndexOrphanEntry = 'warning'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} IndexNotFound
    ##
    ## No @file{INDEX} where one was expected
    ##
    ## Severity of a run that reads @file{INDEX} finding none to read.
    ## Defaults to @qcode{'warning'}, and is the rule to switch off for a
    ## package that deliberately ships without an @file{INDEX}.
    ##
    ## @end deftp
    IndexNotFound = 'warning'

    ## -*- texinfo -*-
    ## @deftp {pkg_doc_options} {property} Verbosity
    ##
    ## How much a run prints
    ##
    ## How much a run prints, specified as @qcode{'all'}, the default, which
    ## prints every finding and then the summary; @qcode{'summary'}, which
    ## prints the summary alone; or @qcode{'none'}, which prints nothing.
    ##
    ## Findings are returned in the report at every setting, so @qcode{'none'}
    ## is for a programmatic caller rather than a way of hiding them.
    ##
    ## @end deftp
    Verbosity = 'all'

  endproperties

  methods (Access = public)

    ## -*- texinfo -*-
    ## @deftypefn  {pkg_doc_options} {@var{obj} =} pkg_doc_options ()
    ## @deftypefnx {pkg_doc_options} {@var{obj} =} pkg_doc_options (@var{filename})
    ##
    ## Create a settings object for the documentation builders.
    ##
    ## @code{@var{obj} = pkg_doc_options ()} returns an object holding the
    ## default settings.
    ##
    ## @code{@var{obj} = pkg_doc_options (@var{filename})} reads a JSON file
    ## over those defaults, taking a bare name in the current directory or an
    ## absolute path anywhere.  The file holds only the settings a package
    ## differs from the defaults in, which is what @code{save_to_json} writes.
    ## Anything the running release cannot use, a key that is not a property
    ## or a value a property will not take, is reported and passed over while
    ## the rest of the file is read.
    ##
    ## @end deftypefn
    function this = pkg_doc_options (filename)

      ## Input validation
      if (nargin == 0)
        return;
      endif
      if (! (ischar (filename) && isrow (filename)))
        error ("pkg_doc_options: FILENAME must be a character vector.");
      endif

      ## Read the file and decode it
      fid = fopen (filename, 'r');
      if (fid < 0)
        error ("pkg_doc_options: cannot read file '%s'.", filename);
      endif
      text = fread (fid, Inf, 'char=>char')';
      fclose (fid);
      try
        data = jsondecode (text);
      catch err
        error ("pkg_doc_options: '%s' is not valid JSON: %s", ...
               filename, err.message);
      end_try_catch
      if (isempty (data))
        return;
      endif
      if (! isstruct (data))
        error ("pkg_doc_options: '%s' must hold a JSON object.", filename);
      endif

      ## Assign what the file names.  A settings file outlives the release
      ## that wrote it, so neither a name this release does not know nor a
      ## value it cannot accept is fatal: the one is reported and passed over
      ## and the rest of the file is read, which is what lets a package carry
      ## one file for several releases of this one.
      known = properties (this);
      given = fieldnames (data);
      for ii = 1:numel (given)
        if (! any (strcmp (given{ii}, known)))
          warning (strcat ("pkg_doc_options: ignoring unknown setting", ...
                           " '%s' in '%s'."), given{ii}, filename);
          continue;
        endif
        try
          this.(given{ii}) = data.(given{ii});
        catch err
          warning (strcat ("pkg_doc_options: ignoring '%s' in '%s',", ...
                           " which this release cannot take: %s"), ...
                   given{ii}, filename, err.message);
        end_try_catch
      endfor

    endfunction

    ## -*- texinfo -*-
    ## @deftypefn {pkg_doc_options} {} save_to_json (@var{obj}, @var{filename})
    ##
    ## Save the settings that differ from the defaults to a JSON file.
    ##
    ## @code{save_to_json (@var{obj}, @var{filename})} writes the properties of
    ## @var{obj} that differ from the default settings to @var{filename}, taking
    ## a bare name in the current directory or an absolute path anywhere.  An
    ## object holding nothing but defaults writes an empty JSON object.
    ##
    ## Only the differences are stored, so a property added in a later release
    ## is not pinned to an old value by a file already written, and the file
    ## stays readable as a statement of what a package asks for.
    ##
    ## @end deftypefn
    function save_to_json (this, filename)

      ## Input validation
      if (nargin != 2)
        error (strcat ("pkg_doc_options.save_to_json: invalid number of", ...
                       " input arguments."));
      endif
      if (! (ischar (filename) && isrow (filename)))
        error (strcat ("pkg_doc_options.save_to_json: FILENAME must be", ...
                       " a character vector."));
      endif

      ## Encode the differences one field at a time, so that the file stays
      ## readable without relying on the 'PrettyPrint' option, which is absent
      ## from some builds of Octave
      diff = differences (this);
      names = fieldnames (diff);
      if (isempty (names))
        text = '{}';
      else
        parts = cell (numel (names), 1);
        for ii = 1:numel (names)
          parts{ii} = sprintf ('  %s: %s', jsonencode (names{ii}), ...
                               jsonencode (diff.(names{ii})));
        endfor
        text = sprintf ("{\n%s\n}", strjoin (parts, ",\n"));
      endif
      tmp = sprintf ('%s.%d.tmp', filename, getpid ());
      fid = fopen (tmp, 'w');
      if (fid < 0)
        error ("pkg_doc_options.save_to_json: cannot write file '%s'.", tmp);
      endif
      fputs (fid, [text "\n"]);
      fclose (fid);
      [err, msg] = rename (tmp, filename);
      if (err)
        unlink (tmp);
        error ("pkg_doc_options.save_to_json: cannot write file '%s': %s", ...
               filename, msg);
      endif

    endfunction

  endmethods

  methods (Access = private)

    ## Properties that differ from the defaults
    function out = differences (this)
      dflt = pkg_doc_options ();
      names = properties (this);
      out = struct ();
      for ii = 1:numel (names)
        if (! isequal (this.(names{ii}), dflt.(names{ii})))
          out.(names{ii}) = this.(names{ii});
        endif
      endfor
    endfunction

  endmethods

  methods (Hidden)

    ## Custom display
    function display (this)
      in_name = inputname (1);
      if (! isempty (in_name))
        fprintf ('%s =\n', in_name);
      endif
      __print__ (this);
    endfunction

    ## Custom display
    function disp (this)
      __print__ (this);
    endfunction

  endmethods

  methods (Access = private, Hidden)

    ## Print the settings, grouped, marking what differs from the defaults
    function __print__ (this)
      groups = {'Structural rules', {'WrappedHeader', 'EndTrailingText', ...
                                     'BareAt', 'UnbalancedBrace', ...
                                     'UnclosedBlock'}; ...
                'Convention rules', {'CategoryLabel', 'MissingDocstring', ...
                                     'BodyColumns', 'SeealsoInMember'}; ...
                'INDEX rules', {'IndexLocation', 'IndexMissingEntry', ...
                                'IndexOrphanEntry', 'IndexNotFound'}; ...
                'Output', {'Verbosity'}};
      changed = fieldnames (differences (this));

      ## A severity fits the value column and a path does not, so a value too
      ## wide for it takes a line of its own underneath rather than pushing
      ## every other row across or being cut short
      width = 13;
      fmt = sprintf ('    %%s %%-18s %%-%ds %%s\n', width);

      fprintf ('\n  pkg_doc_options\n');
      for ii = 1:rows (groups)
        fprintf ('\n    %s\n', groups{ii, 1});
        names = groups{ii, 2};
        for jj = 1:numel (names)
          if (any (strcmp (names{jj}, changed)))
            mark = '*';
          else
            mark = ' ';
          endif
          val = valueString (this.(names{jj}));
          if (numel (val) > width)
            fprintf (fmt, mark, names{jj}, '', summaryOf (names{jj}));
            fprintf ('    %s %-18s %s\n', ' ', '', val);
          else
            fprintf (fmt, mark, names{jj}, val, summaryOf (names{jj}));
          endif
        endfor
      endfor
      if (isempty (changed))
        fprintf ('\n  All settings are at their defaults.\n\n');
      else
        fprintf ('\n  * differs from the default.\n\n');
      endif
    endfunction

  endmethods

  methods (Access = public, Hidden)

    ## Validate on assignment
    function this = set.IndexLocation (this, val)
      if (! (isempty (val) && isnumeric (val)) ...
          && ! (ischar (val) && (isrow (val) || isempty (val))))
        error (strcat ("pkg_doc_options: INDEXLOCATION must be a", ...
                       " character vector or an empty matrix."));
      endif
      this.IndexLocation = val;
    endfunction

    function this = set.Verbosity (this, val)
      if (! (ischar (val) && isrow (val)) ...
          || ! any (strcmp (val, {'all', 'summary', 'none'})))
        error (strcat ("pkg_doc_options: VERBOSITY must be 'all',", ...
                       " 'summary', or 'none'."));
      endif
      this.Verbosity = val;
    endfunction

    function this = set.WrappedHeader (this, val)
      this.WrappedHeader = checkSeverity (val, 'WRAPPEDHEADER');
    endfunction

    function this = set.EndTrailingText (this, val)
      this.EndTrailingText = checkSeverity (val, 'ENDTRAILINGTEXT');
    endfunction

    function this = set.BareAt (this, val)
      this.BareAt = checkSeverity (val, 'BAREAT');
    endfunction

    function this = set.UnbalancedBrace (this, val)
      this.UnbalancedBrace = checkSeverity (val, 'UNBALANCEDBRACE');
    endfunction

    function this = set.UnclosedBlock (this, val)
      this.UnclosedBlock = checkSeverity (val, 'UNCLOSEDBLOCK');
    endfunction

    function this = set.CategoryLabel (this, val)
      this.CategoryLabel = checkSeverity (val, 'CATEGORYLABEL');
    endfunction

    function this = set.MissingDocstring (this, val)
      this.MissingDocstring = checkSeverity (val, 'MISSINGDOCSTRING');
    endfunction

    function this = set.SeealsoInMember (this, val)
      this.SeealsoInMember = checkSeverity (val, 'SEEALSOINMEMBER');
    endfunction

    function this = set.IndexMissingEntry (this, val)
      this.IndexMissingEntry = checkSeverity (val, 'INDEXMISSINGENTRY');
    endfunction

    function this = set.IndexOrphanEntry (this, val)
      this.IndexOrphanEntry = checkSeverity (val, 'INDEXORPHANENTRY');
    endfunction

    function this = set.IndexNotFound (this, val)
      this.IndexNotFound = checkSeverity (val, 'INDEXNOTFOUND');
    endfunction

    function this = set.BodyColumns (this, val)
      if (ischar (val) && isrow (val))
        if (! strcmp (val, 'off'))
          error (strcat ("pkg_doc_options: BODYCOLUMNS must be 'off' or a", ...
                         " positive integer."));
        endif
      elseif (! (isnumeric (val) && isscalar (val) && isreal (val) ...
                 && val > 0 && val == fix (val)))
        error (strcat ("pkg_doc_options: BODYCOLUMNS must be 'off' or a", ...
                       " positive integer."));
      endif
      this.BodyColumns = val;
    endfunction

  endmethods

endclassdef

## Validate a severity, which every rule but BodyColumns takes
function val = checkSeverity (val, name)
  if (! (ischar (val) && isrow (val)) ...
      || ! any (strcmp (val, {'error', 'warning', 'off'})))
    error (strcat ("pkg_doc_options: %s must be 'error', 'warning',", ...
                   " or 'off'."), name);
  endif
endfunction

## What a property controls, in the width a column allows.  The help text of
## each property says the same thing at length, and is where a reader is sent
## for the detail this cannot carry.
function str = summaryOf (name)
  switch (name)
    case 'IndexLocation'
      str = "path to the package's INDEX";
    case 'Verbosity'
      str = 'how much a run prints';
    case 'WrappedHeader'
      str = 'a header broken across lines';
    case 'EndTrailingText'
      str = 'text after @end on its line';
    case 'BareAt'
      str = 'an @ that is not a command';
    case 'UnbalancedBrace'
      str = 'a brace that never closes';
    case 'UnclosedBlock'
      str = 'a block with no @end';
    case 'CategoryLabel'
      str = 'a label naming no class or package';
    case 'MissingDocstring'
      str = 'a public member with no help';
    case 'BodyColumns'
      str = 'width limit of a body line';
    case 'SeealsoInMember'
      str = '@seealso on a class member';
    case 'IndexMissingEntry'
      str = 'a name absent from INDEX';
    case 'IndexOrphanEntry'
      str = 'an INDEX entry with no file';
    case 'IndexNotFound'
      str = 'no INDEX where one was expected';
    otherwise
      str = '';
  endswitch
endfunction

## Render a property value for display
function str = valueString (val)
  if (isnumeric (val) && isempty (val))
    str = '<unspecified>';
  elseif (ischar (val) && isempty (val))
    str = "'' (none)";
  elseif (ischar (val))
    str = sprintf ("'%s'", val);
  else
    str = sprintf ('%d', val);
  endif
endfunction

## The file cases write into a temporary directory rather than the current one,
## which is the package tree while the suite runs, and the last block removes
## it.  The hidden disp/display pair carries no test of its own.

%!test  # defaults
%! o = pkg_doc_options ();
%! assert (isa (o, 'pkg_doc_options'));
%! assert (isempty (o.IndexLocation) && isnumeric (o.IndexLocation));
%! assert (o.Verbosity, 'all');
%! assert (o.WrappedHeader, 'error');
%! assert (o.CategoryLabel, 'warning');
%! assert (o.BodyColumns, 'off');
%! assert (o.SeealsoInMember, 'off');
%! assert (o.IndexNotFound, 'warning');

%!test  # every rule is a property, and there are twelve of them
%! o = pkg_doc_options ();
%! p = properties (o);
%! assert (numel (p), 14);
%! rules = {'WrappedHeader', 'EndTrailingText', 'BareAt', 'UnbalancedBrace', ...
%!          'UnclosedBlock', 'CategoryLabel', 'MissingDocstring', ...
%!          'BodyColumns', 'SeealsoInMember', 'IndexMissingEntry', ...
%!          'IndexOrphanEntry', 'IndexNotFound'};
%! assert (all (ismember (rules, p)));

%!test  # a value class, so an assignment leaves the original alone
%! o = pkg_doc_options ();
%! p = o;
%! p.BodyColumns = 100;
%! assert (o.BodyColumns, 'off');
%! assert (p.BodyColumns, 100);

%!test  # the three states of IndexLocation are distinct
%! o = pkg_doc_options ();
%! assert (isnumeric (o.IndexLocation) && isempty (o.IndexLocation));
%! o.IndexLocation = '';
%! assert (ischar (o.IndexLocation) && isempty (o.IndexLocation));
%! o.IndexLocation = '/tmp/INDEX';
%! assert (o.IndexLocation, '/tmp/INDEX');

%!test  # BodyColumns takes a positive integer or 'off'
%! o = pkg_doc_options ();
%! o.BodyColumns = 80;
%! assert (o.BodyColumns, 80);
%! o.BodyColumns = 'off';
%! assert (o.BodyColumns, 'off');

%!test  # a file holds only what differs from the defaults
%! d = fullfile (tempdir (), 'pkg_octave_doc_opt_bist');
%! if (! isfolder (d))
%!   mkdir (d);
%! endif
%! f = fullfile (d, 'diff.json');
%! o = pkg_doc_options ();
%! o.BodyColumns = 80;
%! o.SeealsoInMember = 'error';
%! save_to_json (o, f);
%! text = fileread (f);
%! assert (! isempty (strfind (text, 'BodyColumns')));
%! assert (! isempty (strfind (text, 'SeealsoInMember')));
%! assert (isempty (strfind (text, 'Verbosity')));
%! assert (isempty (strfind (text, 'WrappedHeader')));

%!test  # what is written comes back identical
%! d = fullfile (tempdir (), 'pkg_octave_doc_opt_bist');
%! f = fullfile (d, 'trip.json');
%! o = pkg_doc_options ();
%! o.IndexLocation = '/pkg/INDEX';
%! o.Verbosity = 'summary';
%! o.BodyColumns = 72;
%! save_to_json (o, f);
%! assert (isequal (pkg_doc_options (f), o));

%!test  # an object holding nothing but defaults writes an empty JSON object
%! d = fullfile (tempdir (), 'pkg_octave_doc_opt_bist');
%! f = fullfile (d, 'empty.json');
%! o = pkg_doc_options ();
%! save_to_json (o, f);
%! assert (strtrim (fileread (f)), '{}');
%! assert (isequal (pkg_doc_options (f), o));

%!test  # a file written for another release is read for what it can be
%! d = fullfile (tempdir (), 'pkg_octave_doc_opt_bist');
%! if (! isfolder (d))
%!   mkdir (d);
%! endif
%! f = fullfile (d, 'future.json');
%! fid = fopen (f, 'w');
%! fputs (fid, '{"FutureRule": "error", "BodyColumns": [80, "error"], ');
%! fputs (fid, '"Verbosity": "verbose", "SeealsoInMember": "warning"}');
%! fclose (fid);
%! warning ('off', 'all');
%! unwind_protect
%!   o = pkg_doc_options (f);
%! unwind_protect_cleanup
%!   warning ('on', 'all');
%! end_unwind_protect
%! assert (o.SeealsoInMember, 'warning');
%! assert (o.BodyColumns, 'off');
%! assert (o.Verbosity, 'all');

%!test  # a setting that is no longer a property is reported and ignored
%! d = fullfile (tempdir (), 'pkg_octave_doc_opt_bist');
%! f = fullfile (d, 'stale.json');
%! fid = fopen (f, 'w');
%! fputs (fid, '{"OldRule": "error", "BodyColumns": 72}');
%! fclose (fid);
%! warning ('off', 'all');
%! unwind_protect
%!   o = pkg_doc_options (f);
%! unwind_protect_cleanup
%!   warning ('on', 'all');
%! end_unwind_protect
%! assert (o.BodyColumns, 72);

%!warning<pkg_doc_options: ignoring unknown setting 'OldRule' in>
%! d = fullfile (tempdir (), 'pkg_octave_doc_opt_bist');
%! f = fullfile (d, 'stale.json');
%! o = pkg_doc_options (f);

%!test  # remove the fixture directory
%! d = fullfile (tempdir (), 'pkg_octave_doc_opt_bist');
%! delete (fullfile (d, '*.json'));
%! rmdir (d);
%! assert (! isfolder (d));

## Test input validation
%!error<pkg_doc_options: FILENAME must be a character vector.> ...
%! pkg_doc_options (5)
%!error<pkg_doc_options: FILENAME must be a character vector.> ...
%! pkg_doc_options ({'a.json'})
%!error<pkg_doc_options: cannot read file 'no_such_file_here.json'.> ...
%! pkg_doc_options ('no_such_file_here.json')
%!error<pkg_doc_options: INDEXLOCATION must be a character vector or an empty matrix.> ...
%! o = pkg_doc_options (); o.IndexLocation = 5;
%!error<pkg_doc_options: VERBOSITY must be 'all', 'summary', or 'none'.> ...
%! o = pkg_doc_options (); o.Verbosity = 'loud';
%!error<pkg_doc_options: VERBOSITY must be 'all', 'summary', or 'none'.> ...
%! o = pkg_doc_options (); o.Verbosity = 5;
%!error<pkg_doc_options: WRAPPEDHEADER must be 'error', 'warning', or 'off'.> ...
%! o = pkg_doc_options (); o.WrappedHeader = 'fatal';
%!error<pkg_doc_options: CATEGORYLABEL must be 'error', 'warning', or 'off'.> ...
%! o = pkg_doc_options (); o.CategoryLabel = 2;
%!error<pkg_doc_options: INDEXNOTFOUND must be 'error', 'warning', or 'off'.> ...
%! o = pkg_doc_options (); o.IndexNotFound = 'quiet';
%!error<pkg_doc_options: BODYCOLUMNS must be 'off' or a positive integer.> ...
%! o = pkg_doc_options (); o.BodyColumns = 'on';
%!error<pkg_doc_options: BODYCOLUMNS must be 'off' or a positive integer.> ...
%! o = pkg_doc_options (); o.BodyColumns = 0;
%!error<pkg_doc_options: BODYCOLUMNS must be 'off' or a positive integer.> ...
%! o = pkg_doc_options (); o.BodyColumns = 79.5;
%!error<pkg_doc_options.save_to_json: invalid number of input arguments.> ...
%! o = pkg_doc_options (); save_to_json (o);
%!error<pkg_doc_options.save_to_json: FILENAME must be a character vector.> ...
%! o = pkg_doc_options (); save_to_json (o, 5);
