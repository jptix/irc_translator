$KCODE = 'UTF8'
require "rubygems"
require File.dirname(__FILE__) + "/translate"
require 'rbot/rfc2812'
require 'rbot/ircsocket'
require 'rbot/timer'
require "rbot/config"
require 'rbot/message'

def debug(message=nil)
  print "DEBUG: #{message}\n" if message
end

class TranslatorBot
  
  def initialize(config = {})
    @config = config
    @socket = Irc::IrcSocket.new(@config[:host], @config[:port] || 6667, false)
    @client = Irc::IrcClient.new
    @nick = @config[:nick] || 'translator'
    @client[:welcome] = proc do |data|
      @socket.queue "JOIN #{@config[:source_channel]}"
      @socket.emergency_puts "JOIN #{@config[:destination_channel]}"
    end
    @threads = []
    @translator = Translate.new
    
    @from_lang = @config[:from_lang] || :norwegian
    @to_lang = @config[:to_lang] || :english
  end
  
  def connect
    @socket.connect
    @socket.emergency_puts "NICK #{@nick}\nUSER #{@nick} 4 #{@config[:from] || 'jp.tix'} :google_translator by jp_tix"
    @socket.emergency_puts "JOIN #{@config[:source_channel]}"
    @socket.emergency_puts "JOIN #{@config[:destination_channel]}"
    loop do
      while @socket.connected?
        if @socket.select
          break unless reply = @socket.gets
          parse(reply)
          @client.process reply
        end
      end
    end
  end
  
  def msg(type, where, message)
    @socket.queue("#{type} #{where} :#{message}")
  end

  def say(message)
    msg("PRIVMSG", @config[:destination_channel], message)
  end

  def action(message)
    msg("PRIVMSG", @config[:destination_channel], "\001ACTION #{message}\001")
  end

  def quit(message)
    @socket.emergency_puts "QUIT :#{message}"
    @socket.flush
    @socket.shutdown
  end
  
  def parse(string)
    case string
    when /:(.+?)!\S+?@\S+? PRIVMSG #{@config[:source_channel]} :(\001ACTION)?(.*)\001?/
      nick, act, reply = $1, $2, @translator.trans($3, @from_lang, @to_lang).to_s
      reply = "#{nick} --> #{reply}"
      act ? action(reply) : say(reply)
    when /:#{@config[:admin_nick] || 'jp_tix'}!\S+? PRIVMSG #{@config[:destination_channel]} :set (.+?) (.*)/
      @from_lang, @to_lang = $1.to_sym, $2.to_sym
      say "changing language: #{@from_lang} -> #{@to_lang}"
    end
  end
end

if __FILE__ == $0
  $stdout.sync = true
  config = {
    :host                => "irc.freenode.net",
    :nick                => 'tolk',
    :source_channel      => "#ubuntu",
    :destination_channel => "#jp_tix",
    :admin_nick          => "jp_tix",
  }
  TranslatorBot.new(config).connect
end