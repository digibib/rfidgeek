require 'rubygems'
require 'serialport'
require 'yaml'

CONFIG     = YAML::load_file('config/config.yml')
RFIDCODES  = YAML::load_file(CONFIG['rfidcodes']['config_file'])
SERIALPORT = CONFIG['serialport']

$debug = CONFIG['debug']
require_relative './lib/websocket_server.rb'

def initialize_serialport
  @sp = SerialPort.new(SERIALPORT['usb_port'], SERIALPORT['baud_rate'], SERIALPORT['data_bits'], SERIALPORT['stop_bits'], SerialPort::module_eval("#{SERIALPORT['parity']}"))
  @sp.read_timeout = 100
end

def initialize_reader
  # send init
  @sp.write RFIDCODES['initialize']['init']
  @sp.read
end

def initialize_request(initcodes)
  initcodes.each { |k,v| @sp.write v; @sp.read.inspect } 
end

def get_response(r)
  # get response given in brackets
  r = r.match(/\[(.+)\]/).to_s
  # remove brackets
  response = r.gsub(/\[|\]/, "")
end

def get_tag(r)
  tag = r.sub(/,../, "")
end

def get_bytes(r)
 # split every two char to get hex bytes
 ary = r.split(/(\w{2})/)
 ary.delete_if {|c| c.empty? }
 # first byte is response code "00"
 ary.shift
 
 ary.collect! { | byte | byte = byte.hex.chr }
 response = ary.join
end

def issue_command(protocol, cmd, cmd_length, options={})
=begin
 function to issue command with options
 protocol standard
 cmd = hex byte in string form
 cmd_length: length of command in hex
 options are:
   :flags => one byte
   :command_code => subcommand
   :offset => offset, one byte
   :byte_length > one byte + 1 (00 = 1)
=end
  case protocol
    when "iso15693"
      unless options[:flags] then options[:flags] = "00" end
      unless options[:command_code] then options[:command_code] = "00" end
      unless options[:offset] then options[:offset] = "00" end
      unless options[:bytes_per_read] then options[:bytes_per_read] = "00" end
      
      @command = "01" + cmd_length.to_s + "000304" + cmd.to_s + options[:flags] + options[:command_code] + options[:offset] + options[:bytes_per_read] + "0000"
    when "iso14443"
      # iso14443 
      @command = "01" + cmd_length.to_s + "000304" + cmd.to_s
  end

  @sp.write @command.to_s
  response = @sp.read
end

=begin
  start main process
=end

  initialize_serialport.inspect
  initialize_reader

  # setup websocket server, imported from ./lib/websocket_server.rb
  # we need to daemonize server to a fork
  
if CONFIG['websocket']
  websocket = CONFIG['websocket']
  #websocket_server = fork do
  #  WebsocketServer.new(websocket['host'],websocket['port'],websocket['debug']).run
  #end
  #sleep 0.5 # to allow server to initialize
  websocket_client = WebsocketClient.new(websocket['host'],websocket['port']).run
end

  # 0x18 - Request command
  # params: flags, command code, data
  # command code 0x20 - read single block
  # response: 00 no tag error, 11 11 11 11 tag block data, 32 bits
  # tip: "%02X" % num - makes binary string out of any two digits

  # issuing 010C00030418002301020000 - ISO15693
@tag = ""
# loops until tag is found
while true do
  CONFIG['knowntags'].each do | tagname, tagsettings |
    protocol = tagsettings['protocol']
  #RFIDCODES['protocols'].each do | protocol, values |
    case protocol
    when "14443A"
#      puts "initializing ..." + protocol 
#      values['initcodes'].each { |k,v| @sp.write v; @sp.read.inspect } 
#      @sp.write values['inventory']
#      puts "response ..." + protocol 
#      p @sp.read
    when "iso15693"
      rfidcodes = RFIDCODES['protocols'][protocol]
      #puts "initializing ... " + protocol 
      initialize_request(rfidcodes['initcodes'])
      
      # read rfid tag uid
      @sp.write rfidcodes['inventory']
      res = @sp.read
      r = get_response(res)
      tag = get_tag(r)
      if !tag.empty? and @tag != tag and tag.length == 16
        puts "found tag: #{tag}" if $debug
        @tag = tag
        initialize_request(rfidcodes['initcodes'])
        bytes_per_read = tagsettings['bytes_per_read']
        offset = tagsettings['start_offset']
        length_to_read = tagsettings['length_to_read']
        @result = ""
        # read rfid content
        while true do
          read = issue_command(protocol, "18", "0C", :command_code => "23", :offset => "%02X" % offset, :bytes_per_read => "%02X" % bytes_per_read)
          response = get_response(read)
          if !response.empty? 
            @result += get_bytes(response)
            offset += bytes_per_read + 1
            break if response == "W_OK"
            break if offset == length_to_read
          end
        end
        puts "rfidresult: " + @result.inspect if $debug
        tagsettings['extract_values'].each do | name, options |
          puts "#{name}: " + @result[options['offset'],options['length']] if $debug
          if tagsettings['send_to_browser'][name]
            # unix tool xdotool can send response to browser
            #`xdotool search --classname Navigator windowactivate --sync type --delay 5 --args 1 "#{@result[options['offset'],options['length']]}" key Return`
            
            # send tag to websocket sinatra-app
            websocket_client.send("#{@result[options['offset'],options['length']]}")
          end
        end
      else
        puts "...reading..." if $debug
      end 
    end # end case protocol
  end
  #sleep 3 # sleep before next loop

  # catch CTRL-C to kill server and websocket
  trap("INT") do
    Process.kill("INT", websocket_client)
    exit
  end
end  

@sp.close  
