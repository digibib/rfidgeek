require 'rubygems'
require 'serialport'
require 'yaml'

CONFIG     = YAML::load_file('config/config.yml')
RFIDCODES  = YAML::load_file(CONFIG['rfidcodes']['file'])
SERIALPORT = CONFIG['serialport']

def start_reader
  @sp = SerialPort.new(SERIALPORT['usb_port'], SERIALPORT['baud_rate'], SERIALPORT['data_bits'], SERIALPORT['stop_bits'], SerialPort::module_eval("#{SERIALPORT['parity']}"))
  @sp.read_timeout = 100
end

def initialize_reader
  initcodes = RFIDCODES['initcodes']
 # send init
 @sp.write initcodes['init']
 @sp.read
 # send set protocol: Register write request.
 @sp.write initcodes['register_write_request']
 @sp.read
 
 # 0xF0 AGC selection 
 # 0x00 – AGC enable
 # @sp.write initcodes['agc_enable']
 
 # 0xF1 AM/PM input selection 
 # 0xFF – AM input
 # @sp.write initcodes['am_input']
end


def rfid_get_word(tag)
 # get response given in brackets
 tag = tag.match(/\[(.+)\]/).to_s
 # remove brackets
 tag.gsub!(/\[|\]/, "")
 # split every two char to get hex bytes
 ary = tag.split(/(\w{2})/)
 ary.delete_if {|c| c.empty? }
 # first byte is response code "00"
 ary.shift
 
 ary.collect! { | byte | byte = byte.hex.chr }
 ary.join
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
   :bytes > one byte + 1 (00 = 1)
=end
  case protocol
    when "iso15693"
      unless options[:flags] then options[:flags] = "00" end
      unless options[:command_code] then options[:command_code] = "00" end
      unless options[:offset] then options[:offset] = "00" end
      unless options[:bytes] then options[:bytes] = "00" end
    when "iso14443"
      #
  end
# iso15693
  command = "01" + cmd_length.to_s + "000304" + cmd.to_s + options[:flags] + options[:command_code] + options[:offset] + options[:bytes] + "0000"
# iso14443 
#  command = "01" + cmd_length.to_s + "000304" + cmd.to_s

  #p command
  @sp.write command.to_s
  response = @sp.read
end

=begin
  start main process
=end

  start_reader.inspect
  initialize_reader

  # 0x18 - Request command
  # params: flags, command code, data
  # command code 0x20 - read single block
  # response: 00 no tag error, 11 11 11 11 tag block data, 32 bits
  # tip: "%02X" % num - makes binary string out of fixed number

  # issuing 010C00030418002301020000 - ISO15693
  @bytes = 0 # actually means 1
  @offset = 1
  @length = 5
  @result = ""
while true do
  
  iso15693_response = issue_command("iso15693", "18", "0C", :command_code => "23", :offset => "%02X" % @offset, :bytes => "%02X" % @bytes)
  #iso14443A_reqa = issue_command("iso14443", "A0", "09")

  match = rfid_get_word(iso15693_response)
  unless match.empty? 
    @result += match
    @offset += @bytes + 1
    
    break if match == "W_OK"
    break if @offset == @length
  else
    sleep 3
    #puts "no reply"
  end

#  match = rfid_get_word(iso14443A_reqa)
end
strekkode = @result[1,14]
tittelnummer = @result[6,6]
puts "strekkode: " + strekkode
puts "tittelnummer: " + tittelnummer
# xdotool sends reply to browser
`xdotool search --classname Navigator windowactivate --sync type --delay 5 --args 1 "#{tittelnummer}" key Return`
#p @result
@sp.close  
