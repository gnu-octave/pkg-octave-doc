## Copyright (C) 2008 Soren Hauberg <soren@hauberg.org>
## Copyright (C) 2015 Julien Bect <jbect@users.sourceforge.net>
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} __texi2html__ ()
## undocumented internal function
## @end deftypefn

function [header, text, footer] = __texi2html__ (text, vpars)

  ## Add easily recognisable text before and after real text
  start = "###### OCTAVE START ######";
  stop  = "###### OCTAVE STOP ######";
  text = sprintf ("%s\n%s\n%s\n", start, text, stop);

  ## Prevent empty <pre> </pre> blocks
  ## (see https://savannah.gnu.org/bugs/?44451)
  text = regexprep (text, '([\r\n|\n])[ \t]*@group', '$1@group');
  text = regexprep (text, '([\r\n|\n])[ \t]*@end', '$1@end');

  ## Remove one leading white space.  Assuming that all non-empty
  ## lines start with "## ", this prevents one extra white space
  ## from showing up in example blocks.
  text = regexprep (text, '([\r\n|\n])[ \t]', '$1');

  ## Run makeinfo
  orig_text = text;
  [text, status] = __makeinfo__ (text, ...
    "html", @(x) getopt ("seealso") (root, x{:}));
  if (status != 0)
    error ("__makeinfo__ returned with error code %d\n. Couldn't parse\
      texinfo:\n%s", status, orig_text (1:min (200, length (orig_text))));
  endif

  ## Check encoding
  tmp = regexp (text, "charset\s*=\s*([^\s\"]*)", "tokens");
  if (! isempty (tmp))
    charset = tmp{1}{1};
    if (! strcmp (options_charset = getopt ("charset"), charset))
      warning (["makeinfo's output is encoded in %s, but will be " ...
        "interpreted with options.charset = %s"], charset, options_charset);
    endif
  endif

  ## Extract the body of makeinfo's output
  p_start = sprintf ('\\s*(<p>)?\\s*%s\\s*(</p>)?\\s*', start);
  p_stop = sprintf ('\\s*(<p>)?\\s*%s\\s*(</p>)?\\s*', stop);
  [i1, i2] = regexp (text, p_start);
  i3 = regexp (text, p_stop);
  text = text((i2 + 1):(i3 - 1));
  
  ## Insert class="deftypefn" attribute
  text = insert_deftypefn_class_attribute (text);

  ## Read options.
  header = getopt ("header", vpars);
  footer = getopt ("footer", vpars);

endfunction


function text = insert_deftypefn_class_attribute (text)

  ## @deftypefn pattern for TexInfo 4.x
  p1 = '&mdash;\s*(Function.*?)\s*<br>';
  
  if ~ isempty (regexp (text, p1, 'once'))  ## TexInfo 4.x

    ## <div class="defun">
    ## &mdash; Function File: ... <br>
    ## &mdash; Function File: ... <br>
    ## <blockquote> ... </blockquote>
    ## </div>

    p2 = sprintf (['\\s*<div\\s*(?:class="[a-z]*")?>\\s*' ...
      '((?:%s\\s*)+)<blockquote>(.*?)\\s*</blockquote>\\s*</div>\\s*'], p1);
    text = regexprep (text, p2, '<dl>\n$1<dd>$3\n</dd></dl>');
    text = regexprep (text, p1, '<dt class="deftypefn">$1</dt>');
    
  else  ## TexInfo 5.x

    ## <dl>
    ## <dt><a name="index-plot"></a>Function File: ... </dt>
    ## <dt><a name="index-plot-1"></a>Function File: ... </dt>
    ## <dd> ... </dd>
    ## </dl>

    ## @deftypefn pattern for TexInfo 5.x
    p1 = '<dt>\s*((<a.*?</a>)?\s*Function.*?)\s*<br>';

    text = regexprep (text, p1, '<dt class="deftypefn">$1</dt>');

  endif
  
endfunction
