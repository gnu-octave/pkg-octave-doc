<img alt="octave-doc logo" width="100"
     src="https://raw.githubusercontent.com/gnu-octave/pkg-octave-doc/main/doc/icon.png">

# pkg-octave-doc

Create a **function reference** from Octave help texts (docstrings)
from single functions or all functions in a package, which can be installed
with **pkg**. The generated pages follow the template of the Octave Packages at
GitHub Pages based on bootstrap 5 and they have similar layout to the older
documentation reference pages at Source Forge.

You can find its documentation at [https://gnu-octave.github.io/pkg-octave-doc/](https://gnu-octave.github.io/pkg-octave-doc/).

## Requirements

* The function `function_texi2html` relies on the
[texi2html v1.82](https://www.nongnu.org/texi2html/) software which must be
be installed and available to $PATH.

* If `git` and an internet connection are available, the functions' generated pages
also include a URL to their respective repository locations.  This feature is only
available for packages hosted at GitHub.


## Installation

To install the latest version (0.4.5) you need Octave (>=7.2.0) installed on your system. You can install it by typing:

```
pkg install -forge pkg-octave-doc
```

To install the latest development version type:

```
pkg install "https://github.com/gnu-octave/pkg-octave-doc/archive/refs/heads/main.zip"
```

## Usage

Create a function reference for all functions listed in the INDEX file of an
installed Octave package in the working directory:

```
package_texi2html ("pkg-octave-doc")
```

## Guidelines for TEXIFNO docsstrings


* `@qcode` is converted to `@code` before texi2html processing, so if you want to display a char string it is best to use @qcode{"somestring"}, which will be displayed properly both on Octave's command window and on HTML output. Keep in mind that `@code{} encloses the content in single quotes in the command window, although they are not displayed in HTML code.

* fields of structures: it is best practice to write them as `@var{structure_name}.@qcode{field_name}` which appears in the command window as `structure_name.field_name` and in HTML as <var>structure_name</var>.<code>field_name</code>. In bootstrap 5, the `<code>` tag is not highlighted and it looks better than here :smiley:.

* Avoid nesting `@itemize` and `multitable` blocks because they are not parsed correctly by `texi2html`. You can achieve the same visual result by segmenting them.

* Table columns in HTML use dynamic width, os if you wish to maintain the required width for better visualization, add extra empty `@tags` inbetween.

For example:
````
@multitable @columnfractions 0.35 0.65
@item text @tab text
````
can be converted to
````
@multitable @columnfractions 0.33 0.02 0.65
@item text @tab @tab text
````

Make sure that `@deftypefn` and `@deftypefnx` tags have a space before them.  This is especially important for help strings in oct files (in .cc code) where we don't use ## for initiating a comment line.
For example:

in .m files
````
## -*- texinfo -*-
## @deftypefn  {pkg-octave-doc} {} function_texi2html (@var{fcnname}, @var{pkgfcns}, @var{info})
##
````
in .oct files
````
DEFUN_DLD (libsvmread, args, nargout,
           "-*- texinfo -*- \n\n\
 @deftypefn  {statistics} {[@var{labels}, @var{data}] =} libsvmread (@var{filename})\n\
\n\
\n\
This function ...
````


## TODO

1. Implement functionality for listing alphabetically all functions available
from every package in Octave Packages that can be installed with `pkg`.
2. Implement functionality for building similar documentation reference for
Octave core functions.


## Further notes

Albeit completely overhauled, this is a fork of the
[generate_html](https://packages.octave.org/generate_html) package previously
used for Source Forge reference pages.
