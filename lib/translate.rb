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
    :swedish             => 'se',
  }
  
  UTF8_REGEXP = / \A (?: [\x00-\x7F] | [\xC2-\xDF] [\x80-\xBF] | [\xE1-\xEF] [\x80-\xBF]{2} |                                                                                           
                         [\xF1-\xF7] [\x80-\xBF]{3} | [\xF9-\xFB] [\x80-\xBF]{4} |                                                                                                      
                         [\xFD-\xFD] [\x80-\xBF]{5} ) \Z /x                                                                                                                             
  
  
  URL = 
  HEADERS = {
    "User-Agent" => "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.9) Gecko/20071025 Firefox/2.0.0.9",
    "Connection" => "Keep-Alive",
    "Keep-Alive" => "30"
  }

  def initialize
    @to_utf8 = Iconv.new('utf-8', 'iso-8859-1')
    @from_utf8 = Iconv.new('iso-8859-1', 'utf-8')
  end
  
  def trans(text, from, to)
    begin
      pair = from == 'auto' ? from : "#{LANGS[from]}|#{LANGS[to]}" 
      text = @from_utf8.iconv(text) if utf?(text)
      url = URI.escape "http://translate.google.com/translate_t?langpair=#{pair}&text=#{text}"
      p url
      doc = Hpricot(open(url))
      res = doc.search("//div#result_box").inner_text
      utf?(res) ? res : @to_utf8.iconv(res)
    rescue Exception => e
      "Error: #{e.message}"
    end
  end
  
  def utf?(str)
    str.split(//u).all? { |c| c =~ UTF8_REGEXP }
  end
  
end

if __FILE__ == $0
  p Translate["let's see", :english, :norwegian]
end