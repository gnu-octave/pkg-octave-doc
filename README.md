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

**Note** that since `pkg-octave-doc (>=0.6.0)` release, Octave (>=9.1) is required.
Moreover, the categories and function files in the side bar are following the same
order in the documented package's INDEX file and the classdef HTML page layout
includes collapsible documentation for all class properties return by calling
`methods ('classname') as well as collapsible documentation only for the methods
(including the constructor) that are present in the classdef file (inherited methods
are ignored).

## Requirements

* The function `function_texi2html` relies on the
[texi2html v1.82](https://www.nongnu.org/texi2html/) software which must be
installed and available to $PATH.

* If `curl` and `tar` are installed and available to $PATH, and an internet connection are available,
the functions' generated pages also include a URL to their respective repository locations.  This
feature is only available for packages hosted at GitHub.


## Installation

To install the latest version you need Octave (>=7.2.0) installed on your system. You can install it by typing:

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


## Guidelines for classdef documentation
Classdef documentation and demos are handled separately in more specialized manner. For each classdef file, a single HTML page is generated containing collapsible items for the documentation of each public property and methods as well as any demos that may be present in the classdef file. Class properties, methods (including the constructor), and demos are grouped together and they follow the same order as they appear in the classdef file.

The first sentence in the docstring of a property or a method is used as a short description in the collapsible item. The respective description for class demos is taken from the top comment lines of each demo block (is available), otherwise the command line for calling the particular demo is used as a default.

Any demos documenting the functionality of a property or method have to be saved in an external file in order to be included inside the respective collapsible item after the help documentation in the same manner it is done for functions. For this feature to work, you must be able to call the particular demos with the same typing convention as you do with the help docstrings.


## TODO

1. Write a C++ implementation for parsing texinfo to html to relax the
dependency on the rather outdated `texi2html` software.
3. Rewrite `build_DEMOS` function so that DEMO documentation includes
the console output and generated figures just after the line of code
that produces the output instead of accumulating all the output and
figures after the DEMO code block. This should help larger DEMO blocks
to be more intuitively presented in the generated documentation.


## Further notes

Albeit completely overhauled, this is a fork of the
[generate_html](https://packages.octave.org/generate_html) package previously
used for Source Forge reference pages.
