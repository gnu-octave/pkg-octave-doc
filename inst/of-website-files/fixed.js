/*
Copyright (C) 2009 Søren Hauberg <soren@hauberg.org>

This file licensed under the CC0 license (see
<https://creativecommons.org/publicdomain/zero/1.0/legalcode>),
effectively placing it in the public domain.
*/

function fix_top_menu()
{
    if (navigator.appVersion.indexOf('MSIE') == -1) {
        document.getElementById("top-menu").style.position = "fixed";
    } // end non-IE
}
