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
  
  UTF8_REGEXP = / \A (?: [\x00-\x7F] | [\xC2-\xDF] [\x80-\xBF] | [\xE1-\xEF] [\x80-\xBF]{2} |                                                                                           
                         [\xF1-\xF7] [\x80-\xBF]{3} | [\xF9-\xFB] [\x80-\xBF]{4} |                                                                                                      
                         [\xFD-\xFD] [\x80-\xBF]{5} ) \Z /x
  
  HEADERS = {
    "User-Agent" => "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.9) Gecko/20071025 Firefox/2.0.0.9",
    "Connection" => "Keep-Alive",
    "Keep-Alive" => "30"
  }

  def initialize
    @conv = Iconv.new('utf-8', 'iso-8859-1')
  end

  def trans(text, from, to)
    begin
      pair = "#{LANGS[from]}|#{LANGS[to]}" 
      text = utf?(text) ? text : @conv.iconv(text)
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
  
  private
  
  def utf?(str)
    str.split(//u).all? { |c| c =~ UTF8_REGEXP }
  end
  
end

if __FILE__ == $0
  p Translate.new.trans("gjør de?", :norwegian, :chinese)
end