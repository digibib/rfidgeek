# RFIDGEEK

    RFIDGEEK - a ruby script to read RFID tags with Univelop generic reader/writer
    Copyright (C) 2012 Benjamin Rokseth
    Reader described in (relatively inactive) http://www.rfidgeek.com/

## GPLv3 LICENSE
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>."

## Usage

ruby rfid.rb

## Installation -- use bundler and Gemfile

    gem install bundler
    bundle install

## Config

Preferably use websockets to send tag as event. Demands a websocket server to accept connections.
EventMachine server included, use config.yml to enable and set host:port

config/config.yml
* example config file (use config.yml-dist as template)
* serialport config
* HTML5 websocket server config
* yaml config for reader
* known tag setting

config/univelop_500B.yml
* example reader config file

NB! check permissions to /dev/ttyUSB0 or whatever device the reader spawns.
On Ubuntu Precise you may need to add user to group dialout.

## Reader config file

communication specifications for reader:

    initialize codes, protocol codes and inventory codes
