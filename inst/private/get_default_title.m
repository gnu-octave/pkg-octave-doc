## Copyright (C) 2014 Julien Bect
## Copyright (C) 2008 Soren Hauberg <soren@hauberg.org>
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

## Author: Julien Bect <bect@bect-laptop>
## Created: 2014-08-20

function title = get_default_title (page_type)

switch page_type

  case 'overview'
    title = "List of Functions for the '%name' package";

  case 'index'
    title = "The '%name' package";  
    
  case 'function'
    title = "%name";
  
  otherwise
    error (sprintf ("Unknown page_type: %s", page_type));
    
endswitch
    
## Note: %name stands for the package name in the first two cases, and for
## the function name in the last one. There is a risk of confusion. 

endfunction
