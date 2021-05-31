#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'httparty'
require 'json'
require 'yaml'
require 'csv'
require 'pry-byebug'
require 'sucker_punch'
require 'set'
require 'anki2'

SKIPPED_CATEGORIES = [
  /Science => Astronomers/,
  /Relatives of astronomers/,
  /^Contest winners/,
  'Other social scientists',
  /^Teachers/,
  'Others',
].freeze

SKIPPED_NAMES = [
  /Arthurian/,
  /Asterix/,
  /Smithsonian/,
].freeze

def download_with_cache(url)
  puts "Fetching #{url}"
  cache_name = url.gsub(/\W+/, '_').gsub(/_+/, '_')
  cache_file = File.expand_path(File.join('tmp', "#{cache_name}.html"), __dir__)
  if File.exist?(cache_file)
    puts "Returning HTML from cache: #{cache_file}"
    return File.read(cache_file)
  end

  puts 'Downloading...'
  response = HTTParty.get(url)
  html = response.body
  File.open(cache_file, 'w') { |f| f.puts html }
  html
end

def parse_list_el(li_el)
  links = li_el.css('> a')
  # Ignore anyone who doesn't have a wikipedia page
  return unless links.count > 1

  sublist_els = li_el.css('> ul')
  sublist_els.each do |sublist_el|
    parse_list_el(sublist_el)
  end

  indentation = '   ' * @categories.count

  asteroid_name = nil
  asteroid_number = nil
  asteroid_url = nil

  links.each do |wiki_link|
    # Ignore any people who have missing wikipedia pages
    break if wiki_link[:class] == 'new'

    path = wiki_link[:href]
    url = if path.start_with?('/')
      "https://en.wikipedia.org#{path}"
    else
      path
    end

    name = wiki_link.text
    break if SKIPPED_NAMES.any? { |n| n.match? name }

    if name.match?(/^\d+ /)
      asteroid_number = name[/^(\d+)/, 1]
      asteroid_name = name
      asteroid_url = url
      puts "#{indentation}Asteroid #{asteroid_number}: #{name} (#{url})"
      next
    end

    # Avoid duplicates
    next if @asteroid_numbers.include?(asteroid_number)

    @asteroid_numbers << asteroid_number

    puts "#{indentation}=> #{name} (#{url})"

    next unless asteroid_number

    @people << {
      name: name,
      url: url,
      asteroid_number: asteroid_number,
      asteroid_name: asteroid_name,
      asteroid_url: asteroid_url,
      categories: @categories,
    }
    break
  end
end

html = download_with_cache('https://en.wikipedia.org/wiki/List_of_minor_planets_named_after_people')
page = Nokogiri::HTML(html)

output_el = page.css('#mw-content-text .mw-parser-output')
raise 'Error finding .mw-parser-output' unless output_el.count == 1
raise 'Error finding .mw-parser-output > *' unless output_el.children.count > 100

# There are some duplicates on the page under multiple categories
@asteroid_numbers = Set.new
@people = []

@categories = []
last_category_tag = nil

last_category_string = nil
output_el.children.each do |el|
  # Build up the nested list of categories

  case el.name
  when 'h2', 'h3', 'h4'
    category = el.css('.mw-headline').text

    # Stop once we get to the "See also" section
    break if category == 'See also'

    # @categories.pop if %w[h4 h3].include?(last_category_tag)
    # @categories.pop if last_category_tag == 'h3'
    case el.name
    when 'h2'
      # Reset (top level category)
      @categories = []
    when 'h3'
      @categories.pop if %w[h3 h4].include?(last_category_tag)
      @categories.pop if last_category_tag == 'h4'
    when 'h4'
      @categories.pop if last_category_tag == 'h4'
    end
    @categories << category
    last_category_tag = el.name
  end

  category_string = @categories.join(' => ')

  # Skip anyone we don't need to know about
  next if SKIPPED_CATEGORIES.any? do |category_matcher|
    case category_matcher
    when String
      category_matcher == category_string
    when Regexp
      category_matcher.match?(category_string)
    end
  end

  if category_string != last_category_string
    puts category_string
  end
  last_category_string = category_string

  next unless el.name == 'ul'

  el.css('li').each do |li_el|
    raise "WTF, we don't have any @categories yet" if @categories.none?

    # Recursively parses any ul els
    parse_list_el(li_el)
  end
end

# puts @people

# Save people to yaml file
# File.open('people.yml', 'w') { |f| f.puts @people.to_yaml }

# Look up images for people

class DownloadImageJob
  include SuckerPunch::Job
  workers 5

  def perform(image_url, image_filename)
    puts "===> Downloading #{image_url}..."
    File.open(image_filename, 'wb') do |file|
      HTTParty.get(image_url, stream_body: true, follow_redirects: true) do |fragment|
        file.write(fragment)
      end
    end
    puts "===> Finished downloading #{image_url}"
  end
end

class DownloadWikipediaPageJob
  include SuckerPunch::Job
  workers 5

  def find_wiki_image(page)
    img_els = page.css('.infobox.biography .infobox-image img')
    return img_els.first[:src] if img_els.any?

    img_els = page.css('.infobox .infobox-image img')
    return img_els.first[:src] if img_els.any?

    # Try find a thumbnail
    img_els = page.css('.mw-body-content .thumb img')
    return img_els.first[:src] if img_els.any?

    nil
  end

  def perform(person_url, person_name)
    html = download_with_cache(person_url)

    page = Nokogiri::HTML(html)
    image_url = find_wiki_image(page)

    unless image_url
      puts
      puts "!!!!!!!!! No image found for #{person_name}"
      puts "          Check Wikipedia: #{person_url}"
      puts
      return
    end
    image_url = image_url.sub(/^\/\//, 'https://')

    image_name = person_name.gsub(/\W+/, '_').gsub(/_+/, '_')
    image_ext = image_url.split('/').last.split('.').last.downcase
    image_ext = 'jpg' if image_ext == 'jpeg'
    image_filename = File.expand_path(File.join('images', "#{image_name}.#{image_ext}"), __dir__)

    if File.exist?(image_filename)
      puts "Image already exists for #{person_name} => #{image_filename}"
      return
    end

    puts "Enqueuing image download job for #{person_name}. #{image_url} => #{image_filename}"
    # DownloadImageJob.perform_async(image_url, image_filename)
    DownloadImageJob.new.perform(image_url, image_filename)
  end
end

# @people.each do |person|
#   # DownloadWikipediaPageJob.perform_async(person[:url], person[:name])
#   DownloadWikipediaPageJob.new.perform(person[:url], person[:name])
# end

# loop do
#   all_stats = SuckerPunch::Queue.stats
#   wikipedia_stats = all_stats[DownloadWikipediaPageJob.to_s]
#   image_stats = all_stats[DownloadImageJob.to_s]

#   enqueued_wikipedia_jobs = wikipedia_stats&.dig('jobs', 'enqueued') || 0
#   enqueued_image_jobs = image_stats&.dig('jobs', 'enqueued') || 0
#   total_enqueued_jobs = enqueued_wikipedia_jobs + enqueued_image_jobs

#   puts
#   puts ":::: Wiki jobs remaining: #{enqueued_wikipedia_jobs}," \
#     " image jobs remaining: #{enqueued_image_jobs}"
#   puts

#   break if total_enqueued_jobs == 0

#   sleep 5
# end

# puts 'All jobs finished!'

# binding.pry unless @debugged
# @debugged = true

page_job_instance = DownloadWikipediaPageJob.new

# Add images and intro paragraphs to YAML
@people.each do |person|
  html = download_with_cache(person[:url])

  page = Nokogiri::HTML(html)
  output_el = page.css('#mw-content-text .mw-parser-output')
  output_el.children.each do |el|
    next unless el.name == 'p'
    next if el.text.strip == ''

    el.css('sup').remove
    el.css('span.IPA').remove
    el.css('i[title="English pronunciation respelling"]').remove

    # Convert relative URLs to absolute
    el.css('a').each do |link_el|
      href = link_el[:href]
      next if href.match?(/^(https?:)?\/\//)

      link_el[:href] = "https://en.wikipedia.org#{href}"
    end

    html = el.to_html
    html = html.gsub("\n</p>", '</p>').strip

    person[:first_paragraph] = html

    break
  end

  person_name = person[:name]

  image_url = page_job_instance.find_wiki_image(page)
  next unless image_url

  image_url = image_url.sub(/^\/\//, 'https://')
  image_name = person_name.gsub(/\W+/, '_').gsub(/_+/, '_')
  image_ext = image_url.split('/').last.split('.').last.downcase
  image_ext = 'jpg' if image_ext == 'jpeg'
  image_filename = File.expand_path(
    File.join('images', "asteroidpeople_#{image_name}.#{image_ext}"), __dir__
  )

  if File.exist?(image_filename)
    person[:image] = image_filename
  end
end

# binding.pry # unless @debugged
# @debugged = true

@people_with_images = @people.reject { |p| p[:image].nil? }

# Save people to yaml file
File.open('people.yml', 'w') { |f| f.puts @people.to_yaml }

headers = @people_with_images.first.keys
CSV.open('people.csv', 'w', { col_sep: "\t" }) do |csv|
  # csv << headers
  # @people_with_images[0..3].each do |person|
  @people_with_images.each do |person|
    data = headers.map do |h|
      case h
      when :categories
        person[h].join(' - ')
      when :image
        person[h].split('/').last
      else
        person[h]
      end
    end
    csv << data
  end
end

binding.pry # unless @debugged
@debugged = true

# Create Anki deck file
ANKI_CSS = <<~CSS
      .card {
        font-family: arial;
        font-size: 20px;
        text-align: center;
        color: black;
        background-color: white;
      }
  #{'  '}
      hr {
        margin: 22px;
      }
  #{'  '}
      small.asteroid {
        font-size: 14px;
      }
  #{'  '}
      .description {
        text-align: left;
        font-size: 16px;
        line-height: 21px;
        max-width: 450px;
        margin: auto;
        margin-top: 25px
      }
  #{'  '}
      .profile {
        margin: auto;
      }
      .profile img {
        max-width: 300px;
        max-height: 300px;
      }
  #{'  '}
      .categories {
        font-size: 12px;
        color: #777;
        margin-top: 10px;
      }
    }
CSS

ANKI_NAME_ABOUT_FRONT = <<~HTML
    <a href="{{URL}}">{{Name}}</a> <small class="asteroid">(<a href="{{Asteroid URL}}">{{Asteroid Name}}</a>)</small>
  #{'  '}
    <hr>
  #{'  '}
    ?
HTML

ANKI_NAME_ABOUT_BACK = <<~HTML
    <a href="{{URL}}">{{Name}}</a> <small class="asteroid">(<a href="{{Asteroid URL}}">{{Asteroid Name}}</a>)</small>
  #{'  '}
    <div class="categories">{{Categories}}</div>
  #{'  '}
    <hr>
  #{'  '}
    <div class="profile">{{Image}}</div>
  #{'  '}
    <div class="description">
    {{First Paragraph}}
    </div>
HTML

ANKI_PICTURE_NAME_FRONT = <<~HTML
    <div class="profile">{{Image}}</div>
  #{'  '}
    <hr>
  #{'  '}
    ?
HTML

ANKI_PICTURE_NAME_BACK = <<~HTML
    <div class="profile">{{Image}}</div>
  #{'  '}
    <hr>
  #{'  '}
    <a href="{{URL}}">{{Name}}</a> <small class="asteroid">(<a href="{{Asteroid URL}}">{{Asteroid Name}}</a>)</small>
  #{'  '}
    <div class="categories">{{Categories}}</div>
    <hr>
  #{'  '}
    <div class="description">
    {{First Paragraph}}
    </div>
HTML

DEFAULT_FIELD = {
  'rtl' => false,
  'sticky' => false,
  'media' => [],
  'ord' => 0,
  'font' => 'Arial',
  'size' => 12,
}.freeze

ANKI_MODEL = {
  'name' => 'AsteroidPeople-1234',
  'flds' => [
    DEFAULT_FIELD.dup.merge('ord' => 0, 'name' => 'Name'),
    DEFAULT_FIELD.dup.merge('ord' => 1, 'name' => 'URL'),
    DEFAULT_FIELD.dup.merge('ord' => 2, 'name' => 'Asteroid Number'),
    DEFAULT_FIELD.dup.merge('ord' => 3, 'name' => 'Asteroid Name'),
    DEFAULT_FIELD.dup.merge('ord' => 4, 'name' => 'Asteroid URL'),
    DEFAULT_FIELD.dup.merge('ord' => 5, 'name' => 'Asteroid Categories'),
    DEFAULT_FIELD.dup.merge('ord' => 6, 'name' => 'First Paragraph'),
    DEFAULT_FIELD.dup.merge('ord' => 7, 'name' => 'Image'),
  ],
  'css' => ANKI_CSS,
  'tmpls' => [
    {
      'name' => 'Name -> About',
      'qfmt' => ANKI_NAME_ABOUT_FRONT,
      'did' => nil,
      'bafmt' => '',
      'afmt' => ANKI_NAME_ABOUT_BACK,
      'ord' => 0,
      'bqfmt' => '',
    },
    {
      'name' => 'Picture -> Name',
      'qfmt' => ANKI_PICTURE_NAME_FRONT,
      'did' => nil,
      'bafmt' => '',
      'afmt' => ANKI_PICTURE_NAME_BACK,
      'ord' => 1,
      'bqfmt' => '',
    },
  ],
}
class Anki2
  def default_model
    ANKI_MODEL
  end

  attr_accessor :db, :top_deck_id, :top_model_id
end

def checksum(str)
  Digest::SHA1.hexdigest(str)[0...8].to_i(16)
end

def strip_html(str)
  str # TODO?
end

def add_card(person)
  fields = [
    person[:name],
    person[:url],
    person[:asteroid_number],
    person[:asteroid_name],
    person[:asteroid_url],
    person[:categories].join(', '),
    person[:first_paragraph],
    person[:image].split('/').last,
  ]

  deck_id = @anki.top_deck_id
  note_id = rand(10**13)

  # Build list of tags
  tags = person[:categories].map do |t|
    ['AP', t.tr(' ', '_').gsub(/\W/, '_').gsub(/_+/, '_')].join('::')
  end.join(' ')

  note_guid = rand(10**10).to_s(36)
  modified_time = Time.now.to_i

  note_content = fields.join(Anki2::SEPARATOR)

  @anki.db.execute 'insert into notes values(?,?,?,?,?,?,?,?,?,?,?)',
                   note_id,
                   note_guid,
                   @anki.top_model_id,
                   modified_time, -1,
                   tags,
                   note_content,
                   strip_html(fields.first),
                   checksum(strip_html(note_content)),
                   0, ''
  card_id = rand(10**13)
  @anki.db.execute 'insert into cards values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                   card_id,
                   note_id,
                   deck_id,
                   0,
                   modified_time,
                   -1, 0, 0, 179, 0, 0, 0, 0, 0, 0, 0, 0, ''
end

@anki = Anki2.new(model: ANKI_MODEL, output_path: 'AsteroidPeople.apkg', name: 'AsteroidPeople')
@anki.add_media('images')

# @people_with_images.each do |person|
add_card(person)
# end

# Save sqlite db to disk so we can inspect in DB Browser for SQLite
backup_db = SQLite3::Database.new('ankibackup.sqlite3')
sqlite_backup = SQLite3::Backup.new(backup_db, 'main', @anki.db, 'main')
sqlite_backup.step(-1)
sqlite_backup.finish

@anki.save

binding.pry # unless @debugged
@debugged = true
