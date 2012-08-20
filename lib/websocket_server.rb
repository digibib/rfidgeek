#!/usr/bin/env ruby
# websocket server (multicast):

require 'em-websocket'
require 'web_socket'
require 'logger'

class WebsocketClient
  def initialize(host,port)
    @host = host
    @port = port
  end
  
  def run
    @client = WebSocket.new("ws://#{@host}:#{@port}/ws")
  end

  def send(data)
    @client.send(data)
  end
  
  def close
    @client.close()
  end
end
