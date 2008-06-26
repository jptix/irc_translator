$KCODE = 'UTF8'
require "rubygems"
require File.dirname(__FILE__) + "/translate"
require 'rbot/rfc2812'
require 'rbot/ircsocket'
require 'rbot/timer'
require "rbot/config"
require 'rbot/message'

HOST = "irc.efnet.no"
NICK = 'tolk'
FROM = 'jp.tix'
SOURCE_CHANNEL = "#mac1"
DESTINATION_CHANNEL = "#mac2"

def debug(message=nil)
  print "DEBUG: #{message}\n" if message
end


class TranslatorBot
  attr_reader :nick, :socket, :client, :threads
  
  def initialize(nick)
    @socket = Irc::IrcSocket.new(HOST, 6667, false)
    @client = Irc::IrcClient.new
    @nick = nick
    @client[:welcome] = proc do |data|
      @socket.queue "JOIN #{SOURCE_CHANNEL}"
    end
    @threads = []
    @translator = Translate.new
    
    @from_lang = :norwegian
    @to_lang = :english
  end
  
  def connect
    @socket.connect
    @socket.emergency_puts "NICK #{@nick}\nUSER #{@nick} 4 #{FROM} :google_translator by jp_tix"
    @socket.emergency_puts "JOIN #{SOURCE_CHANNEL}"
    @socket.emergency_puts "JOIN #{DESTINATION_CHANNEL}"
    @threads << Thread.start(self) do |bot|
      loop do
        while bot.socket.connected?
          if bot.socket.select
            break unless reply = bot.socket.gets
            bot.parse(reply)
            bot.client.process reply
          end
        end
      end
    end
  end
  
  def msg(type, where, message)
    @socket.queue("#{type} #{where} :#{message}")
  end
  def say(message)
    msg("PRIVMSG", DESTINATION_CHANNEL, message)
  end
  def action(message)
    msg("PRIVMSG", DESTINATION_CHANNEL, "\001ACTION #{message}\001")
  end
  def renick(name)
    @nick = name
    @socket.queue("NICK #{@nick}")
  end
  def quit(message)
    @socket.emergency_puts "QUIT :#{message}"
    @socket.flush
    @socket.shutdown
  end
  
  def parse(string)
    case string
    when /:(.+?)!\S+?@\S+? PRIVMSG #{SOURCE_CHANNEL} :(\001ACTION)?(.*)\001?/
      nick, act, msg = $1, $2, $3
      if act
        action("#{nick} --> " + @translator.trans(msg, @from_lang, @to_lang).to_s)
      else
        say "#{nick} --> " + @translator.trans(msg, @from_lang, @to_lang).to_s
      end
    when /:jp_tix!markus@rykroken.org PRIVMSG #{DESTINATION_CHANNEL} :set (.+?) (.*)/
      @from_lang, @to_lang = $1.to_sym, $2.to_sym
      puts "changing language to #{@from_lang} -> #{@to_lang}"
    end
  end
end

if __FILE__ == $0
  $stdout.sync = true
  bot = TranslatorBot.new('tolk')
  bot.connect
  bot.threads.each { |t| t.join }
end