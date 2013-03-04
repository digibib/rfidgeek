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

class WebsocketServer
  
  def initialize(host,port,debug)
    @host = host
    @port = port
    @debug = debug
    @logger = Logger.new(STDOUT)
    @sockets = {}
  end
  
  def run
    @logger.info "Starting server"
    EventMachine.run do
      @logger.info "Listening on #{@host}:#{@port}"
      EventMachine::WebSocket.start(:host => @host, :port => @port, :debug => @debug) do |socket|
        socket.onopen do
          @logger.debug "socket #{socket.object_id} opened"
          @sockets[socket] = 1
        end

        socket.onmessage do |msg|
          @logger.info "received: #{msg}"
          broadcast(msg)
        end

        socket.onerror do |s|
          @logger.debug "error: #{s.inspect} #{s.backtrace}"
        end

        socket.onclose do
          @logger.debug "socket #{socket.object_id} closed"
          @sockets.delete(socket)
        end
      end

      #EventMachine::add_periodic_timer(10) { broadcast(JSON.generate({ :type => "ping" })) }

      trap("INT") do
        exit
      end
    end
  end

  def broadcast(msg)
    @sockets.keys.each { |socket| socket.send(msg) }
  end
end
