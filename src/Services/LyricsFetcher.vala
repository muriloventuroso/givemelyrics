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
            lyrics_apis += "letras_mus";
            lyrics_apis += "lyrics_wikia";
            lyrics_apis += "api_seeds";
        }

        private string[] get_api_seeds(string title, string artist){
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
                    return {text, ""};
                }


            } catch (Error e) {
                stderr.printf ("I guess something is not working...\n");
                return {"", ""};
            }
            return {"", ""};
        }

        private string[] get_lyrics_wikia(string title, string artist){
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
                return {"", ""};
            }
            if(lyricbox.contains("Unfortunately, we are not licensed to display the full lyrics for this song at the moment.")){
                return {"", ""};
            }
            return {lyricbox, url};
        }

        private string[] get_letras_mus(string title, string artist){
            var letras_url = "https://www.letras.mus.br/";
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
            var lyricbox = getValue(doc, "//div[contains(@class, 'cnt-letra')]//article");

            if(lyricbox == null){
                return {"", ""};
            }

            return {lyricbox, url};
        }

        public string[] get_lyric(string title, string artist){
            string song_ret = "";
            var url = "";
            string[] r;
            var n_title = remove_accents(title.replace("?", "").down());
            var n_artist = remove_accents(artist.down());
            foreach (var s_api in lyrics_apis) {
                var ret = "";
                if(s_api == "api_seeds"){
                    r = get_api_seeds(n_title, n_artist);
                }else if(s_api == "lyrics_wikia"){
                    r = get_lyrics_wikia(n_title, n_artist);
                }else if(s_api == "letras_mus"){
                    r = get_letras_mus(n_title, n_artist);
                }else{
                    return {"", "", ""};
                }

                ret = r[0];
                url = r[1];
                if(ret != ""){
                    song_ret = ret;
                    break;
                }
            }
            return {song_ret, url, title};
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
            var new_string = input.replace("ê", "e").replace("á", "á").replace("à", "à").replace("ã", "a").replace("ó", "o").replace("ç", "c").replace("í", "i").replace("ú", "u");
            return new_string;
        }
    }
}
