## fcns = collect_docstrings (directory, options)
##
## Collect documentation strings from all functions in a given directory.
##
## The following options with their default values are supported.
##
##   options.max_recursion_depth = inf;  # "0" means no recusion
##   options.ignore_errors = false;
##   options.document_private_functions = false;

function fcns = collect_docstrings (directory, options)

  if (! ischar (directory))
    print_usage ();
  endif

  if (nargin == 1)
    options.max_recursion_depth = inf;
    options.ignore_errors = false;
    options.document_private_functions = false;
  endif
  options = validate_options (options);

  fcns = collect_docstrings_recursive (directory, 0, options);

endfunction


function fcns = collect_docstrings_recursive (directory, recursion_depth, options)

  relative_path = strsplit (directory, filesep ());
  relative_path = strjoin (relative_path(end+(1-recursion_depth):end), ...
    filesep ());

  [items, err, msg] = readdir (directory);
  if (err)
    error ("couldn't read directory %s: %s", dir, msg);
  endif
  items(strcmp (items, ".") | strcmp (items, "..")) = [];

  if (options.document_private_functions)
    recurse_into_directory = @(x) true;
  else
    recurse_into_directory = @(x) ! strcmp (x, "private");
  end

  fcns = {};
  for i = 1:length (items)
    try
      absolute_item_path = strjoin ({directory, items{i}}, filesep ());
      if (recursion_depth)
        relative_item_path = strjoin ({relative_path, items{i}}, filesep ());
      else
        relative_item_path = items{i};
      endif

      if (isfile (absolute_item_path))
        [~, fname, ext] = fileparts (relative_item_path);
        fcn.name = fname;
        fcn.relative_path = relative_item_path;
        if (strcmp (ext, ".m"))
          fcn.help_str = help (absolute_item_path);
          fcns = [fcns, fcn];
        elseif (strcmp (ext, ".oct") || strcmp (ext, [".", mexext()]));
          old_dir = cd (directory);
          unwind_protect
            fcn.help_str = help (fname);
            fcns = [fcns, fcn];
          unwind_protect_cleanup
            cd (old_dir);
          end_unwind_protect
        else
          warning ("Ignore file '%s'.\n", relative_item_path);
        endif
      elseif (isfolder (absolute_item_path))
        if (recurse_into_directory (items{i}) ...
          && (recursion_depth < options.max_recursion_depth))
          fcns_r = collect_docstrings_recursive (absolute_item_path, ...
            recursion_depth + 1, options);
          fcns = [fcns, fcns_r];
        else
          warning ("Ignore folder '%s'.\n", relative_item_path);
        endif
      else
        warning ("Ignore entry '%s'.\n", relative_item_path);
      endif
    catch err
      if (options.ignore_errors)
        warning ("Ignore error '%s'.\n", err.message);
      else
        rethrow (err);
      endif
    end_try_catch
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
      error ("options.max_recursion_depth must be a non-negative integer");
    endif
  else
    options.max_recursion_depth = inf;
  endif
endfunction


%!error<must be a struct> collect_docstrings ("dir", "invalid");
%!error<Allowed option fieldnames are> collect_docstrings ("dir", ...
%!  struct ("invalid", true));
%!error<must be a logical value> collect_docstrings ("dir", ...
%!  struct ("ignore_errors", 4));
%!error<must be a non-negative integer> collect_docstrings ("dir", ...
%!  struct ("max_recursion_depth", true));

%!test
%! options.ignore_errors = false;
%! options.document_private_functions = true;
%! directory = "/home/siko1056/.local/share/octave/7.3.0/io-2.6.4";
%! fcns = collect_docstrings (directory, options);

