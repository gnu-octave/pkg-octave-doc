# octave-doc package

Generate HTML web page from help texts.

This package provides functions for generating HTML pages that contain the help
texts for a set of functions.

The package is designed to be as general as possible, but also contains
convenience functions for generating a set of pages for entire packages.

The GNU Octave function reference can be created using
```
generate_html_manual ("/path/to/octave", "htdocs", ...
                      get_html_options ("octave-forge"));
```

This is a fork of the
[generate_html](https://gnu-octave.github.io/packages/generate_html)
package.
