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
    public class Preferences : Gtk.Dialog {

        Settings settings;


        public Preferences (Gtk.Window? parent) {
            Object (
                border_width: 5,
                title: _("Preferences"),
                resizable: false,
                deletable: false,
                transient_for: parent
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

            var general_grid = new Gtk.Grid ();
            general_grid.column_spacing = 12;
            general_grid.row_spacing = 6;

            general_grid.attach (new Granite.HeaderLabel (_("Synchronized Lyrics:")), 0, 1, 1, 1);
            general_grid.attach (sync_lyrics_switch, 1, 1, 1, 1);
            var main_stack = new Gtk.Stack ();
            main_stack.margin = 6;
            main_stack.margin_bottom = 18;
            main_stack.margin_top = 24;
            main_stack.add_titled (general_grid, "general", _("General"));

            var main_stackswitcher = new Gtk.StackSwitcher ();
            main_stackswitcher.set_stack (main_stack);
            main_stackswitcher.halign = Gtk.Align.CENTER;

            var main_grid = new Gtk.Grid ();
            main_grid.attach (main_stackswitcher, 0, 0, 1, 1);
            main_grid.attach (main_stack, 0, 1, 1, 1);

            get_content_area ().add (main_grid);

            add_button (_("Close"), Gtk.ResponseType.CLOSE);

            show_all();
        }



    }
}
