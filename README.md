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
`methods ('classname')` as well as collapsible documentation only for the methods
(including the constructor) that are present in the classdef file (inherited methods
are ignored).

## Requirements

* If `curl` and `tar` are installed and available to $PATH, and an internet connection are available,
the functions' generated pages also include a URL to their respective repository locations.  This
feature is only available for packages hosted at GitHub.


## Installation

To install the latest version you need Octave (>=9.1) installed on your system. You can install it by typing:

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

## Guidelines for texinfo docstrings


* `@deftypefn` must be used at the beggining of functions and class methods to describe the function's syntax. Consecutive lines with alternative syntaxes must use `@deftypefnx`. Both tags should stricktly follow the pattern showns in the example below in order to be correctly parsed and generate the appropriate HTML code.
     ```
     ## -*- texinfo -*-
     ## @deftypefn  {} {} function_name ()
     ## @deftypefnx {package_name} {} function_name ()
     ## @deftypefnx {package_name} {@var{out} =} function_name ()
     ## @deftypefnx {package_name} {@var{out} =} function_name (@var{in})
     ## @deftypefnx {package_name} {[@var{out}, @dots{}] =} function_name (@var{in}, @dots{})
     ...
     ## @end deftypefn
     ```
     **Note** that even when a function does not accept any input arguments, the parentheses `()` after the function name are mandatory.
     Also the two sets of curly brackets `{}` before the function name are also mandatory. The first contains the package name (which may be omitted) and the second contains the function's output arguments (including the equal sign operator).
  
* To display a char string it is best to use `@qcode{"somestring"}`, which is rendered properly both on Octave's command window and in the HTML output. Keep in mind that `@code{}` and `@qcode{}` enclose their content in single quotes in the command window, although these quotes are not shown in the HTML output.

* fields of structures: it is best practice to write them as `@var{structure_name}.@qcode{field_name}` which appears in the command window as `structure_name.field_name` and in HTML as <var>structure_name</var>.<code>field_name</code>. In bootstrap 5, the `<code>` tag is not highlighted and it looks better than here :smiley:.

* You may nest `@itemize` or `@enumerate` lists inside `@multitable` cells. The native texinfo-to-HTML converter parses nested blocks correctly and renders them as `<ul>`/`<ol>` lists within the table cell. *(Previously, nesting these blocks was not parsed correctly by the external `texi2html` tool and had to be avoided; this restriction no longer applies.)*

* Table column widths are taken directly from `@columnfractions`: each fraction becomes the CSS width of the corresponding column in the generated HTML. Just declare the fractions you want — the former workaround of inserting empty `@tab` spacer columns is no longer necessary.

For example:
````
@multitable @columnfractions 0.35 0.65
@item Name @tab Description
````
renders a table whose first column is 35% wide and second column 65% wide.

* Make sure that `@deftypefn` and `@deftypefnx` tags have a white space before them.  This is especially important for help strings in oct files (in .cc code) where we don't use ## for initiating a comment line.
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

* `@math{}` texi tags are converted to `<math></math>` tags in HTML and their contents are scanned for `x` and `*` characters, which are replaced by `&times;` in order to properly display the multiplication symbol. Make sure that lower case `x` within the `@math{}` tags is explicitly used for denoting multiplication and it is not used for anything else (e.g. variable name).  This feature, introduced in release 0.4.7, only affects the contents of `@math{}` texi tags. 

* At the moment, `function_texi2html` can handle a single `@seealso{}` tag. Make sure that there is only one `@seealso{}` tag inside each function's docstring located at the very end just before the `@end deftypefn` texinfo closing statement. Functions listed therein that belong to the same package are also linked to their individual function pages.

* `@tex` tags must only contain latex mathematical expressions enclosed with `$$` identifiers, such as in `$$ ... $$`. Math delimiters `\(...\)` are also processed in `@tex` blocks.


## Guidelines for classdef documentation
Classdef documentation and demos are handled separately in a more specialized manner, and a class is rendered in one of two layouts, chosen automatically from its source.

An **ordinary** (lumped) classdef is rendered as a single HTML page containing collapsible items for the class documentation, each public property, the constructor, and each public method, along with any demos present in the classdef file. Properties, methods (including the constructor), and demos follow the same order as they appear in the classdef file.

A **large** (grouped) classdef — one whose methods are organised into named groups by banner comment blocks in the source — is rendered as a main page carrying the class documentation, the properties, and one collapsible block per method *group*. Each group lists its methods with a one-line description, each linking to a standalone `Class.method.html` page. Those method pages are laid out like a function page (help text, source-code link, and demos) but with a class-scoped sidebar (the groups and their methods) and a breadcrumb back to the package index and the class page. The constructor is listed within its own group.

A class is treated as large when — and only when — its source contains at least one method-group banner, never by its size or line count. A banner is a comment block of the following form, placed before a `methods` block (matching the convention used by the datatypes package):
````
################################################################
##                     ** Group Name **                       ##
################################################################
````
Each public method is assigned to the group of the most recent banner above its definition; groups whose methods are all non-public (`Hidden` or private) are omitted.

Top level classdef documentation and classdef properties should use the `@deftp` tag for name declaration instead of the `@deftypefn` tag used in syntax declaration of functions and class methods. Only a single line should be used for name declaration as shown in the example below.

     ```
     classdef class_name
       ## -*- texinfo -*-
       ## @deftp {package_name} class_name
       ## 
       ## A class that does something.
       ## 
       ## More info about it...
       ##
       ## @end deftp
       
       properties
         ## -*- texinfo -*-
         ## @deftp {class_name} {property} property_name
         ##
         ## Property short description
         ##
         ## More info about it...
         ##
         ## @end deftp
         property_name = []
       endproperties
       
     endclassdef
     ```

The first sentence in the docstring of a property or a method is used as a short description in the collapsible item. The respective description for class demos is taken from the top comment lines of each demo block (if available), otherwise the command line for calling the particular demo is used as a default.

Any demos documenting the functionality of a property or method have to be saved in an external file in order to be included inside the respective collapsible item after the help documentation in the same manner it is done for functions. For this feature to work, you must be able to call the particular demos with the same typing convention as you do with the help docstrings.


## Guidelines for demos

Demos (`%!demo` blocks) are rendered as an interleaved **notebook**: each block is split into cells and laid out as a vertical stack, so that every statement's console output and figures appear immediately after the code that produced them, instead of being aggregated at the end of the demo.

* **Comment lines** become prose, written in a small subset of **Markdown** rather than texinfo. This keeps the same demo readable in the terminal when it is run with the `demo` command, while still rendering richly online. The supported constructs are:
  * inline `` `code` ``, `**bold**`, `*italic*`, and `[text](url)` links;
  * unordered lists (lines starting with `-` or `*`) and ordered lists (lines starting with `1.`);
  * paragraphs, separated by a blank comment line.

  Underscore emphasis (`_text_`) and `#` headings are intentionally unsupported, as they would clash with identifier names and the comment marker respectively. Do **not** use texinfo tags inside demo comments.

* **Code** statements become input boxes. Consecutive statements that print nothing are merged into a single box, so muted setup code reads as one block. As soon as a statement prints — because it is left unterminated by a semicolon, or calls `disp`, `printf`, and the like — an output box is emitted directly beneath it.

* **Figures** are saved as PNG images and shown right after the code that drew them.

For demos placed in the body of a classdef file, the leading comment lines of each demo block are also used as the collapsible item's label on the class page (see the classdef guidelines above).


## Further notes

Albeit completely overhauled, this is a fork of the
[generate_html](https://packages.octave.org/generate_html) package previously
used for Source Forge reference pages.
