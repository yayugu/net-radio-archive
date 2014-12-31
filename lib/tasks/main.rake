namespace :main do
  desc 'scraping ag'
  task :scraping_ag => :environment do
    Rails.logger = Logger.new(STDOUT)

    ret = Ag::Scraping.new.main
    now = Time.now
    ret = ret.delete_if do |r|
      # only update after 10 minutes form now
      (r.start_time.next_on_air - Time.now).to_i < 10 * 60
    end
    ret.each do |r|
      ActiveRecord::Base.transaction do
        job = Job.find_or_initialize_by(
          ch: Job::CH[:ag],
          start: r.start_time.next_on_air
        )
        unless r.title == job.title
          job.title = r.title
          job.end = r.start_time.next_on_air + r.minutes.minutes
          job.state = Job::STATE[:scheduled]
          job.save
        end
      end
    end
  end

  desc 'recording ag'
  task :recording_ag => :environment do
    Rails.logger = Logger.new(STDOUT)

    job = Job
      .where(ch: Job::CH[:ag])
      .where(
        "? <= `start` and `start` <= ?",
        2.minutes.ago,
        1.minutes.from_now
      )
      .where(state: Job::STATE[:scheduled])
      .order(:start)
      .first
    unless job
      next
    end

    affected_rows_count = nil
    ActiveRecord::Base.transaction do
      affected_rows_count = Job
        .where(id: job.id, state: Job::STATE[:scheduled])
        .update_all(state: Job::STATE[:recording])
    end
    if affected_rows_count == 1
      succeed = Ag::Recording.new.record(job)
      job.state =
        if succeed
          Job::STATE[:succeed]
        else
          Job::STATE[:failed]
        end
      job.save
    end
  end

  desc 'scraping onsen'
  task :scraping_onsen => :environment do
    Rails.logger = Logger.new(STDOUT)

    program_list = Onsen::Scraping.new.main
    pp program_list
  end
end
