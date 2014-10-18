#!/usr/bin/env python

# TODO use https://github.com/denysonique/ruby-libappindicator

import os
import gobject
import gtk
import appindicator

DESKTOPS_PATH='/home/mateus/desktops'

def change_desktop(w, desktop):
  os.system("desktop show " + desktop)

def get_desktops():
  desktops = {}
  desktops_path = os.path.abspath(DESKTOPS_PATH)

  for filename in os.listdir(desktops_path):
    path = os.path.join(desktops_path, filename)
    if os.path.islink(path):
      desktops[filename] = path

  return desktops
  
def get_menu(desktops):
  menu = gtk.Menu()

  for desktop in desktops:
    menu_item = gtk.MenuItem(desktop)
    menu_item.connect("activate", change_desktop, desktops[desktop])
    menu_item.show()   
    menu.append(menu_item)  

  return menu

  
def get_appindicator():
  ind = appindicator.Indicator("uou-gnome",
                              "tray-message",
                              appindicator.CATEGORY_APPLICATION_STATUS)
  ind.set_status (appindicator.STATUS_ACTIVE)
  ind.set_icon ("preferences-desktop-peripherals-directory")
  
  return ind  


if __name__ == "__main__":
  desktops  = get_desktops() 
  menu      = get_menu(desktops)
  indicator = get_appindicator()
  indicator.set_menu(menu)
  gtk.main()
  
