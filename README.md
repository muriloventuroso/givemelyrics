[![Translation status](https://hosted.weblate.org/widgets/givemelyrics/-/translations/svg-badge.svg)](https://hosted.weblate.org/engage/givemelyrics/?utm_source=widget)

<h1 align="center">Give Me Lyrics</h1>

See the lyrics of the song that is playing, from any application.

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.muriloventuroso.givemelyrics"><img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter" /></a>
</p>

### Online Sources

* Lyrics Wikia
* API Seeds

### Donate
<a href="https://www.paypal.me/muriloventuroso">PayPal</a> | <a href="https://www.patreon.com/muriloventuroso">Patreon</a>

![Screenshot](data/screenshot.png)


[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.muriloventuroso.givemelyrics)


## Developing and Building

If you want to hack on and build EasySSH yourself, you'll need the following dependencies:

* libgtk-3-dev
* libgranite-dev
* meson
* valac
* libxml2-dev
* libsoup2.4-dev
* libjson-glib-dev

Run `meson build` to configure the build environment and run `ninja test` to build and run automated tests

    meson build --prefix=/usr
    cd build
    ninja test

To install, use `ninja install`, then execute with `com.github.muriloventuroso.givemelyrics`

    sudo ninja install
    com.github.muriloventuroso.givemelyrics


## Install with Flatpak

Install:

    flatpak install flathub com.github.muriloventuroso.givemelyrics

Run:

    flatpak run com.github.muriloventuroso.givemelyrics


-----

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.muriloventuroso.givemelyrics)

