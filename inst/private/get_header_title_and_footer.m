## Copyright (C) 2008 Soren Hauberg <soren@hauberg.org>
## Copyright (C) 2014 Julien Bect <julien.bect@supelec.fr>
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

function [header, title, footer] = get_header_title_and_footer ...
  (page_type, options, name, root = "", pkgroot = "", pkgname = "")

  header = get_feature (page_type, "header", options);

  if (isfield (options, "css"))
    header = strrep (header, "%css", options.css);
  endif

  header = strrep (header, "%root", root);
  header = strrep (header, "%pkgroot", pkgroot);
  header = strrep (header, "%package", pkgname);

  body_command = get_feature (page_type, "body_command", options);
  header = strrep (header, "%body_command", body_command);

  title = get_feature (page_type, "title", options);
  title = strrep (title, "%name", name);
  header = strrep (header, "%title", title);

  footer = get_feature (page_type, "footer", options);
  footer = strrep (footer, "%root", root);
  footer = strrep (footer, "%pkgroot", pkgroot);
  footer = strrep (footer, "%package", pkgname);

endfunction
