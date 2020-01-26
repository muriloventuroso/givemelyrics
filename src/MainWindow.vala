/*
* Copyright (c) 2020 Murilo Venturoso
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
    public class MainWindow : Gtk.Window {
        private Gtk.HeaderBar headerbar;
        DBusImpl impl;
        HashTable<string,MprisClient> ifaces;
        private LyricsWidget lyrics_widget;
        private bool is_fullscreen = false;
        private Gtk.Button play_button;
        private Gtk.Button next_button;
        private Gtk.Button previous_button;
        public Gtk.Application application { get; construct; }
        private bool is_playing;

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_FULLSCREEN = "action-fullscreen";
        public const string ACTION_PLAY = "action_play";
        public const string ACTION_PLAY_NEXT = "action_play_next";
        public const string ACTION_PLAY_PREVIOUS = "action_play_previous";
        public const string ACTION_QUIT = "action_quit";

        public SimpleActionGroup actions;
        public Gtk.ActionGroup main_actions;

        private const ActionEntry[] action_entries = {
            { ACTION_FULLSCREEN, action_fullscreen },
            { ACTION_PLAY, action_play, null, "false" },
            { ACTION_PLAY_NEXT, action_play_next },
            { ACTION_PLAY_PREVIOUS, action_play_previous },
            { ACTION_QUIT, action_quit },
        };

        public MainWindow (Gtk.Application application) {
            Object (
                application: application,
                icon_name: "com.github.muriloventuroso.givemelyrics",
                resizable: true,
                title: _("Give Me Lyrics"),
                window_position: Gtk.WindowPosition.CENTER
            );
            application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>q", "<Control>w"});
            ifaces = new HashTable<string,MprisClient>(str_hash, str_equal);

            Idle.add(()=> {
                setup_dbus();
                return false;
            });
        }


        construct {
            settings = new Settings ();
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
            settings.notify["use-dark-theme"].connect (
                () => {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
            });
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/muriloventuroso/givemelyrics/Application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            var pref_grid = new Preferences();
            var pref_popover = new Gtk.Popover (null);
            pref_popover.add (pref_grid);

            Gtk.MenuButton settings_button = new Gtk.MenuButton ();
            settings_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            settings_button.popover = pref_popover;
            settings_button.tooltip_text = _("Menu");
            settings_button.valign = Gtk.Align.CENTER;
            previous_button = new Gtk.Button.from_icon_name (
                "media-skip-backward-symbolic",
                Gtk.IconSize.LARGE_TOOLBAR
            );
            previous_button.action_name = ACTION_PREFIX + ACTION_PLAY_PREVIOUS;
            previous_button.tooltip_text = _("Previous");

            play_button = new Gtk.Button.from_icon_name (
                "media-playback-start-symbolic",
                Gtk.IconSize.LARGE_TOOLBAR
            );
            play_button.action_name = ACTION_PREFIX + ACTION_PLAY;
            play_button.tooltip_text = _("Play");

            next_button = new Gtk.Button.from_icon_name (
                "media-skip-forward-symbolic",
                Gtk.IconSize.LARGE_TOOLBAR
            );
            next_button.action_name = ACTION_PREFIX + ACTION_PLAY_NEXT;
            next_button.tooltip_text = _("Next");

            headerbar = new Gtk.HeaderBar ();
            headerbar.show_close_button = true;
            headerbar.pack_start (previous_button);
            headerbar.pack_start (play_button);
            headerbar.pack_start (next_button);
            headerbar.set_title (_("Give Me Lyrics"));
            headerbar.pack_end(settings_button);
            headerbar.show_all ();

            set_titlebar (headerbar);
            load_settings();
            get_style_context().add_class("mainwindow");

            actions = new SimpleActionGroup ();
            actions.add_action_entries (action_entries, this);
            insert_action_group ("win", actions);

            this.delete_event.connect (
                () => {
                    save_settings ();
                    return false;
                });
            show_all();
            lyrics_widget = new LyricsWidget(this);

            add(lyrics_widget);
        }

        private void load_settings () {
            print("load settings");
            if (settings.window_maximized) {
                this.maximize ();
                this.resize (1024, 720);
            } else {
                this.resize (settings.window_width, settings.window_height);
            }
            this.move (settings.pos_x, settings.pos_y);

        }

        private void save_settings () {
            print("save settings");
            settings.window_maximized = this.is_maximized;

            if (!settings.window_maximized) {
                int x, y, width, height;
                this.get_position (out x, out y);
                this.get_size (out width, out height);
                settings.pos_x = x;
                settings.pos_y = y;
                settings.window_height = height;
                settings.window_width = width;
            }
        }

        void action_fullscreen () {
            if (is_fullscreen) {
                this.unfullscreen ();
                is_fullscreen = false;
            } else {
                this.fullscreen ();
                is_fullscreen = true;
            }
        }

        private void action_play () {
            foreach (var cw in ifaces.get_values ()) {
                if(is_playing){
                    try {
                        cw.player.pause ();
                    } catch (Error e) {
                        warning ("Could not pause: %s", e.message);
                    }
                }else{
                    if(cw.player.playback_status == "Paused"){
                        try {
                            cw.player.play ();
                        } catch (Error e) {
                            warning ("Could not pause: %s", e.message);
                        }
                        break;
                    }
                }
            }
        }

        private void action_play_next () {
            foreach (var cw in ifaces.get_values ()) {
                if(cw.player.playback_status != "Stopped"){
                    try {
                        cw.player.next ();
                    } catch (Error e) {
                        warning ("Could not pause: %s", e.message);
                    }
                    break;
                }
            }
        }

        private void action_play_previous () {
            foreach (var cw in ifaces.get_values ()) {
                if(cw.player.playback_status != "Stopped"){
                    try {
                        cw.player.previous ();
                    } catch (Error e) {
                        warning ("Could not pause: %s", e.message);
                    }
                    break;
                }
            }
        }

        private void action_quit () {
            destroy ();
        }

        public void setup_dbus() {
            try {
                impl = Bus.get_proxy_sync(BusType.SESSION, "org.freedesktop.DBus", "/org/freedesktop/DBus");
                var names = impl.list_names();

                /* Search for existing players (launched prior to our start) */
                foreach (var name in names) {
                    if (name.has_prefix("org.mpris.MediaPlayer2.")) {
                        bool add = true;
                        foreach (string name2 in ifaces.get_keys ()) {
                            // skip if already a interface is present.
                            // some version of vlc register two
                            if (name2.has_prefix (name) || name.has_prefix (name2)) {
                                add = false;
                            }
                        }
                        if (add) {
                            var iface = new_iface(name);
                            if (iface != null) {
                                add_iface(name, iface);
                            }
                        }
                    }
                }

                /* Also check for new mpris clients coming up while we're up */
                impl.name_owner_changed.connect((n,o,ne)=> {
                    /* Separate.. */
                    if (n.has_prefix("org.mpris.MediaPlayer2.")) {
                        if (o == "") {
                            // delay the sync because otherwise the dbus properties are not yet intialized!
                            Timeout.add (100, () => {
                                foreach (string name in ifaces.get_keys ()) {
                                    // skip if already a interface is present.
                                    // some version of vlc register two
                                    if (name.has_prefix (n) || n.has_prefix (name)) {
                                        return false;
                                    }
                                }
                                var iface = new_iface(n);
                                if (iface != null) {
                                    add_iface(n, iface);
                                }
                                return false;
                            });
                        } else {
                            Idle.add(()=> {
                                destroy_iface(n);
                                return false;
                            });
                        }
                    }
                });
            } catch (Error e) {
                warning("Failed to initialise dbus: %s", e.message);
            }
        }

        /**
         * Add an interface handler/widget to known list and UI
         *
         * @param name DBUS name (object path)
         * @param iface The constructed MprisClient instance
         */
        void add_iface (string name, MprisClient iface) {
            update_from_meta(iface, name);
            connect_to_client(iface);
            ifaces.insert(name, iface);

        }

        /**
         * Destroy an interface handler and remove from UI
         *
         * @param name DBUS name to remove handler for
         */
        void destroy_iface(string name) {

            ifaces.remove(name);

        }

        public MprisClient? new_iface(string busname) {
            PlayerIface? play = null;
            MprisClient? cl = null;
            DbusPropIface? prop = null;

            try {
                play = Bus.get_proxy_sync(BusType.SESSION, busname, "/org/mpris/MediaPlayer2");
            } catch (Error e) {
                message(e.message);
                return null;
            }
            try {
                prop = Bus.get_proxy_sync(BusType.SESSION, busname, "/org/mpris/MediaPlayer2");
            } catch (Error e) {
                message(e.message);
                return null;
            }
            cl = new MprisClient(play, prop);

            return cl;
        }

        private void connect_to_client (MprisClient client) {
            client.prop.properties_changed.connect ((i,p,inv) => {
                if (i == "org.mpris.MediaPlayer2.Player") {
                    /* Handle mediaplayer2 iface */
                    p.foreach ((k,v) => {
                        if (k == "Metadata") {
                            update_from_meta (client, i);

                        }
                    });
                }
            });

        }

        protected void update_from_meta (MprisClient client, string i) {

            if(client.player.playback_status == "Playing"){
                is_playing = true;
                play_button.image = new Gtk.Image.from_icon_name (
                    "media-playback-pause-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.tooltip_text = _("Pause");
            }else{
                is_playing = false;
                play_button.image = new Gtk.Image.from_icon_name (
                    "media-playback-start-symbolic",
                    Gtk.IconSize.LARGE_TOOLBAR
                );
                play_button.tooltip_text = _("Play");
            }

            lyrics_widget.update_from_meta(client, i);

        }

    }

}
