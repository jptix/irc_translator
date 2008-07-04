$KCODE = 'u'
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
    @commands = {}
    
    @socket = Irc::IrcSocket.new(@config[:host], @config[:port] || 6667, false)
    @client = Irc::IrcClient.new
    @nick   = @config[:nick] || 'translator'
    
    @translator = Translate.new
    @from_lang  = @config[:from_lang] || "norwegian"
    @to_lang    = @config[:to_lang] || "english"
    @admins     = @config[:admin_nicks] ? Regexp.union(*@config[:admin_nicks]) : /jp_tix/
    
    setup_hooks
    setup_commands
  end
  
  def connect
    @socket.connect
    @socket.emergency_puts "NICK #{@nick}\nUSER #{@nick} 4 #{@config[:from] || 'jp.tix'} :google translate bot by jp_tix"
    @socket.emergency_puts "JOIN #{@config[:source_channel]}"
    @socket.emergency_puts "JOIN #{@config[:target_channel]}"
    loop do
      while @socket.connected?
        if @socket.select
          break unless reply = @socket.gets
          @client.process reply
          parse(reply)
        end
      end
    end
  end
  
  def msg(type, where, message)
    @socket.queue("#{type} #{where} :#{message}")
  end

  def say(message)
    msg("PRIVMSG", @config[:target_channel], message)
  end

  def action(message)
    msg("PRIVMSG", @config[:target_channel], "\001ACTION #{message}\001")
  end
  
  def op(nick)
    @socket.queue("MODE #{@config[:target_channel]} +o #{nick}")
  end

  def quit(message = 'bye')
    @socket.emergency_puts "QUIT :#{message}"
    @socket.flush
    @socket.shutdown
  end
  
  def parse(string)
    case string
    # source channel message 
    when /:(.+?)!\S+? PRIVMSG #{@config[:source_channel]} :(\001ACTION)?(.*)\001?/
      nick, act, reply = $1, $2, @translator.trans($3, @from_lang, @to_lang).to_s

      # hack
      nick = nick[0..(nick.size/2)] if @config[:no_highlight]

      reply = "[#{nick}] #{reply}"
      act ? action(reply) : say(reply)
    # target channel message
    when /:(#{@admins})\S+? PRIVMSG #{@config[:target_channel]} :\.(\S+)( .*)?/
      on_command($2.to_s, $3.to_s)
    # target channel joins
    when /:(.+?)!\S+? JOIN :#{@config[:target_channel]}/
      on_join($1)
    end
  end
  
  def on_command(cmd, params)
    if c = @commands[cmd]
      c.call(params)
    else
      say "no such command #{cmd.inspect}"
    end
  end
  
  def on_join(nick)
    op(nick) if @admins =~ nick
  end
  
  private
  
  def setup_hooks
    @client[:welcome] = proc do |data|
      @socket.queue "JOIN #{@config[:source_channel]}"
      @socket.queue "JOIN #{@config[:target_channel]}"
    end
    
    @client[:ping] = proc do |data|
      @socket.queue "PONG #{data[:pingid]}"
    end
  end
  
  def setup_commands
    @commands['set'] = proc do |params|
      if (params.strip.empty?)
       say "USAGE: .set <from> <to>"
      else
        from, to = params.split
        if [from, to].all? { |lang| Translate::LANGS.has_key?(lang) }
          @from_lang, @to_lang = from, to
          say "changing language: #{@from_lang} -> #{@to_lang}"
        else
          say "invalid pair: #{from} -> #{to}" 
        end
      end
    end
    
    @commands['list'] = proc do
      say "available languages: " + Translate::LANGS.keys.sort.join(', ')
    end
    
    @commands['current'] = proc { say "#{@from_lang} -> #{@to_lang}" }
    @commands['quit'] = proc { quit }
    @commands['commands'] = proc { say "commands: #{@commands.keys.sort.join(', ')}"}
  end
  
end
