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

var cookie_name = "octave_forge_cookie";

function set_cookie(val)
{
    if (document.cookie != document.cookie) {
        index = document.cookie.indexOf(cookie_name);
    } else {
        index = -1;
    }
    if (index == -1) {
        var cval = cookie_name + "=" + val + "; ";
        var d = new Date();
        d.setSeconds(d.getSeconds()+30);
        cval = cval + "expires=" + d.toString() + ";";
        document.cookie = cval;
    }
}

function get_cookie()
{
    var retval = -1;
    if (document.cookie) {
        var index = document.cookie.indexOf(cookie_name);
        if (index != -1) {
            var start = document.cookie.indexOf("=", index) + 1;
            stop = document.cookie.indexOf(";", start);
            if (stop == -1) {
                stop = document.cookie.length;
            }
            retval = document.cookie.substring(start, stop);
        }
    }
    return retval;
}

function goto_url (selSelectObject)
{
    if (selSelectObject.options[selSelectObject.selectedIndex].value != "-1") {
        location.href=selSelectObject.options[selSelectObject.selectedIndex].value;
    }
}

function show_left_menu ()
{
  document.getElementById ("left-menu").style.display = "block";
}

function manual_menu ()
{
  // XXX: What should we do here? And do we even need this function?
  write_left_menu ();
}

function write_top_menu (prefix)
{
  // default prefix (maybe some old browsers need this way)
  prefix = (typeof prefix == 'undefined') ? '.' : prefix;

  document.write
  (`
  <div id="top-menu" class="menu"> 
   <table class="menu">
      <tr>
        <td style="width: 90px;" class="menu" rowspan="2">
          <a name="top">
          <img src="${prefix}/oct.png" alt="Octave logo" />
          </a>
        </td>
        <td class="menu" style="padding-top: 0.9em;">
          <big class="menu">Octave-Forge</big><small class="menu"> - Extra packages for GNU Octave</small>
        </td>
      </tr>
      <tr>
        <td class="menu">
          
 <a href="${prefix}/index.php" class="menu">Home</a> &middot;
 <a href="${prefix}/packages.php" class="menu">Packages</a> &middot;
 <a href="${prefix}/developers.php" class="menu">Developers</a> &middot;
 <a href="${prefix}/docs.php" class="menu">Documentation</a> &middot;
 <a href="${prefix}/FAQ.php" class="menu">FAQ</a> &middot;
 <a href="${prefix}/bugs.php" class="menu">Bugs</a> &middot;
 <a href="${prefix}/archive.php" class="menu">Mailing Lists</a> &middot;
 <a href="${prefix}/links.php" class="menu">Links</a> &middot;
 <a href="${prefix}/code.php" class="menu">Code</a>

        </td>
      </tr>
    </table>
  </div>
   `);
}

function write_docs_left_menu (prefix)
{
  // default prefix (maybe some old browsers need this way)
  prefix = (typeof prefix == 'undefined') ? '.' : prefix;

  document.write
  (`
<div id="left-menu">
  <h3>Navigation</h3>
  <p class="left-menu"><a class="left-menu-link" href="${prefix}/operators.html">Operators and Keywords</a></p>
  <p class="left-menu"><a class="left-menu-link" href="${prefix}/function_list.php">Function List:</a>
  <ul class="left-menu-list">
    <li class="left-menu-list">
      <a  class="left-menu-link" href="${prefix}/octave/overview.html">&#187; Octave core</a>
    </li>
    <li class="left-menu-list">
      <a  class="left-menu-link" href="${prefix}/functions_by_package.php">&#187; by package</a>
    </li>
    <li class="left-menu-list">
      <a  class="left-menu-link" href="${prefix}/functions_by_alpha.php">&#187; alphabetical</a>
    </li>
  </ul>
  </p>
  <p class="left-menu"><a class="left-menu-link" href="${prefix}/doxygen/html">C++ API</a></p>
</div>
   `);
}
