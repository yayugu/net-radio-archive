# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
#
# Learn more: http://github.com/javan/whenever

job_type :rake_not_silent, 'sleep $[ ( $RANDOM % 30 )  + 1 ]s; export PATH=/usr/local/bin:$PATH; export LANG=en_US.UTF-8; cd :path && :environment_variable=:environment bundle exec rake :task :output'

every 1.minute do
  rake_not_silent 'main:rec_one'
end

every '3-50/3 * * * *' do
  rake_not_silent 'main:rec_ondemand'
end

#=== nico
# maintenance on Thursday
every '0 14 * * *' do
  rake_not_silent 'main:niconama_scrape'
end

# maintenance on Thursday
every '4-58 * * * 0-3,5-6' do
  rake_not_silent 'main:rec_niconama'
end
every '4-58 12-23 * * 4' do
  rake_not_silent 'main:rec_niconama'
end
#===

every '0 15 * * *' do
  rake_not_silent 'main:ag_scrape'
end

every '4 10-22 * * *' do
  rake_not_silent 'main:onsen_scrape'
end

every '8 10-22 * * *' do
  rake_not_silent 'main:hibiki_scrape'
end

every '12 * * * *' do
  rake_not_silent 'main:radiko_scrape'
end

every '5 * * * *' do
  rake_not_silent 'main:radiru_scrape'
end

every '17 10-22 * * *' do
  rake_not_silent 'main:anitama_scrape'
end

every '21 10-22 * * *' do
  rake_not_silent 'main:agon_scrape'
end

every '38 15 1 * *' do
  rake_not_silent 'main:wikipedia_scrape'
end

every '37 15 * * *' do
  rake_not_silent 'main:kill_zombie_process'
end

every '7 16 * * *' do
  rake_not_silent 'main:rm_working_files'
end
