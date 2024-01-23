<img alt="octave-doc logo" width="100"
     src="https://raw.githubusercontent.com/gnu-octave/pkg-octave-doc/main/doc/pkg-octave-doc.png">

# pkg-octave-doc

Create online documentation from Octave help texts (docstrings)
of functions and classes in a package, which can be installed
with **pkg**. The generated pages follow the template of the Octave Packages at
GitHub Pages based on bootstrap 5 and they have similar layout to the older
documentation reference pages at Source Forge. The documentation also includes
the demos that are available. Legacy classes (in `@class/` folders) are processed
as individual functions with separate html pages, `classdef` files are processed
collectively including their public methods in a single html page.

You can find its documentation at [https://gnu-octave.github.io/pkg-octave-doc/](https://gnu-octave.github.io/pkg-octave-doc/).

## Requirements

* The function `function_texi2html` relies on the
[texi2html v1.82](https://www.nongnu.org/texi2html/) software which must be
be installed and available to $PATH.

* If `curl` and `tar` are installed and available to $PATH, and an internet connection are available,
the functions' generated pages also include a URL to their respective repository locations.  This
feature is only available for packages hosted at GitHub.


## Installation

To install the latest version (0.5.2) you need Octave (>=7.2.0) installed on your system. You can install it by typing:

```
pkg install -forge pkg-octave-doc
```

To install the latest development version type:

```
pkg install "https://github.com/gnu-octave/pkg-octave-doc/archive/refs/heads/main.zip"
```

## Usage

Generate a function reference for all functions listed in the INDEX file of an
installed Octave package in the working directory:

```
package_texi2html ("pkg-octave-doc")
```

If you wish to host the generated documentation on GitHub Pages, you need to create a `/docs` folder at the root of your package's repository hosted at Github (or at least mirrored there), run the above command from inside this folder in Octave to generate all necessary files, push the changes and from the repository's interface at GitHub, go to settings, choose `Pages` on the left hand side list (last item in the `Code and automation` category), and in the `Build and deployment` section of the <b>GitHub Pages</b> select:

<b>Source</b>  ->  Deploy from a branch

<b>Branch</b>  ->  `main` `/docs` and click `Save`.

You only need to do this once, and the package's website will be automatically updated every time you push a new commit into the package's `/docs` folder.

## Guidelines for TEXIFNO docsstrings


* `@qcode` is converted to `@code` before texi2html processing, so if you want to display a char string it is best to use @qcode{"somestring"}, which will be displayed properly both on Octave's command window and on HTML output. Keep in mind that `@code{}` encloses the content in single quotes in the command window, although they are not displayed in HTML code.

* fields of structures: it is best practice to write them as `@var{structure_name}.@qcode{field_name}` which appears in the command window as `structure_name.field_name` and in HTML as <var>structure_name</var>.<code>field_name</code>. In bootstrap 5, the `<code>` tag is not highlighted and it looks better than here :smiley:.

* Avoid nesting `@itemize` and `@multitable` blocks because they are not parsed correctly by `texi2html`. You can achieve the same visual result by segmenting them.

* Table columns in HTML use dynamic width, so if you wish to maintain the required width for better visualization, add extra empty `@tags` inbetween.

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

* Make sure that `@deftypefn` and `@deftypefnx` tags have a space before them.  This is especially important for help strings in oct files (in .cc code) where we don't use ## for initiating a comment line.
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

* Small docstrings containing a single line of help text after the `@deftypefn` tag must have an additional empty line before `@end deftypefn` in order to be parsed correclty. For example, the following docstring
````
## -*- texinfo -*-
## @deftypefn {RTree} {@var{n} =} rect_size ()
##
## The size @var{n} in bytes of a rectangle.
## @end deftypefn
````
must be
````
## -*- texinfo -*-
## @deftypefn {RTree} {@var{n} =} rect_size ()
##
## The size @var{n} in bytes of a rectangle.
##
## @end deftypefn
````
in order to be properly formatted in final HTML code.

* `@math{}` texi tags are converted to `<math></math>` tags in HTML and their contents are scanned for `x` and `*` characters, which are replaced by `&times;` in order to properly display the multiplication symbol. Make sure that lower case `x` within the `@math{}` tags is explicitly used for denoting multiplication and it is not used for anything else (e.g. variable name).  This feature, introduced in release 0.4.7, only affects the contents of `@math{}` texi tags. 

* At the moment, `function_texi2html` can handle a signle `@seealso{}` tag. Make sure that there is only one `@seealso{}` tag inside each function's docstring located at the very end just before the `@end deftypefn` texinfo closing statement. Functions listed therein that belong to the same package are also linked to their individual function pages.

* `@tex` tags must only contain latex mathematical expressions enclosed with `$$` identifiers, such as in `$$ ... $$`. Math delimiters `\(...\)` are also processed in `@tex` blocks.


## TODO

1. Implement functionality for listing alphabetically all functions available
from every package in Octave Packages that can be installed with `pkg`.
2. Implement functionality for building similar documentation reference for
Octave core functions.


## Further notes

Albeit completely overhauled, this is a fork of the
[generate_html](https://packages.octave.org/generate_html) package previously
used for Source Forge reference pages.
