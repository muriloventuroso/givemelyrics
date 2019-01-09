/*
* Copyright (c) 2018 Murilo Venturoso
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

    public Settings settings;

    public class Application : Granite.Application {
        private Gtk.Window main_window;
        private Gtk.HeaderBar headerbar;
        private LyricsWidget lyrics_widget;

        public const string ACTION_PREFIX = "win.";

        public SimpleActionGroup actions;
        public Gtk.ActionGroup main_actions;

        public Application () {
            Object (application_id: "com.github.muriloventuroso.givemelyrics",
            flags: ApplicationFlags.FLAGS_NONE);


        }

        construct {
            Intl.setlocale (LocaleCategory.ALL, "");
        }

        public override void activate () {
            if (get_windows ().length () > 0) {
                get_windows ().data.present ();
                return;
            }
            settings = new Settings ();
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/muriloventuroso/givemelyrics/Application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            actions = new SimpleActionGroup ();
            main_window = new Gtk.Window();

            headerbar = new Gtk.HeaderBar ();
            headerbar.has_subtitle = false;
            headerbar.show_close_button = true;
            headerbar.title = _("Give Me Lyrics");
            headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            headerbar.get_style_context().add_class("headerbar");

            main_window.application = this;
            main_window.icon_name = "givemelyrics";
            main_window.title = _("Give Me Lyrics");
            main_window.set_titlebar (headerbar);
            main_window.insert_action_group ("win", actions);

            load_settings();

            main_window.show_all();
            lyrics_widget = new LyricsWidget(main_window);
            main_window.add(lyrics_widget);

            main_window.get_style_context().add_class("mainwindow");

            add_window (main_window);

            var quit_action = new SimpleAction ("quit", null);

            add_action (quit_action);

            quit_action.activate.connect (() => {
                if (main_window != null) {
                    main_window.destroy ();
                }
            });

            main_window.delete_event.connect (
                () => {
                    save_settings ();
                    return false;
                });


        }

        private void load_settings () {
            if (settings.window_maximized) {
                main_window.maximize ();
                main_window.set_default_size (1024, 720);
            } else {
                main_window.set_default_size (settings.window_width, settings.window_height);
            }
            main_window.move (settings.pos_x, settings.pos_y);

        }

        private void save_settings () {

            settings.window_maximized = main_window.is_maximized;

            if (!settings.window_maximized) {
                int x, y, width, height;
                main_window.get_position (out x, out y);
                main_window.get_size (out width, out height);
                settings.pos_x = x;
                settings.pos_y = y;
                settings.window_height = height;
                settings.window_width = width;
            }
        }


        private static int main (string[] args) {
            Gtk.init (ref args);

            var app = new Application ();
            return app.run (args);
        }


    }
}
