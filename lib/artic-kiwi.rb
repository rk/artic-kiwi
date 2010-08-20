require 'digest/sha1'
require 'yaml'

module Kiwi
  class << self
    
    def version
      "0.1"
    end
    
    def guid
      Digest::SHA1.hexdigest(rand(2**48).to_s + user + Time.now.to_s)
    end

    def user
      ENV["USERNAME"] || ENV["USER"]
    end

    def path
      @@path ||= File.join(Dir.pwd,".kiwi")
    end
    
    def is_project?
      File.exists?(path) && File.directory?(path)
    end
    
  end
  
  class Issue
    attr_reader   :guid, :reported_by
    attr_accessor :text, :state

    def self.[](guid)
      file = File.join(Kiwi.path, guid)
      if File.exists?(file)
        ::YAML.load_file(file) || nil
      end
    end
    
    def self.find(pattern)
      Dir[File.join(Kiwi.path, "#{pattern}*")].collect { |f| ::YAML.load_file(f) }
    end
    
    def self.all
      @@all ||= Dir[File.join(Kiwi.path, "*")].collect do |f|
        ::YAML.load_file(f)
      end
    end
    
    def self.size
      @@size ||= Dir[File.join(Kiwi.path, "*")]
    end

    def initialize(text, state=nil)
      @guid  = Kiwi.guid
      @text  = text
      @state = state || :unresolved
      @reported_by = Kiwi.user
    end

    def to_s
      "Issue: #{@guid}\nState: #{@state.to_s.upcase}\nUser:  #{@reported_by}\nText:  #{@text}\n"
    end
    
    def save
      File.open(File.join(Kiwi.path, self.guid), 'wb+') do |f|
        ::YAML.dump(self, f)
      end
    end
    
  end

  def self.add(text)
    Dir.mkdir(Kiwi.path) unless Kiwi.is_project?
    if text.rstrip == ""
      raise "Add text next time."
      exit
    else
      issue = Issue.new(text) and issue.save
      puts issue
    end
  end
  
  def self.update(guid, text=nil)
    issue = Issue[guid] || Issue.find(guid).first
    if text
      issue.text = text
    else
      puts "---", "Description: #{issue.text}", "---"
      puts "Enter your new description (CTRL-D to accept):"
      issue.text = STDIN.readlines.join.rstrip
    end
    issue.save
    puts issue
  end
  
  def self.resolve(guid)
    issue = Issue[guid] || Issue.find(guid).first
    issue.state = :resolved
    issue.save
    puts "#{issue.guid} RESOLVED"
  end
  
  def self.info(guid)
    puts Issue[guid] || Issue.find(guid).first
  end
  
  def self.list
    Issue.all.each do |issue|
      issue and puts "#{issue.guid} #{issue.state.to_s.upcase}"
    end
  end
  
  def self.untrack
    print "Are you sure? (Y/N): "
    STDIN.getc == ?Y and File.unlink(*Dir[File.join(Kiwi.path, "*")]) and
      Dir.unlink(Kiwi.path) and puts "There is no longer a project here."
  end
  
  def self.status(guid=nil)
    if guid
      Issue.find(guid).each { |i| puts "#{i.guid} #{i.state.to_s.upcase}" }
    else
      puts Kiwi.is_project? ? "There is a project here, tracking #{Issues.size} issues." : "There is no project here yet."
    end
  end
end
