## fcns = collect_docstrings (directory, options)
##
## Collect documentation strings from all functions in a given directory.
##
## The following options with their default values are supported.
##
##   options.max_recursion_depth = inf;  # "0" means no recusion
##   options.ignore_errors = false;
##   options.document_private_functions = false;

function fcns = write_docstrings (list, options)

  if (! iscell (list))
    print_usage ();
  endif

  for i = 1:length (list)
    list{i}.name
    list{i}.relative_path;
    list{i}.help_str;
  endfor

endfunction


function options = validate_options (options)
  if (! isstruct (options))
    error ("options must be a struct");
  endif
  valid_fieldnames = {"max_recursion_depth", "ignore_errors", ...
    "document_private_functions"};
  if (any (! ismember (fieldnames (options), valid_fieldnames)))
    error ("Allowed option fieldnames are: %s", ...
      strjoin (valid_fieldnames, ", "));
  endif
  if (isfield (options, "ignore_errors"))
    if (! islogical (options.ignore_errors))
      error ("options.ignore_errors must be a logical value");
    endif
  else
    options.ignore_errors = false;
  endif
  if (isfield (options, "document_private_functions"))
    if (! islogical (options.document_private_functions))
      error ("options.document_private_functions must be a logical value");
    endif
  else
    options.document_private_functions = false;
  endif
  if (isfield (options, "max_recursion_depth"))
    if (! (isscalar (options.max_recursion_depth) ...
      && isnumeric (options.max_recursion_depth) ...
      && (options.max_recursion_depth >= 0)))
      error ("options.max_recursion_depth must be a logical value");
    endif
  else
    options.max_recursion_depth = inf;
  endif
endfunction


%!test
%! options.ignore_errors = false;
%! options.document_private_functions = false;
%! directory = "/home/siko1056/.local/share/octave/7.3.0/io-2.6.4";
%! write_docstrings (collect_docstrings (directory, options));

