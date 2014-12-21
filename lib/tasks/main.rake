namespace :main do
  desc 'scraping ag'
  task :scraping_ag => :environment do
    ret = Ag::Scraping.new.main
    ret.each do |r|
      pp r
      p r.start_time.next_on_air
    end
  end
end
