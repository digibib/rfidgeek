#!/usr/bin/env ruby
# websocket server (multicast):

require 'em-websocket'
require 'web_socket'
require 'logger'
require 'yaml'

CONFIG     = YAML::load_file('config/config.yml')

class WebsocketClient
  def initialize(host,port)
    @host = host
    @port = port
    @logger = Logger.new(STDOUT)
  end
  
  def run
    @logger.info "Starting testclient on ws://#{@host}:#{@port}/"
    @client = WebSocket.new("ws://#{@host}:#{@port}/")
  end

  def receive
    data = @client.receive()
    @logger.info "received data: #{data}"
  end
  
  def send(data)
    @client.send(data)
  end
  
  def close
    @client.close()
  end
end

if CONFIG['websocket']
  websocket = CONFIG['websocket']
  websocket_client = WebsocketClient.new(websocket['host'],websocket['port']).run
  while data = websocket_client.receive()
    puts "received data: #{data}"
  end
else
  puts "missing websocket config in config/config.yml"
end
