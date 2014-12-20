namespace :main do
  desc 'scraping ag'
  task :scraping_ag => :environment do
    Ag::Scraping.new.main
  end
end
