namespace :main do
  desc 'ag scrape'
  task :ag_scrape => :environment do
    Main::Main.new.ag_scrape
  end

  desc 'radiko scrape'
  task :radiko_scrape => :environment do
    Main::Main.new.radiko_scrape
  end

  desc 'onsen scrape'
  task :onsen_scrape => :environment do
    Main::Main.new.onsen_scrape
  end

  desc 'hibiki scrape'
  task :hibiki_scrape => :environment do
    Main::Main.new.hibiki_scrape
  end

  desc 'rec one'
  task :rec_one => :environment do
    Main::Main.new.rec_one
  end

  desc 'rec ondemand'
  task :rec_ondemand => :environment do
    Main::Main.new.rec_ondemand
  end

  desc 'rec radiko'
  task :rec_radiko => :environment do
    #Main::Main.new.rec_one
    Radiko::Recording.new.record(nil)
  end

  desc 'kill zombie process (rtmpdump)'
  task :kill_zombie_process => :environment do
    Main::Workaround::kill_zombie_process
  end

  desc 'remove old working(temporary) files'
  task :rm_working_files => :environment do
    Main::Workaround::rm_working_files
  end
end
