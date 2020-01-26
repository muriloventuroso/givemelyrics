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
        private int? current_line_sync;
        private bool sync_running;
        private string last_subtitle;
        private Gtk.TextTag bold_tag;
        private int64 msec_change_song;
        private int64 last_position;
        private bool was_paused;
        private bool updating;
        private Gtk.Label sync_label;
        private Lyric current_lyric;
        private Gtk.Box box_change_lyric;
        private Gtk.Button arrow_lyric_left;
        private Gtk.Button arrow_lyric_right;
        private Gtk.Label label_change_lyric;

        public LyricsWidget (Gtk.Window window) {
            Object (
                margin_start: 30,
                margin_end: 30,
                window: window
            );
            last_title = "";
            last_artist = "";
            last_artUrl = "";
            last_subtitle = "";
            current_line_sync = null;
            sync_running = false;
            last_position = 0;
            was_paused = false;

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

            var box_information = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box_information.halign = Gtk.Align.END;
            box_information.hexpand = true;

            titles = new Gtk.Grid ();
            titles.hexpand = true;
            titles.column_spacing = 3;
            titles.attach (overlay, 0, 0, 1, 2);
            titles.attach (title_label, 1, 0);
            titles.attach (artist_label, 1, 1);
            titles.attach (box_information, 2, 0, 1, 2);
            titles.margin_bottom = 10;

            scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
            scrolled.margin_bottom = 30;

            view = new Gtk.TextView ();
            view.editable = false;
            view.set_wrap_mode (Gtk.WrapMode.WORD);
            view.vexpand = true;
            view.get_style_context().add_class("view-lyric");
            view.buffer.create_tag("lyric");
            var subtitle_tag = view.buffer.create_tag("subtitle");
            subtitle_tag.justification = Gtk.Justification.CENTER;
            bold_tag = view.buffer.create_tag("bold");
            bold_tag.weight = 700;
            bold_tag.pixels_above_lines = 20;
            bold_tag.pixels_below_lines = 20;

            source_link = new Gtk.LinkButton.with_label("http://google.com/", _("Source"));
            source_link.hexpand = false;
            source_link.vexpand = false;
            source_link.margin_bottom = 10;
            source_link.margin_top = 0;
            source_link.halign = Gtk.Align.END;

            sync_label = new Gtk.Label(_("Synchronized Lyrics"));
            sync_label.margin_bottom = 10;

            box_change_lyric = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box_change_lyric.halign = Gtk.Align.END;
            arrow_lyric_left = new Gtk.Button.from_icon_name ("pan-start-symbolic", Gtk.IconSize.BUTTON);
            arrow_lyric_left.relief = Gtk.ReliefStyle.NONE;
            arrow_lyric_left.clicked.connect(change_lyric_left);

            arrow_lyric_right = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.BUTTON);
            arrow_lyric_right.relief = Gtk.ReliefStyle.NONE;
            arrow_lyric_right.clicked.connect(change_lyric_right);
            label_change_lyric = new Gtk.Label("1");
            box_change_lyric.pack_start(arrow_lyric_left, false, false, 0);
            box_change_lyric.pack_start(label_change_lyric, false, false, 0);
            box_change_lyric.pack_start(arrow_lyric_right, false, false, 0);

            box_information.pack_start(source_link, false, false, 0);
            box_information.pack_start(sync_label, false, false, 0);
            box_information.pack_start(box_change_lyric, false, false, 0);

            scrolled.add (view);

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

            add(box);
            show_all();
            titles.hide();
            scrolled.hide();
            box_spinner.hide();
            source_link.hide();
            sync_label.hide();
            box_change_lyric.hide();
        }

        public void update_from_meta (MprisClient client, string i) {
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
                    title = metadata["xesam:title"].get_string ().split(" - ")[0];
                    msec_change_song = GLib.get_real_time ();
                    if(title != last_title){
                        last_title = title;
                        title_label.label = "<b>%s</b>".printf (Markup.escape_text (last_title));
                        must_update_lyric = true;
                        last_subtitle = "";
                        last_position = 0;
                        was_paused = false;
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

                var window_title = artist + " - " + title;
                if(window.title != window_title){
                    window.title = window_title;
                }
            }else{
                string title = "";
                if  ("xesam:title" in metadata && metadata["xesam:title"].is_of_type (VariantType.STRING)
                    && metadata["xesam:title"].get_string () != "") {
                    title = metadata["xesam:title"].get_string ().split(" - ")[0];
                    if(title == last_title){
                        was_paused = true;
                    }
                }
                window.title = _("Give Me Lyrics");
            }

            if(last_title == "Spotify" || last_title == "Advertisement" && last_artist == ""){
                must_update_lyric = false;
                scrolled.hide();
                titles.show();
                box_message.show();
                icon.show();
                source_link.hide();
                box_spinner.hide();
                label_message.label = _("Advertising");
            }

            if(playing == true && must_update_lyric == true){
                scrolled.hide();
                icon.hide();
                titles.show();
                box_message.show();
                box_spinner.show();
                label_message.label = _("Loading");
                sync_label.hide();
                box_change_lyric.hide();
                source_link.hide();
                arrow_lyric_left.set_sensitive(false);
                arrow_lyric_right.set_sensitive(true);
                label_change_lyric.label = "1";
                update_lyric(client, i);
            }else{
                if(playing == true && sync_running == false && updating == false){
                    set_sync(client, i);
                }
            }

        }

        private async void update_lyric(MprisClient client, string i){
            ThreadFunc<void*> run = () => {
                updating = true;
                var sub = "";
                var title = "";
                var url = "";
                var lyric = "";
                try{
                    bool error = false;
                    var r = fetcher.get_lyric(last_title, last_artist);
                    if(r != null){
                        lyric = r.lyric;
                        url = r.current_url;
                        title = r.title;
                        sub = r.lyric_sync;
                        if(title != last_title){
                            return null;
                        }
                        if(url != ""){
                            source_link.set_uri(url);
                            source_link.show();
                        }else{
                            source_link.hide();
                        }
                        Idle.add(()=> {
                            clean_text_buffer();
                            return false;
                        });

                        if(lyric == "" || lyric == null){
                            error = true;
                        }
                        current_lyric = r;
                    }else{
                        error = true;
                    }

                    if (error == true) {
                        scrolled.hide();
                        box_spinner.hide();
                        icon.show();
                        label_message.label = _("No lyric found");
                        sync_label.hide();
                        box_change_lyric.hide();
                    } else {
                        if(settings.sync_lyrics == true && sub != "" && sub != null){
                            Idle.add(()=> {
                                insert_subtitle(sub);
                                show_lyrics();
                                return false;
                            });
                            set_sync(client, i);
                            sync_label.label = _("Synchronized Lyrics");
                            sync_label.show();
                            if(current_lyric.get_len_urls() > 1){
                                box_change_lyric.show();
                            }else{
                                box_change_lyric.hide();
                            }

                        }else{
                            box_change_lyric.hide();
                            Idle.add(()=> {
                                insert_text(lyric);
                                show_lyrics();
                                return false;
                            });
                            if(settings.sync_lyrics == true){
                                sync_label.label = _("Non-Synchronized Lyrics");
                                sync_label.show();
                            }else{
                                sync_label.hide();
                            }
                        }
                    }
                } catch (Error e) {
                    warning("Failed to get lyric: %s", e.message);
                }

                updating = false;
                return null;
            };

            try {
                new Thread<void*>.try (null, run);
            } catch (Error e) {
                warning (e.message);
            }

        }

        private void insert_text(string text){
            Gtk.TextIter text_start;
            Gtk.TextIter text_end;

            view.buffer.get_start_iter(out text_start);
            view.buffer.insert (ref text_start, text, text.length);
            view.buffer.get_end_iter(out text_end);
            view.buffer.apply_tag_by_name ("lyric", text_start, text_end);
        }

        private void show_lyrics(){
            scrolled.get_vadjustment().set_value(0);
            box_spinner.hide();
            box_message.hide();
            scrolled.show();
        }

        private void insert_subtitle(string subtitle){
            Gtk.TextIter subtitle_start;
            Gtk.TextIter subtitle_end;
            last_subtitle = subtitle;
            view.buffer.get_start_iter(out subtitle_start);
            foreach(var row in subtitle.split("\n")){
                var array = row.split("|-|");
                var lyric = "\n";
                if(array[0] != null){
                    lyric = array[0].chomp() + "\n";
                }
                view.buffer.insert (ref subtitle_start, lyric, lyric.length);
                view.buffer.get_end_iter(out subtitle_start);
            }

            view.buffer.get_start_iter(out subtitle_start);
            view.buffer.get_end_iter(out subtitle_end);
            view.buffer.apply_tag_by_name ("subtitle", subtitle_start, subtitle_end);

        }

        private void set_sync(MprisClient client, string iface_name){
            sync_running = true;

            Timeout.add_full (Priority.DEFAULT, 500, () => {
                try{
                    int64 position;
                    int64 position_msec = 0;
                    try{
                        position_msec = client.prop.get_sync(iface_name, "Position").get_int64();
                    }catch(Error e){
                    }
                    var diff_msec = GLib.get_real_time () - msec_change_song;
                    if(position_msec == 0){
                        if(was_paused == true){
                            position = diff_msec / 1000 / 1000 + last_position;
                        }else{
                            position = diff_msec / 1000 / 1000;
                        }
                    }else{
                        position = position_msec / 1000 / 1000;
                    }
                    var rows = last_subtitle.split("\n");
                    if(position < 10){
                        scrolled.get_vadjustment().set_value(0);
                    }
                    if(position == 0){
                        return true;
                    }
                    var find_row = false;
                    for(var i = 0; i < rows.length; i++){
                        var array = rows[i].split("|-|");
                        if(array.length == 3){
                            if(Math.round (double.parse(array[1])) - 0.1 < position && Math.round (int.parse(array[2])) > position){
                                find_row = true;
                                if(i != current_line_sync){
                                    current_line_sync = i;
                                    Idle.add(() => {
                                        clean_bold_tag();
                                        Gtk.TextIter line_start;
                                        Gtk.TextIter line_end;
                                        view.buffer.get_iter_at_line(out line_start, i);
                                        view.buffer.get_iter_at_line_offset(out line_end, i, array[0].length);
                                        view.buffer.apply_tag(bold_tag, line_start, line_end);
                                        view.scroll_to_iter(line_start, 0.1, false, 0, 0);
                                        return false;
                                    });
                                    break;
                                }
                            }
                        }
                    }
                    if(sync_label.visible == false){
                        return false;
                    }
                    if(client.prop.get_sync(iface_name, "PlaybackStatus").dup_string() == "Playing"){
                        return true;
                    }else{
                        sync_running = false;
                        last_position = position + 1;
                        return false;
                    }
                }catch (Error e) {
                    print(e.message);
                    return true;
                }
            });
        }

        private void clean_bold_tag(){
            Gtk.TextIter line_start;
            Gtk.TextIter line_end;
            view.buffer.get_start_iter(out line_start);
            view.buffer.get_end_iter(out line_end);
            view.buffer.remove_tag(bold_tag, line_start, line_end);
        }

        private void clean_text_buffer(){
            Gtk.TextIter start;
            Gtk.TextIter end;
            view.buffer.get_start_iter(out start);
            view.buffer.get_end_iter(out end);
            view.buffer.delete(ref start, ref end);
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

        private void change_lyric_right(){
            var current = int.parse(label_change_lyric.label);
            if(current < current_lyric.get_len_urls()){
                change_lyric(current + 1);
                label_change_lyric.label = (current + 1).to_string();
                arrow_lyric_left.set_sensitive(true);
            }
            current = int.parse(label_change_lyric.label);
            if(current == 1){
                arrow_lyric_left.set_sensitive(false);
            }
            if(current == current_lyric.get_len_urls()){
                arrow_lyric_right.set_sensitive(false);
            }
        }

        private void change_lyric_left(){
            var current = int.parse(label_change_lyric.label);
            if(current > 1){
                change_lyric(current - 1);
                label_change_lyric.label = (current - 1).to_string();
                arrow_lyric_right.set_sensitive(true);
            }
            current = int.parse(label_change_lyric.label);
            if(current == 1){
                arrow_lyric_left.set_sensitive(false);
            }
            if(current == current_lyric.get_len_urls()){
                arrow_lyric_right.set_sensitive(false);
            }
        }

        private void change_lyric(int index_url){
            var url = current_lyric.get_url_from_index(index_url - 1);
            if(url == "" || url == null){
                return;
            }
            var new_lyric = fetcher.get_lyric_from_url(url, current_lyric);
            current_lyric = new_lyric;
            Idle.add(()=> {
                clean_text_buffer();
                return false;
            });
            Idle.add(()=> {
                insert_subtitle(new_lyric.lyric_sync);
                return false;
            });
        }


    }
}
