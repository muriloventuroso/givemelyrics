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
            lyrics_apis += "lyrics_wikia";
            lyrics_apis += "api_seeds";
        }

        private string get_api_seeds(string title, string artist){
            var seeds_url = "https://orion.apiseeds.com/api/music/lyric/";
            var api_key = "DasGEcpYgIQRlcEEs0reSyuvn9uIcvisOaFW1QiVK7uS3mPpYL7Qb25YmPIVl60r";
            var session = new Soup.Session ();
            var url = seeds_url + artist + "/" + title + "/?apikey=" + api_key;
            print(url);
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
                    return text;
                }


            } catch (Error e) {
                stderr.printf ("I guess something is not working...\n");
            }
            return "";
        }

        private string get_lyrics_wikia(string title, string artist){
            var seeds_url = "http://lyrics.wikia.com/wiki/";
            var session = new Soup.Session ();
            var url = seeds_url + artist + ":" + title;
            print(url);
            var message = new Soup.Message ("GET", url);

            /* send a sync request */
            session.send_message (message);

            // parse html
            var html_cntx = new Html.ParserCtxt();
            html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
            var result_string = (string) message.response_body.flatten ().data;

            var doc = html_cntx.read_doc(result_string.replace("<br />", "\n"), "");
            var lyricbox = getValue(doc, "//div[contains(@class, 'lyricbox')]");
            if(lyricbox != null){
                return lyricbox;
            }
            return "";
        }

        public string get_lyric(string title, string artist){
            string song_ret = "";
            var n_title = title.replace("?", "");
            foreach (var s_api in lyrics_apis) {
                var ret = "";
                if(s_api == "api_seeds"){
                    ret = get_api_seeds(n_title, artist);
                }else if(s_api == "lyrics_wikia"){
                    ret = get_lyrics_wikia(n_title, artist);
                }
                if(ret != ""){
                    song_ret = ret;
                    break;
                }
            }
            return song_ret;
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
    }
}