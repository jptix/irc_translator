require "rubygems"
require "open-uri"
require "hpricot"
require "iconv"

class Translate
  LANGS              = {
    :auto                => 'auto',
    :arabic              => 'ar',
    :bulgarian           => 'bu',
    :croatian            => 'hr',
    :czechian            => 'cs',
    :danish              => 'da',
    :finnish             => 'fi',
    :chinese             => 'zh',
    :chinese_simplified  => 'zh-CN',
    :chinese_traditional => 'zh-TW',
    :dutch               => 'nl',
    :english             => 'en',
    :french              => 'fr',
    :german              => 'de',
    :greek               => 'el',
    :hindi               => 'hi',
    :italian             => 'it',
    :japanese            => 'ja',
    :korean              => 'ko',
    :norwegian           => 'no',
    :polish              => 'pl',
    :romanian            => 'ro',
    :portuguese          => 'pt',
    :russian             => 'ru',
    :spanish             => 'es',
    :swedish             => 'sv',
  }
  
  HEADERS = {
    "User-Agent" => "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.9) Gecko/20071025 Firefox/2.0.0.9",
    "Connection" => "Keep-Alive",
    "Keep-Alive" => "30"
  }

  def trans(text, from, to)
    begin
      pair = "#{LANGS[from]}|#{LANGS[to]}" 
      url = URI.escape "http://translate.google.com/translate_t?langpair=#{pair}&text=#{text}&ie=UTF8"
      puts "get   : #{url}"
      doc = Hpricot(open(url))
      res = doc.search("//div#result_box").inner_text
      puts "result: #{res}"
      res
    rescue Exception => e
      "Error: #{e.message}"
    end
  end
  
end

if __FILE__ == $0
  p Translate.new.trans "gjør de?", :norwegian, :chinese
end