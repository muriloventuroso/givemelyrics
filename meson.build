# project name and programming language
project('com.github.muriloventuroso.givemelyrics', 'vala', 'c', version: '0.4.0')
message ('project name and programming language')
cc = meson.get_compiler('c')
# Adds project arguments
message ('Adds project arguments')
gnome = import('gnome')
add_project_arguments([
        '-DGETTEXT_PACKAGE=\"@0@\"'.format(meson.project_name()),
        '-lm'
    ],
    language: 'c',
)
asresources = gnome.compile_resources(
    'as-resources', 'data/com.github.muriloventuroso.givemelyrics.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)
install_data('data/com.github.muriloventuroso.givemelyrics.gschema.xml', install_dir : join_paths(get_option('datadir'), 'glib-2.0/schemas/'))

# Include the translations module
message('Include the translations module')

i18n = import('i18n')

# Set our translation domain
message ('Set our translation domain')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')

# Adding deps
message ('Listing dependencies')

dependencies = [
    dependency('glib-2.0', version: '>=2.30.0'),
    dependency('gtk+-3.0'),
    dependency('gio-unix-2.0', version: '>=2.20'),
    dependency('granite'),
    dependency('libsoup-2.4', version: '>=2.44'),
    dependency('json-glib-1.0'),
    dependency('libxml-2.0'),
    cc.find_library('m', required : false)

]

# Adds subfolders specific build system
message ('Adds subfolders specific build system')



config_data = configuration_data()
config_data.set('EXEC_NAME', meson.project_name())

# Src build
message ('Src build')

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))


message ('Adds files to build')

code_files = files(
    'src/Application.vala',
    'src/Services/MprisClient.vala',
    'src/Widgets/LyricsWidget.vala',
    'src/Widgets/Preferences.vala',
    'src/Services/LyricsFetcher.vala',
    'src/Services/Settings.vala',
    'src/Lyric.vala',
    'src/MainWindow.vala'
)

message ('Defines executable')

executable(
    meson.project_name(),
    code_files,
    asresources,
    dependencies: dependencies,
    install: true
)
subdir('po')
subdir('data')

meson.add_install_script('meson/post_install.py')
