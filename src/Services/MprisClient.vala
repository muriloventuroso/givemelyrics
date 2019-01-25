/*
* Copyright (c) 2014 Ikey Doherty <ikey.doherty@gmail.com>
*               2018 elementary LLC. (https://elementary.io)
                2019 Murilo Venturoso (muriloventuroso@gmail.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace GiveMeLyrics {

    /**
     * Simple wrapper to ensure vala doesn't unref our shit.
     */
    public class MprisClient : Object {
        public PlayerIface player { construct set; get; }
        public DbusPropIface prop { construct set; get; }

        public MprisClient (PlayerIface player, DbusPropIface prop) {
            Object (player: player, prop: prop);
        }
    }

    /**
     * We need to probe the dbus daemon directly, hence this interface
     */
    [DBus (name="org.freedesktop.DBus")]
    public interface DBusImpl : Object {
        public abstract string[] list_names () throws GLib.Error;
        public signal void name_owner_changed (string name, string old_owner, string new_owner);
    }

    /**
     * Vala dbus property notifications are not working. Manually probe property changes.
     */
    [DBus (name="org.freedesktop.DBus.Properties")]
    public interface DbusPropIface : DBusProxy {
        public signal void properties_changed(string iface, HashTable<string,Variant> changed, string[] invalid);

        [DBus (name = "Get")]
        public abstract async GLib.Variant @get(string iface, string prop) throws DBusError, IOError;
        [DBus (name = "Set")]
        public abstract async void @set(string iface, string prop, GLib.Variant val) throws DBusError, IOError;
        [DBus (name = "Get")]
        public abstract GLib.Variant get_sync(string iface, string prop) throws DBusError, IOError;
        [DBus (name = "Set")]
        public abstract void set_sync(string iface, string prop, GLib.Variant val) throws DBusError, IOError;
}

    /**
     * Represents the base org.mpris.MediaPlayer2 spec
     */
    [DBus (name="org.mpris.MediaPlayer2")]
    public interface MprisIface : DBusProxy {
        public abstract async void raise() throws DBusError, IOError;
        public abstract async void quit() throws DBusError, IOError;

        public abstract bool can_quit { get; set; }
        public abstract bool fullscreen { get; } /* Optional */
        public abstract bool can_set_fullscreen { get; } /* Optional */
        public abstract bool can_raise { get; }
        public abstract bool has_track_list { get; }
        public abstract string identity { owned get; }
        public abstract string desktop_entry { owned get; } /* Optional */
        public abstract string[] supported_uri_schemes { owned get; }
        public abstract string[] supported_mime_types { owned get; }
    }

    /**
     * Interface for the org.mpris.MediaPlayer2.Player spec
     *
     * @note We cheat and inherit from MprisIface to save faffing around with two
     * iface initialisations over one
     */
    [DBus (name="org.mpris.MediaPlayer2.Player")]
    public interface PlayerIface : MprisIface {
        public abstract async void next() throws DBusError, IOError;
        public abstract async void previous() throws DBusError, IOError;
        public abstract async void pause() throws DBusError, IOError;
        public abstract async void play_pause() throws DBusError, IOError;
        public abstract async void stop() throws DBusError, IOError;
        public abstract async void play() throws DBusError, IOError;
        public abstract async void seek(int64 offset) throws DBusError, IOError;
        public abstract async void open_uri(string uri) throws DBusError, IOError;
        public abstract async void set_position(GLib.ObjectPath track_id, int64 position) throws DBusError, IOError;

        public abstract string playback_status { owned get; }
        public abstract string loop_status { owned get; set; } /* Optional */
        public abstract double rate { get; set; }
        public abstract bool shuffle { set; get; } /* Optional */
        public abstract HashTable<string,Variant> metadata { owned get; }
        public abstract double volume {get; set; }
        public abstract int64 position { get; }
        public abstract double minimum_rate { get; }
        public abstract double maximum_rate { get; }
        public abstract bool can_go_next { get; }
        public abstract bool can_go_previous { get; }
        public abstract bool can_play { get; }
        public abstract bool can_pause { get; }
        public abstract bool can_seek { get; }
        public abstract bool can_control { get; }

        public signal void seeked (int64 position);

}



}
