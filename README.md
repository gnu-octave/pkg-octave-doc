<img alt="octave-doc logo" width="100"
     src="https://raw.githubusercontent.com/gnu-octave/pkg-octave-doc/main/doc/icon.png">

# octave-doc package

Create a **function reference** from Octave help texts (docstrings)
from single functions, all functions in a package,
or of all functions available in Octave itself, for example.


## Octave package function reference

Create a function reference for an installed Octave package in a `htdocs`
subfolder relative to the current directory:

```
generate_package_html ("installed_package", "htdocs");
```


## Octave (core) function reference

Create an Octave (core) function reference in a `htdocs` subfolder relative to
the current directory:

```
generate_html_manual ("/path/to/octave/repo", "htdocs");
```


## Further notes

This is a fork of the
[generate_html](https://packages.octave.org/generate_html) package.
