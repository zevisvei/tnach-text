# converts original mechon mamre htm files of the talmud bavli to txt
# caution: appends to output files, manually erase old ones before running.
require 'nokogiri'
require 'fileutils'
require 'pry'
require 'gematria'

def read_htm(f_name)
  puts 'parsing: ' + f_name
  htm = File.read(f_name)
  htm = Nokogiri.HTML(htm) # , nil, 'windows-1255')
  # get rid of '<big>' tags
  htm.css('big').each { |big| big.replace(big.children) }
  # reparse to join text nodes
  Nokogiri.HTML(htm.to_html)
end

def mkdirs(d_name)
  puts 'mkdirs', d_name
  FileUtils.mkdir(d_name) unless File.directory?(d_name)
end

def book(htm)
  @book_title = htm.css('title')[0].text.tr('/', '')
  puts 'creating book: ' + @book_title.reverse
  @txt_dir = "txts/#{@book_title}/"
  mkdirs(@txt_dir)
  @clean_txt_dir = 'clean_txts/' + @book_title + '/'
  mkdirs(@clean_txt_dir)
  # mkdirs('torah_or/' + @book_title)
end

def fix_name(old_name)
  old_name = old_name.split(',')
  perek = Gematria::Calculator.new(old_name[0], :hebrew)
  perek = pad_zero(perek.converted.to_s)
  pasuk = Gematria::Calculator.new(old_name[1], :hebrew)
  pasuk = pad_zero(pasuk.converted.to_s)
  perek + '.' + pasuk
end

def append_file(f_name, f_text)
  puts 'appending to ' + f_name
  f = File.open(f_name, 'a')
  f.write(f_text + "\n")
  f.close
end

def pad_zero(f_name)
  f_name.rjust(3, '0')
end

def sections(new_name, section_name)
  amud_text = "\n" + section_name + ': '
  append_file(@txt_dir + new_name, amud_text)
end

def clean_text(text)
  # remove everything bw ()
  text = text.split(/\(|\)/).select.with_index { |_, i| i.even? }.join
  text = text.split(/\{|\}/).select.with_index { |_, i| i.even? }.join
  text = text.tr('<>-', '() ').tr(';.,', '').tr(' ', ' ')
  text = text.gsub('  ', ' ') while text.include?('  ')
  text
end

def clean_section_name(section_name)
  if section_name == ' משנה'
    then "מתני'"
  elsif section_name == ' גמרא'
    then "גמ'"
  end
end

def clean_sections(new_name, text)
  text = clean_text(text)
  # section_name = clean_section_name(section_name)
  # amud_text = section_name == @section_name ? '' : ' ' + section_name
  # @section_name = section_name
  # # amud_text += section.next.text
  # torah_or(amud_text, new_name)
  # amud_text = clean_amud_text(amud_text)
  # # write to clean_txts/!
  append_file(@clean_txt_dir + new_name, text.strip)
end

@f_names = Dir['./enco_htm/*.htm']

# skip the toc pages
@f_names[3..-1].each do |f_name|
  # some pages have the entire book, some just a perek
  # next if it is a serate perek page
  next if f_name.length > 19
  puts f_name
  htm = read_htm(f_name)
  book(htm)
  htm.css('b').each do |section|
    puts section
    # b_text are future page names, in the htm they are surrounded by '<b>' tags
    b_text = section.text # .split(' ')
    puts b_text
    new_name = fix_name(b_text)
    puts new_name
    text = section.next.text
    # write to txts/!
    sections(new_name, text)
    # write to clean_txts/ and torah_or/!
    clean_sections(new_name, text)
  end
end
