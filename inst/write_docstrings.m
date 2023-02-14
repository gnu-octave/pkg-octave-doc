## write_docstrings (list, options)
##
## Write documentation strings to a given output directory.
##
## The following options with their default values are supported.
##
##   options.output_directory = "build";

function write_docstrings (list, options)

  if (! iscell (list))
    print_usage ();
  endif

  if (nargin == 1)
    options.output_directory = "build";
  endif
  options = validate_options (options);

  ## Ensure empty output directory.
  if (exist (options.output_directory, "dir"))
    confirm_recursive_rmdir (false, "local");
    [successful, msg] = rmdir (options.output_directory, "s");
    if (! successful)
      error (msg);
    endif
  endif
  [successful, msg] = mkdir (options.output_directory);
  if (! successful)
    error (msg);
  endif

  ## Load templates
  default_template = fileread (fullfile ("_layouts", "default.html"));

  for i = 1:length (list)
    % list{i}.relative_path;

    output_str = default_template;
    output_str = strrep (output_str, "{{TITLE}}", list{i}.name);
    output_str = strrep (output_str, "{{BODY}}", ...
      ["<h1>", list{i}.name, "</h1>", ...
      "<pre>", list{i}.help_str, "</pre>"]);

    output_file = fullfile (options.output_directory, [list{i}.name, ".html"]);
    fp = fopen (output_file, "w");
    fprintf (fp, "%s", output_str);
    fclose (fp);
  endfor

endfunction


function options = validate_options (options)
  if (! isstruct (options))
    error ("options must be a struct");
  endif
  valid_fieldnames = {"output_directory"};
  if (any (! ismember (fieldnames (options), valid_fieldnames)))
    error ("Allowed option fieldnames are: %s", ...
      strjoin (valid_fieldnames, ", "));
  endif
  if (isfield (options, "output_directory"))
    if (! ischar (options.output_directory))
      error ("options.output_directory must be a string");
    endif
  else
    options.output_directory = "build";
  endif
endfunction


%!test
%! options.ignore_errors = false;
%! options.document_private_functions = false;
#%! directory = "/home/siko1056/.local/share/octave/7.3.0/io-2.6.4";
#%! opts.output_directory = "build";
#%! write_docstrings (collect_docstrings (directory, options), opts);

