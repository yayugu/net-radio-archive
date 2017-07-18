namespace :main do
  desc 'ag scrape'
  task :ag_scrape => :environment do
    Main::Main.new.ag_scrape
  end

  desc 'radiko scrape'
  task :radiko_scrape => :environment do
    Main::Main.new.radiko_scrape
  end

  desc 'radiru scrape'
  task :radiru_scrape => :environment do
    Main::Main.new.radiru_scrape
  end

  desc 'onsen scrape'
  task :onsen_scrape => :environment do
    Main::Main.new.onsen_scrape
  end

  desc 'hibiki scrape'
  task :hibiki_scrape => :environment do
    Main::Main.new.hibiki_scrape
  end

  desc 'anitama scrape'
  task :anitama_scrape => :environment do
    Main::Main.new.anitama_scrape
  end

  desc 'niconama scrape'
  task :niconama_scrape => :environment do
    Main::Main.new.niconama_scrape
  end

  desc 'agonp scrape'
  task :agonp_scrape => :environment do
    Main::Main.new.agonp_scrape
  end

  desc 'wikipedia scape'
  task :wikipedia_scrape => :environment do
    Main::Main.new.wikipedia_scrape
  end

  desc 'rec one'
  task :rec_one => :environment do
    Main::Main.new.rec_one
  end

  desc 'rec ondemand'
  task :rec_ondemand => :environment do
    Main::Main.new.rec_ondemand
  end

  desc 'rec niconama timeshift'
  task :rec_niconama => :environment do
    Main::Main.new.niconama_download
  end

  desc 'kill zombie process (rtmpdump)'
  task :kill_zombie_process => :environment do
    Main::Workaround::kill_zombie_process
  end

  desc 'remove old working(temporary) files'
  task :rm_working_files => :environment do
    Main::Workaround::rm_working_files
    Main::Workaround::rm_latest_dir_symlinks
  end
end
