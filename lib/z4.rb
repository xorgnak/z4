# frozen_string_literal: true

['DISCORD_CLIENT_ID''DISCORD_CLIENT_SECRET','DISCORD_APPLICATION_ID','DISCORD_TOKEN','DISCORD_PERMISSIONS'].each do |env|
  if ENV[env] == ''
    puts "set '#{env}' in env.sh to continue.  z4 can't help you without it."
    exit
  end
end







require 'browser'
require 'discordrb'
require 'sinatra/base'
require 'gdbm'
require 'json'
require 'paho-mqtt'
require 'rotp'
require 'openssl'

require_relative "z4/version"
require_relative "z4/utils"
require_relative "z4/levels"
require_relative "z4/org"
require_relative "z4/db"
require_relative "z4/tables"
require_relative "z4/broker"
require_relative "z4/host"
require_relative "z4/app"
require_relative "z4/bot"

module Z4
  class Error < StandardError; end
  def self.stop o
    o.stop!
  end
  def self.stop!
    exit
  end
  def self.init!
    puts "[BROKER]"
    Z4Broker.init!
    puts "[BOT]"
    fork { Z4Bot.init! }
    puts "[APP]"
    fork { Z4App.init! }
  end
end

if ARGF.argv[0] && File.exists?(ARGF.argv[0])
  begin
    load ARGF.argv[0]
  rescue => e
    puts %[loadError in #{ARGF.argv[0]}]
  end
else
  ["bot.rb","world.rb"].each {|e|
    if File.exists?(e);
      puts "loading #{e}";
      begin
        load e;
      rescue
        puts %[loadError in #{e}]
      end
    end
  }
end

Z4.init!

at_exit do
  puts "BYE"
end
