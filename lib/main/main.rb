module Main
  class Main
    def initialize
      Rails.logger = Logger.new(STDOUT)
    end

    def ag_scrape
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

    def onsen_scrape
      program_list = Onsen::Scraping.new.main

      program_list.each do |program|
        ActiveRecord::Base.transaction do
          if program.update_date.blank? || program.file_url.blank?
            next
          end
          if OnsenProgram.where(file_url: program.file_url).first
            next
          end

          p = OnsenProgram.new
          p.title = program.title
          p.number = program.number
          p.date = program.update_date
          p.file_url = program.file_url
          p.personality = program.personality
          p.state = OnsenProgram::STATE[:waiting]
          p.save
        end
      end
    end

    def hibiki_scrape
      program_list = Hibiki::Scraping.new.main

      program_list.each do |program|
        ActiveRecord::Base.transaction do
          if program.rtmp_url.blank?
            next
          end
          if HibikiProgram.where(rtmp_url: program.rtmp_url).first
            next
          end

          p = HibikiProgram.new
          p.title = program.title
          p.comment = program.comment
          p.rtmp_url = program.rtmp_url
          p.state = HibikiProgram::STATE[:waiting]
          p.save
        end
      end
    end

    def rec_one
      ag_rec
      onsen_download
      hibiki_download
    end

    def ag_rec
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
        return
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
            Job::STATE[:done]
          else
            Job::STATE[:failed]
          end
        job.save
      end

      exit 0
    end

    def onsen_download
      p = OnsenProgram
        .where(state: OnsenProgram::STATE[:waiting])
        .first
      unless p
        return
      end

      affected_rows_count = nil
      ActiveRecord::Base.transaction do
        affected_rows_count = OnsenProgram
          .where(id: p.id, state: OnsenProgram::STATE[:waiting])
          .update_all(state: OnsenProgram::STATE[:downloading])
      end
      if affected_rows_count == 1
        succeed = Onsen::Downloading.new.download(p)
        p.state =
          if succeed
            OnsenProgram::STATE[:done]
          else
            OnsenProgram::STATE[:failed]
          end
        p.save
      end

      exit 0
    end

    def hibiki_download
      p = HibikiProgram
        .where(state: HibikiProgram::STATE[:waiting])
        .first
      unless p
        return
      end

      affected_rows_count = nil
      ActiveRecord::Base.transaction do
        affected_rows_count = HibikiProgram
          .where(id: p.id, state: HibikiProgram::STATE[:waiting])
          .update_all(state: HibikiProgram::STATE[:downloading])
      end
      if affected_rows_count == 1
        succeed = Hibiki::Downloading.new.download(p)
        p.state =
          if succeed
            HibikiProgram::STATE[:done]
          else
            HibikiProgram::STATE[:failed]
          end
        p.save
      end

      exit 0
    end
  end
end
