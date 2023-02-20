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

To install the latest version (0.4.4) you need Octave (>=6.1.0) installed on your system. If you have Octave (>=7.2.0) you can install it by typing:

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


## TODO

1. Implement a function for listing alphabetically all functions available
from every package in Octave Packages that can be installed with `pkg`.
2. Implement a function for building a similar documentation reference for
Octave core functions.


## Further notes

Albeit completely overhauled, this is a fork of the
[generate_html](https://packages.octave.org/generate_html) package previously
used for Source Forge reference pages.
