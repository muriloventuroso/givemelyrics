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
const int ICON_SIZE = 64;
namespace GiveMeLyrics {
    public class LyricsWidget : Gtk.Box{

        DBusImpl impl;
        HashTable<string,MprisClient> ifaces;
        private Gtk.Image? background = null;
        public Gtk.Window window { get; construct; }
        public string last_title;
        public string last_artist;
        public string last_artUrl;
        private Cancellable load_remote_art_cancel;
        private Gtk.Label title_label;
        private Gtk.Label artist_label;
        private LyricsFetcher fetcher;
        private Gtk.TextView view;
        private Gtk.Grid titles;
        private Gtk.ScrolledWindow scrolled;
        private Gtk.Image icon;
        private Gtk.Box box_message;
        private Gtk.Box box_spinner;
        private Gtk.Label label_message;
        private Gtk.LinkButton source_link;

        public LyricsWidget (Gtk.Window window) {
            Object (
                margin_start: 30,
                margin_end: 30,
                window: window
            );
            last_title = "";
            last_artist = "";
            last_artUrl = "";
            ifaces = new HashTable<string,MprisClient>(str_hash, str_equal);

            Idle.add(()=> {
                setup_dbus();
                return false;
            });
        }
        construct {
            fetcher = new LyricsFetcher();
            load_remote_art_cancel = new Cancellable ();

            background = new Gtk.Image ();

            var overlay = new Gtk.Overlay ();
            overlay.can_focus = true;
            overlay.margin_bottom = 2;
            overlay.margin_end = 4;
            overlay.margin_start = 4;
            overlay.add (background);

            title_label = new Gtk.Label (last_title);
            title_label.ellipsize = Pango.EllipsizeMode.END;
            title_label.halign = Gtk.Align.START;
            title_label.use_markup = true;
            title_label.valign = Gtk.Align.END;
            title_label.get_style_context().add_class("h2");

            artist_label =  new Gtk.Label (last_artist);
            artist_label.ellipsize = Pango.EllipsizeMode.END;
            artist_label.halign = Gtk.Align.START;
            artist_label.use_markup = true;
            artist_label.valign = Gtk.Align.START;
            artist_label.get_style_context().add_class("h3");

            titles = new Gtk.Grid ();
            titles.hexpand = true;
            titles.column_spacing = 3;
            titles.attach (overlay, 0, 0, 1, 2);
            titles.attach (title_label, 1, 0);
            titles.attach (artist_label, 1, 1);
            titles.margin_bottom = 10;

            scrolled = new Gtk.ScrolledWindow (null, null);
            var box_scrolled = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            view = new Gtk.TextView ();
            view.editable = false;
            view.set_wrap_mode (Gtk.WrapMode.WORD);
            view.vexpand = true;
            view.get_style_context().add_class("view-lyric");
            box_scrolled.pack_start(view, true, true, 0);

            source_link = new Gtk.LinkButton.with_label("http://google.com/", _("Source"));
            source_link.hexpand = false;
            source_link.vexpand = false;
            source_link.margin_bottom = 10;
            source_link.margin_top = 10;
            source_link.halign = Gtk.Align.START;
            box_scrolled.pack_start(source_link, false, false, 0);

            scrolled.add (box_scrolled);

            box_message = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box_message.hexpand = true;
            box_message.vexpand = true;
            box_message.halign = Gtk.Align.CENTER;
            box_message.valign = Gtk.Align.CENTER;
            box_message.set_spacing(10);

            icon = new Gtk.Image ();
            icon.gicon = new ThemedIcon ("face-uncertain");
            icon.pixel_size = 48;

            label_message = new Gtk.Label(_("Nothing is playing"));
            label_message.get_style_context().add_class("h1");

            var spinner = new Gtk.Spinner();
            spinner.active = true;
            spinner.height_request = 32;
            spinner.width_request = 32;

            box_spinner = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box_spinner.add(spinner);
            box_message.pack_start(box_spinner, false, false, 0);

            box_message.pack_start(label_message, false, false, 0);
            box_message.pack_start(icon, false, false, 0);

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_start(titles, false, true, 0);
            box.pack_start(box_message);
            box.pack_start(scrolled, true, true, 0);

            var grid_source = new Gtk.Grid();
            grid_source.attach(source_link, 0, 0, 1, 1);
            box.pack_start(grid_source, false, false, 0);
            add(box);
            show_all();
            titles.hide();
            scrolled.hide();
            box_spinner.hide();
            source_link.hide();
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
            update_from_meta(iface);
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

                            update_from_meta (client);

                        }
                    });
                }
            });
        }

        protected void update_from_meta (MprisClient client) {
            var metadata = client.player.metadata;
            var playing = false;
            var must_update_lyric = false;
            if(client.player.playback_status == "Playing"){
                playing = true;
                if  ("mpris:artUrl" in metadata) {
                    var url = metadata["mpris:artUrl"].get_string ();
                    if(url != last_artUrl){
                        last_artUrl = url;
                        update_art (url);
                    }
                }

                string title = "";
                if  ("xesam:title" in metadata && metadata["xesam:title"].is_of_type (VariantType.STRING)
                    && metadata["xesam:title"].get_string () != "") {
                    title = metadata["xesam:title"].get_string ().split("-")[0];
                    if(title != last_title){
                        last_title = title;
                        title_label.label = "<b>%s</b>".printf (Markup.escape_text (last_title));
                        must_update_lyric = true;
                    }
                }

                //title_label.label = "<b>%s</b>".printf (Markup.escape_text (title));
                string artist = "";
                if  ("xesam:artist" in metadata && metadata["xesam:artist"].is_of_type (VariantType.STRING_ARRAY)) {
                    (unowned string)[] artists = metadata["xesam:artist"].get_strv ();
                    //artist_label.label = string.joinv (", ", artists);
                    artist = Markup.escape_text (string.joinv (", ", artists));
                    if(artist != last_artist){
                        last_artist = artist;
                        artist_label.label = artist;
                    }
                }
            }

            if(last_title == "Spotify" || last_title == "Advertisement" && last_artist == ""){
                must_update_lyric = false;
                scrolled.hide();
                titles.show();
                box_message.show();
                icon.show();
                source_link.hide();
                label_message.label = _("Advertising");
            }

            if(playing == true && must_update_lyric == true){
                scrolled.hide();
                icon.hide();
                titles.show();
                box_message.show();
                box_spinner.show();
                label_message.label = _("Loading");
                update_lyric();
            }

        }

        private void update_lyric(){
            new Thread<void*> (null, () => {
                bool error = false;
                var r = fetcher.get_lyric(last_title, last_artist);
                var lyric = r[0];
                var url = r[1];
                if(url != ""){
                    source_link.set_uri(url);
                    source_link.show();
                }else{
                    source_link.hide();
                }
                view.buffer.text = lyric;
                if(lyric == "" || lyric == null){
                    error = true;
                }

                if (error == true) {
                    scrolled.hide();
                    box_spinner.hide();
                    icon.show();
                    label_message.label = _("No lyric found");
                } else {
                    box_spinner.hide();
                    box_message.hide();
                    scrolled.show();
                }


                return null;
            });
        }

        private static Gdk.Pixbuf? mask_pixbuf (Gdk.Pixbuf pixbuf, int scale) {
            var size = ICON_SIZE * scale;
            var mask_offset = 4 * scale;
            var mask_size_offset = mask_offset * 2;
            var mask_size = ICON_SIZE * scale;
            var offset_x = mask_offset;
            var offset_y = mask_offset + scale;
            size = size - mask_size_offset;

            var input = pixbuf.scale_simple (size, size, Gdk.InterpType.BILINEAR);
            var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, mask_size, mask_size);
            var cr = new Cairo.Context (surface);

            Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, offset_x, offset_y, size, size, mask_offset);
            cr.clip ();

            Gdk.cairo_set_source_pixbuf (cr, input, offset_x, offset_y);
            cr.paint ();
            return Gdk.pixbuf_get_from_surface (surface, 0, 0, mask_size, mask_size);
        }

        /**
         * Utility, handle updating the album art
         */
        private void update_art (string uri) {
            var scale = get_style_context ().get_scale ();
            if (!uri.has_prefix ("file://") && !uri.has_prefix ("http")) {
                background.gicon = null;
                background.get_style_context ().set_scale (scale);
                return;
            }

            if (uri.has_prefix  ("file://")) {
                string fname = uri.split ("file://")[1];
                try {
                    var pbuf = new Gdk.Pixbuf.from_file_at_size (fname, ICON_SIZE * scale, ICON_SIZE * scale);
                    background.gicon = mask_pixbuf (pbuf, scale);
                    background.get_style_context ().set_scale (1);
                } catch  (Error e) {
                    //background.set_from_gicon (app_icon, Gtk.IconSize.DIALOG);
                }
            } else {
                load_remote_art_cancel.cancel ();
                load_remote_art_cancel.reset ();
                load_remote_art.begin (uri);
            }
        }

        private async void load_remote_art (string uri) {
            var scale = get_style_context ().get_scale ();
            GLib.File file = GLib.File.new_for_uri (uri);
            try {
                GLib.InputStream stream = yield file.read_async (Priority.DEFAULT, load_remote_art_cancel);
                Gdk.Pixbuf pixbuf = yield new Gdk.Pixbuf.from_stream_async (stream, load_remote_art_cancel);
                if (pixbuf != null) {
                    background.gicon = mask_pixbuf (pixbuf, scale);
                    background.get_style_context ().set_scale (1);
                }
            } catch (Error e) {
                background.gicon = null;
                background.get_style_context ().set_scale (scale);
            }
        }


    }
}
