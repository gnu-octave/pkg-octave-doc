<img alt="octave-doc logo" width="100"
     src="https://raw.githubusercontent.com/gnu-octave/pkg-octave-doc/main/doc/icon.png">

# pkg-octave-doc

Create a **function reference** from Octave help texts (docstrings)
from single functions or all functions in a package, which can be installed
with **pkg**. The generated pages follow the template of the Octave Packages at
GitHub Pages based on bootstrap 5 and they have similar layout to the older
documentation reference pages at Source Forge.

## Requirements

The function `function_texi2html` relies on the
[texi2html](https://www.nongnu.org/texi2html/) software which must be
be installed and available to $PATH.

## Octave package function reference

Create a function reference for all functions listed in the INDEX file of an
installed Octave package in the current directory:

```
package_texi2html (pkgname)
```


## TODO

1. Add documentation and BISTs to the existing functions.
2. Update functionality to include DEMOS at the bottom of each function's page
like in Source Forge site.
3. Implement a function for building a function reference for Octave core
 functions.


## Further notes

Albeit completely overhauled, this is a fork of the
[generate_html](https://packages.octave.org/generate_html) package previously
used for Source Forge reference pages.
