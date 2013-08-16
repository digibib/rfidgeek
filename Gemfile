source "http://rubygems.org"
gem "builder"
gem "em-websocket"
gem "web-socket-ruby"
gem "logger"

platforms :jruby do
  gem "jruby-serialport", :git => "https://github.com/pmukerji/jruby-serialport.git", :require => "serialport"
end

platforms :ruby do
  gem "serialport"
end
