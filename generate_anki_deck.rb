#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'
require 'csv'
require 'pry-byebug'
require 'set'
require 'anki2'

@people = YAML.load_file('people.yml')
@people_with_images = @people.reject { |p| p[:image].nil? }

class Anki2
  def default_model
    ANKI_MODEL
  end

  attr_accessor :db, :top_deck_id, :top_model_id

  def initialize(options = {})
    @options = {
      output_path: File.join('anki', 'deck.apkg'),
      name: 'Anki2 Rubygem Deck',
      template_sql_path: File.join(File.dirname(__FILE__), 'template.sql'),
    }.merge(options)

    @options[:model_name] = @options[:name] unless @options[:model_name]
    @options[:css] = default_css + @options[:css].to_s
    @options[:model] = model_config.call(default_model) if block_given?

    @media = []

    FileUtils.mkdir_p(File.dirname(@options[:output_path]))
    @tmpdir = Dir.mktmpdir

    @db = SQLite3::Database.open(File.join(@tmpdir, 'collection.anki2'))
    @db.execute_batch File.read(@options[:template_sql_path])

    @top_deck_id = 6771564019408 # rand(10**13)
    decks  = @db.execute('select decks from col')
    decks  = JSON.parse(decks.first.first) # .gsub('\"', '"')
    decks.delete('1') # Delete default deck from template
    deck = decks.delete(decks.keys.last)
    deck['name'] = @options[:name]
    deck['id']   = @top_deck_id
    decks[@top_deck_id.to_s] = deck
    @db.execute('update col set decks=? where id=1', decks.to_json)

    @top_model_id = 1178095728650 # rand(10**13)
    models = @db.execute('select models from col')
    models = JSON.parse(models.first.first) # .gsub('\"', '"')

    # Delete weird Basic card type from template
    models.delete '1622425042530'
    model = models.delete(models.keys.first)
    model['did']  = @top_deck_id
    model['id']   = @top_model_id
    models[@top_model_id.to_s] = model
    @db.execute('update col set models=? where id=1', models.to_json)
  end
end

def checksum(str)
  Digest::SHA1.hexdigest(str)[0...8].to_i(16)
end

def strip_html(str)
  str # TODO?
end

@card_due = 0

# Generate idempotent ids that can be reimported after updates
@note_id = 1632278802000
@card_id = 1632285802000
@note_guid_i = 2893482027

def add_card(person)
  fields = [
    person[:name],
    person[:url],
    person[:asteroid_number],
    person[:asteroid_name],
    person[:asteroid_url],
    person[:categories].join(', '),
    person[:first_paragraph],
    "<img src=\"#{person[:image].split('/').last}\">",
  ]

  deck_id = @anki.top_deck_id

  # Build list of tags
  tags = person[:categories].map do |t|
    ['AP', t.tr(' ', '_').gsub(/\W/, '_').gsub(/_+/, '_')].join('::')
  end.join(' ')

  modified_time = Time.now.to_i

  note_content = fields.join(Anki2::SEPARATOR)

  # Example note:
  # 1622288802433,"FC4k0rY[,4",1622287453372,1622424272,0,,"Charles Darwin...asteroidpeople_Charles_Darwin.jpg",Charles Darwin,591330921,0,
  @anki.db.execute 'insert into notes
    (id,guid,mid,mod,usn,tags,flds,sfld,csum,flags,data)
    values (?,?,?,?,?,?,?,?,?,?,?)',
                   @note_id,
                   @note_guid_i.to_s(36),
                   @anki.top_model_id,
                   modified_time, 0,
                   tags,
                   note_content,
                   strip_html(fields.first),
                   checksum(strip_html(note_content)),
                   0, ''

  # Example card:
  # 1622288802593,1622288802433,1622285981071,0,1622425042,-1,0,0,1,0,0,0,0,1001,0,0,0,
  # Add name -> details card (type 0)
  card_type = 0
  @anki.db.execute 'insert into cards
    (id,nid,did,ord,mod,usn,type,queue,due,ivl,factor,reps,lapses,left,odue,odid,flags,data)
    values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                   @card_id,
                   @note_id,
                   deck_id,
                   card_type,
                   modified_time,
                   -1, 0, 0, @card_due, 0, 0, 0, 0, 0, 0, 0, 0, ''
  @card_id += 1
  @card_due += 1

  # Add picture -> name card (type 1)
  card_type = 1
  @anki.db.execute 'insert into cards
    (id,nid,did,ord,mod,usn,type,queue,due,ivl,factor,reps,lapses,left,odue,odid,flags,data)
    values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                   @card_id,
                   @note_id,
                   deck_id,
                   card_type,
                   modified_time,
                   -1, 0, 0, @card_due, 0, 0, 0, 0, 0, 0, 0, 0, ''
  @card_id += 1
  @card_due += 1

  @note_id += 1
  @note_guid_i += 1
end

@anki = Anki2.new(
  output_path: 'PeopleWithAsteroidsNamedAfterThem.apkg',
  name: 'People With Asteroids Named After Them',
  template_sql_path: File.join(__dir__, 'anki_template.sql')
)
puts 'Adding media from ./images...'
@anki.add_media('images')

puts "Adding #{@people_with_images.count} cards..."
@people_with_images.each do |person|
  # person = @people_with_images.first
  add_card(person)
end

# binding.pry # unless @debugged
# @debugged = true

puts 'Saving deck to file...'
@anki.save

puts 'Finished!'

# Save sqlite db to disk so we can inspect in DB Browser for SQLite
# backup_db = SQLite3::Database.new('ankibackup.sqlite3')
# sqlite_backup = SQLite3::Backup.new(backup_db, 'main', @anki.db, 'main')
# sqlite_backup.step(-1)
# sqlite_backup.finish
