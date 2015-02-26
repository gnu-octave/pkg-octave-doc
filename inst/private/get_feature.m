## Copyright (C) 2014, 2015 Julien Bect <jbect@users.sourceforge.net>
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

function s = get_feature (page_type, feature, options)

  s = "";

  ## Look at page-specific feature value first  
  if (! strcmp (page_type, "function"))
    page_specific_feature = [page_type "_" feature];
    s = options.(page_specific_feature); 
  endif

  ## If not available, use value from individual function pages
  if (isempty (s))
    s = options.(feature);
  endif

endfunction
