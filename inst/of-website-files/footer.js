/* Copyright (C) 2008 Soren Hauberg

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, see
<http://www.gnu.org/licenses/>.
*/

// This function is in an extra file because it contains code specific
// to the hosting service.
function write_footer ()
{
  document.write
  (`
<div id="sf_logo">
  <a href="https://sourceforge.net"><img src="https://sourceforge.net/sflogo.php?group_id=2888&amp;type=1"
     width="88" height="31" style="border: 0;" alt="SourceForge.net Logo"/></a>
</div>
   `);
}
