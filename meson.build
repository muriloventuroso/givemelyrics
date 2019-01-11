# project name and programming language
project('com.github.muriloventuroso.givemelyrics', 'vala', 'c', version: '0.1.2')

message ('project name and programming language')

# Adds project arguments
message ('Adds project arguments')
gnome = import('gnome')
add_project_arguments([
        '-DGETTEXT_PACKAGE=\"@0@\"'.format(meson.project_name())
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
    dependency('gio-unix-2.0', version: '>=2.20'),
    dependency('granite'),
    dependency('libsoup-2.4', version: '>=2.44'),
    dependency('json-glib-1.0'),
    dependency('libxml-2.0')
]

# Adds subfolders specific build system
message ('Adds subfolders specific build system')

icon_sizes = ['16', '24', '32', '48', '64', '128', '256']

foreach i : icon_sizes
    install_data(
        join_paths('data/icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
    install_data(
        join_paths('data/icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps')
    )

endforeach

config_data = configuration_data()
config_data.set('EXEC_NAME', meson.project_name())

# Src build
message ('Src build')

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))

message ('Configuring desktop entry: ' + meson.project_name() + '.desktop')

desktop_in_file = configure_file(
    input: join_paths('data', meson.project_name() + '.desktop.in.in'),
    output: '@BASENAME@',
    configuration: config_data
)

desktop_file = i18n.merge_file(
    input: desktop_in_file,
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

appstream_file = i18n.merge_file(
    input: join_paths (meson.source_root(), 'data', meson.project_name() + '.appdata.xml.in'),
    output: '@BASENAME@',
    po_dir: join_paths(meson.source_root(), 'po'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

message ('Adds files to build')

code_files = files(
    'src/Application.vala',
    'src/Services/MprisClient.vala',
    'src/Widgets/LyricsWidget.vala',
    'src/Services/LyricsFetcher.vala',
    'src/Services/Settings.vala'
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
