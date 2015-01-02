namespace :main do
  desc 'ag scrape'
  task :ag_scrape => :environment do
    Main::Main.new.ag_scrape
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
end
