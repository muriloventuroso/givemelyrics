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

using Gee;

namespace GiveMeLyrics {
    public class Lyric : Object {

        /* Fields */
        public string title {get; set;}
        public string artist {get; set;}
        public string lyric {get; set;}
        public string lyric_sync {get; set;}
        private string[] urls;
        public string current_url {get; set;}
        public string current_sync_url {get; set;}

        public void add_url(string url){
            urls += url;
        }

        public int get_len_urls(){
            return urls.length;
        }

        public string get_url_from_index(int index){
            if(index > get_len_urls()){
                return "";
            }
            return urls[index];
        }

    }

}
