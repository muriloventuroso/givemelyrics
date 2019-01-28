/*
* Copyright (c) 2019 Murilo Venturoso
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Murilo Venturoso <muriloventuroso@gmail.com>
*/


namespace GiveMeLyrics {
    public class Preferences : Gtk.Grid {

        Settings settings;


        public Preferences () {
            Object (
                margin: 12,
                column_spacing: 6,
                row_spacing: 12,
                width_request: 200
            );

        }

        construct {
            settings = Settings.get_default ();

            var sync_lyrics_switch = new Gtk.Switch();
            sync_lyrics_switch.halign = Gtk.Align.START;
            sync_lyrics_switch.valign = Gtk.Align.CENTER;
            sync_lyrics_switch.set_active(settings.sync_lyrics);
            sync_lyrics_switch.notify["active"].connect (() => {
                settings.sync_lyrics = sync_lyrics_switch.active;
            });

            var dark_theme_switch = new Gtk.Switch();
            dark_theme_switch.halign = Gtk.Align.START;
            dark_theme_switch.valign = Gtk.Align.CENTER;
            dark_theme_switch.set_active(settings.use_dark_theme);
            dark_theme_switch.notify["active"].connect (() => {
                settings.use_dark_theme = dark_theme_switch.active;
            });

            attach (new Granite.HeaderLabel (_("Synchronized Lyrics:")), 0, 1, 1, 1);
            attach (sync_lyrics_switch, 1, 1, 1, 1);

            attach (new Granite.HeaderLabel (_("Dark Theme:")), 0, 2, 1, 1);
            attach (dark_theme_switch, 1, 2, 1, 1);

            show_all();
        }



    }
}
