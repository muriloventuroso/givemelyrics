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

    public class LyricsAPI : GLib.Object {
        public LyricsAPI  () {

        }

    }

    public class LyricsFetcher : GLib.Object {

        private string[] lyrics_apis = {};

        public LyricsFetcher () {
            lyrics_apis += "music_163";
            lyrics_apis += "letras_mus";
            lyrics_apis += "lyrics_wikia";
            lyrics_apis += "api_seeds";
        }

        private Lyric? get_music_163(string title, string artist){
            var 163_url = "http://music.163.com/api/search/pc?offset=0&limit=1&type=1&s=";
            var session = new Soup.Session ();
            session.timeout = 5;
            var url = 163_url + title + "," + artist;
            var message = new Soup.Message ("GET", url);
            /* send a sync request */
            session.send_message (message);
            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) message.response_body.flatten ().data, -1);

                var root_object = parser.get_root ().get_object ();
                if(root_object.get_int_member ("code") == 200){
                    var result = root_object.get_object_member ("result");
                    var songs = result.get_array_member ("songs");
                    if(songs.get_elements().length() > 0){
                        var song = songs.get_object_element(0);
                        var song_id = song.get_int_member("id");
                        163_url = "https://music.163.com/api/song/lyric?os=pc&lv=-1&kv=-1&tv=-1&id=";
                        session = new Soup.Session ();
                        session.timeout = 5;
                        url = 163_url + song_id.to_string();
                        message = new Soup.Message ("GET", url);
                        /* send a sync request */
                        session.send_message (message);
                        try {
                            parser = new Json.Parser ();
                            parser.load_from_data ((string) message.response_body.flatten ().data, -1);

                            root_object = parser.get_root ().get_object ();
                            if(root_object.has_member ("lrc")){
                                var lyric = new Lyric();
                                var lrc = root_object.get_object_member ("lrc");
                                var string_lyric = lrc.get_string_member ("lyric");
                                var result_lyric_sync = "";
                                var result_lyric = "";
                                var split_lyric = string_lyric.split("\n");
                                GLib.Regex exp = /\[(.*?)\](.*)/;
                                for(var i = 0;i < split_lyric.length; i++){
                                    GLib.MatchInfo mi;
                                    exp.match (split_lyric[i], 0, out mi);
                                    mi.matches();
                                    var fetch_position = mi.fetch (1);
                                    var position = "";
                                    if(fetch_position != null){
                                        var position_split = fetch_position.split(":");
                                        if(position_split.length > 0){
                                            if(position_split[1] == "00.000"){
                                                continue;
                                            }
                                            position = (int.parse(position_split[1].split(".")[0]) + (int.parse(position_split[0]) * 60)).to_string();
                                            if(result_lyric_sync != ""){
                                                result_lyric_sync += "|-|" + position + "\n";
                                            }
                                        }
                                    }
                                    result_lyric_sync += mi.fetch (2) + "|-|" + position;

                                    result_lyric += mi.fetch (2) + "\n";
                                }
                                lyric.lyric = result_lyric;
                                lyric.current_url = "https://music.163.com";
                                lyric.lyric_sync = result_lyric_sync;
                                return lyric;
                            }

                        } catch (Error e) {
                            print ("I guess something is not working...\n");
                            return null;
                        }
                    }
                }


            } catch (Error e) {
                stderr.printf ("I guess something is not working...\n");
                return null;
            }
            return null;
        }

        private Lyric? get_api_seeds(string title, string artist){
            var seeds_url = "https://orion.apiseeds.com/api/music/lyric/";
            var api_key = "DasGEcpYgIQRlcEEs0reSyuvn9uIcvisOaFW1QiVK7uS3mPpYL7Qb25YmPIVl60r";
            var session = new Soup.Session ();
            session.timeout = 5;
            var url = seeds_url + artist + "/" + title + "/?apikey=" + api_key;
            var message = new Soup.Message ("GET", url);

            /* send a sync request */
            session.send_message (message);
            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) message.response_body.flatten ().data, -1);

                var root_object = parser.get_root ().get_object ();
                if(!root_object.has_member("error")){
                    var result = root_object.get_object_member ("result");
                    var track = result.get_object_member ("track");
                    var text = track.get_string_member("text");
                    var lyric = new Lyric();
                    lyric.lyric = text;
                    lyric.current_url = "";
                    return lyric;
                }


            } catch (Error e) {
                stderr.printf ("I guess something is not working...\n");
                return null;
            }
            return null;
        }

        private Lyric? get_lyrics_wikia(string title, string artist){
            var seeds_url = "http://lyrics.wikia.com/wiki/";
            var session = new Soup.Session ();
            session.timeout = 5;
            var url = seeds_url + artist.replace("&apos;", "'").replace("&amp;", "e") + ":" + title;
            var message = new Soup.Message ("GET", url);

            /* send a sync request */
            session.send_message (message);

            // parse html
            var html_cntx = new Html.ParserCtxt();
            html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
            var result_string = (string) message.response_body.flatten ().data;

            var doc = html_cntx.read_doc(result_string.replace("<br />", "\n"), "");
            var lyricbox = getValue(doc, "//div[contains(@class, 'lyricbox')]");

            if(lyricbox == null){
                return null;
            }
            if(lyricbox.contains("Unfortunately, we are not licensed to display the full lyrics for this song at the moment.")){
                return null;
            }
            var lyric = new Lyric();
            lyric.lyric = lyricbox;
            lyric.current_url = url;
            return lyric;
        }

        private Lyric? get_letras_mus(string title, string artist){
            var letras_url = "https://m.letras.mus.br/";
            var session = new Soup.Session ();
            session.timeout = 5;
            var url = letras_url + artist.replace(" ", "-").replace("&apos;", "-").replace("&amp;", "e") + "/" + title.replace(" ", "-").split("(")[0];
            var message = new Soup.Message ("GET", url);

            /* send a sync request */
            session.send_message (message);

            // parse html
            var html_cntx = new Html.ParserCtxt();
            html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
            var result_string = (string) message.response_body.flatten ().data;

            var doc = html_cntx.read_doc(result_string.replace("<br/>", "\n").replace("</p><p>", "\n\n").replace("<p>", "").replace("</p>", ""), "");

            // check song
            var check_song = getValue(doc, "//div[contains(@class, 'lyric-title')]//h1");

            if(check_song == null || check_song.down().contains(title.down()) == false){
                return null;
            }

            var lyricbox = getValue(doc, "//div[contains(@class, 'lyric-tra_l')]");
            var remove_first_line = false;
            if(lyricbox == null){
                lyricbox = getValue(doc, "//div[contains(@class, 'lyric-cnt')]");

                if(lyricbox == null){
                    return null;
                }
            }else{
                remove_first_line = true;
            }

            if(lyricbox.contains("Essa música foi removida em razão de solicitação do(s) titular(es) da obra.")){
                return null;
            }
            var array_subtitle = "";
            var lyric = new Lyric();
            if(settings.sync_lyrics == true){
                var script = getValue(doc, "//div[@id='js-scripts']//script");
                var song_id = script.split(",")[1].split(":")[1];
                foreach(var subtitle_id in get_lyrics_available_letras(song_id)){
                    if(subtitle_id != ""){
                        var c_url = "https://www.letras.mus.br/subtitle/" + song_id + "/" + subtitle_id;
                        lyric.add_url(c_url);
                        if(array_subtitle == ""){
                            array_subtitle = get_sync_lyric_letras(c_url);
                            lyric.current_sync_url = c_url;
                        }
                    }
                }
            }
            if(remove_first_line == true){
                Regex regex = new GLib.Regex ("^" + check_song);
                lyricbox = regex.replace (lyricbox, lyricbox.length, 0, "");
                lyricbox = lyricbox.strip();
            }
            lyric.lyric = lyricbox;
            lyric.current_url = url;
            lyric.lyric_sync = array_subtitle;
            return lyric;
        }

        private string[] get_lyrics_available_letras(string song_id){
            string[] result = {};
            var letras_url = "https://www.letras.mus.br/subtitle/";
            var url = letras_url + song_id;
            var session = new Soup.Session ();
            session.timeout = 5;
            var message = new Soup.Message ("GET", url);
            /* send a sync request */
            session.send_message (message);
            if(message.status_code != 200){
                return result;
            }

            try {
                var parser = new Json.Parser ();
                var data = (string) message.response_body.flatten ().data;
                if(data.length < 10 || data == ""){
                    return result;
                }
                parser.load_from_data ("{\"subtitle\":" + data+ "}", -1);
                var root_object = parser.get_root ().get_object ();

                if(root_object.has_member("subtitle")){
                    var array_sub = root_object.get_array_member("subtitle");
                    foreach(var row in array_sub.get_elements()){
                        result += row.dup_string();
                    }
                }

            }catch(Error e){
                print(e.message);
            }

            return result;
        }

        private string get_sync_lyric_letras(string url){
            var result = "";
            var session = new Soup.Session ();
            session.timeout = 5;
            var message = new Soup.Message ("GET", url);
            /* send a sync request */
            session.send_message (message);

            try {
                var parser = new Json.Parser ();
                var data = (string) message.response_body.flatten ().data;
                if(data.length < 10 || data == ""){

                    return result;
                }
                parser.load_from_data (data, -1);
                var root_object = parser.get_root ().get_object ();
                if(root_object.has_member("Original")){
                    var original = root_object.get_object_member ("Original");
                    if(original.has_member("Subtitle")){
                        var subtitle = original.get_string_member ("Subtitle");
                        var parser_sub = new Json.Parser ();
                        parser_sub.load_from_data ("{\"subtitle\":" + subtitle.replace("\\\"", "") + "}", -1);
                        var root_subtitle = parser_sub.get_root ().get_object ();
                        var array_sub = root_subtitle.get_array_member("subtitle");
                        foreach(var row in array_sub.get_elements()){
                            var array = row.get_array();
                            var lyric = array.get_element(0).dup_string();
                            var start = array.get_element(1).dup_string();
                            var end = array.get_element(2).dup_string();
                            result += lyric + "|-|" + start + "|-|" + end + "\n";
                        }
                    }
                }
            }catch(Error e){
                print(e.message);
            }

            return result;
        }

        public Lyric? get_lyric(string title, string artist){
            Lyric? r = null;
            var n_title = remove_accents(title.replace("?", "").down());
            var n_artist = remove_accents(artist.down());
            foreach (var s_api in lyrics_apis) {
                if(s_api == "music_163"){
                    r = get_music_163(n_title, n_artist);
                }else if(s_api == "api_seeds"){
                    r = get_api_seeds(n_title, n_artist);
                }else if(s_api == "lyrics_wikia"){
                    r = get_lyrics_wikia(n_title, n_artist);
                }else if(s_api == "letras_mus"){
                    r = get_letras_mus(n_title, n_artist);
                }else{
                    return null;
                }
                if(r == null){
                    continue;
                }
                if(r.lyric != ""){

                    break;
                }

            }
            if(r != null){
                r.title = title;
                r.artist = artist;
            }
            return r;
        }

        public Lyric get_lyric_from_url(string url, Lyric lyric){
            if(url.contains("letras.mus.br")){
                var sub = get_sync_lyric_letras(url);
                lyric.lyric_sync = sub;
            }
            return lyric;
        }


        public static string? getValue(Html.Doc* doc, string xpath, bool remove = false){
            Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
            Xml.XPath.Object* res = cntx.eval_expression(xpath);

            if(res == null)
            {
                return null;
            }
            else if(res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
            {
                delete res;
                return null;
            }

            Xml.Node* node = res->nodesetval->item(0);
            string result = cleanString(node->get_content());

            if(remove)
            {
                node->unlink();
                node->free_list();
            }

            delete res;
            return result;
        }

        public static string cleanString(string? text){
            if(text == null)
                return "";
            var tmpText =  text;
            var array = tmpText.split(" ");
            tmpText = "";

            foreach(string word in array)
            {
                if(word.chug() != "")
                {
                    tmpText += word + " ";
                }
            }

            return tmpText.chomp();
        }

        private string remove_accents(string input){
            var new_string = input.replace("ê", "e").replace("á", "á").replace("à", "à").replace("ã", "a").replace("ó", "o").replace("ç", "c").replace("í", "i").replace("ú", "u").replace("å", "a").replace("ö", "o");
            return new_string;
        }
    }
}
