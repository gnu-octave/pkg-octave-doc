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

function s = get_feature (page_type, feature, options)

page_specific_feature = [page_type "_" feature];

if (isfield (options, page_specific_feature))
  s = options.(page_specific_feature);
elseif (isfield (options, feature))
  s = options.(feature);
else
  s = feval (['get_default_', feature], page_type);
endif

endfunction
