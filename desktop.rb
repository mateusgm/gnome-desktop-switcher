#! /usr/bin/env ruby
# encoding: utf-8

require 'json'

class Workspace

  CONFIG    = File.expand_path "~/.config/workspaces"
  DESKTOP   = File.expand_path '~/desktop'
  BOOKMARKS = File.expand_path '~/.config/gtk-3.0/bookmarks'
  IDS       = { down: [nil, 768], up: [nil, 0], right: [1366, nil], left: [0, nil] }

  # initialization

  def self.init
    dados       = get_config()
    @active     = dados['active'] || {}
    @bookmarked = dados['bookmarked'] || {}
  end

  def self.setup
    # TODO backup desktop
    # TODO create first symlink desktop
    # TODO change bookmarks
  end

  def self.install
    map_keybindings()
    `sudo apt-get install xdotool`
    `sudo cp #{__FILE__} /usr/bin/ws -f`
  end

  def self.map_keybindings
    already_created = eval(`gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings`)    
    IDS.keys.map(&:to_s).each do |k|
      already_created << "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-#{k}/"
      `gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-#{k} "['']"`
      `gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "#{already_created.uniq.to_s.gsub('"', "'")}"`
      `gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-#{k}/ binding "<Primary><Alt>#{k.capitalize}"`
      `gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-#{k}/ name "Uou Workspace #{k}"`
      `gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom-#{k}/ command "ws move #{k}"`
    end
  end

  def self.uninstall
    IDS.keys.map(&:to_s).each do |k|
      `gsettings reset org.gnome.desktop.wm.keybindings.switch-to-workspace-#{k}`
    end
  end

  # creation

  def self.active(id)
    @active[id.join('_')]
  end

  def self.set_active(id, path)
    @active[id.join('_')] = File.expand_path path
  end

  def self.bind(path, id=nil)
    id = id || get_current
    set_active id, path
    save_config()
    refresh()
  end

  def self.save(name, src)
    @bookmarked[name] = File.expand_path src
    File.open(BOOKMARKS, 'a') { |f| f << "file://#{@bookmarked[name]}"}
    save_config()
  end

  # render

  def self.move(direction)
    target    = IDS[direction.to_sym]
    notchange = target.index(nil) 
    target[notchange] = get_current[notchange]
    show active(target) unless active(target).nil?
    `xdotool set_desktop_viewport #{target.join(' ')}`
  end

  def self.refresh
    show active(get_current) unless active(get_current).nil?
  end

  def self.show(path)
    File.delete  DESKTOP if File.symlink?(DESKTOP)
    File.symlink File.expand_path(path), DESKTOP
    system "gsettings set org.nemo.preferences desktop-is-home-dir false"
  end

  private

  def self.get_current
    `xprop -root -notype _NET_DESKTOP_VIEWPORT`.gsub(',', '').split(' ')[-2..-1]
  end

  def self.save_config
    File.open(CONFIG, 'w') { |f| f << JSON.pretty_generate(as_json) }
  end

  def self.get_config
    dados = JSON.parse(File.open(CONFIG, 'r').read) if File.exists?(CONFIG)
    dados || {}
  end

  def self.as_json
    { active: @active, bookmarked: @bookmarked }
  end

end


# exec

def execute_command(name, params=[])
  case name
  when 'install' then Workspace.install()
  when 'bind'    then Workspace.bind(params[0] || Dir.pwd)
  when 'save'    then Workspace.save(params[0], params[1] || Dir.pwd)
  when 'show'    then Workspace.show(params[0] || Dir.pwd)
  when 'move'    then Workspace.move(params[0])
  else execute_command('show')
  end
end

Workspace.init()
execute_command(ARGV.shift, ARGV)