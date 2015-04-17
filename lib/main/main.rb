module Main
  class Main
    def initialize
      Rails.logger = Logger.new(STDOUT)
    end

    def ag_scrape
      programs = Ag::Scraping.new.main
      programs.each do |p|
        Job.new(
          ch: Job::CH[:ag],
          title: p.title,
          start: p.start_time.next_on_air,
          end: p.start_time.next_on_air + p.minutes.minutes
        ).schedule
      end
    end

    def radiko_scrape
      ch = 'QRR'
      programs = Radiko::Scraping.new.get(ch)
      programs.each do |p|
        title = p.title
        title += " #{p.performers}" if p.performers.present?
        Job.new(
          ch: ch,
          title: title,
          start: p.start_time,
          end: p.end_time
        ).schedule
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
          p.retry_count = 0
          p.save
        end
      end
    end

    def rec_one
      job = Job
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

      affected_rows_count = Job
        .where(id: job.id, state: Job::STATE[:scheduled])
        .update_all(state: Job::STATE[:recording])
      unless affected_rows_count == 1
        return 0
      end

      succeed = false
      if job.ch == Job::CH[:ag]
        succeed = Ag::Recording.new.record(job)
      else
        succeed = Radiko::Recording.new.record(job)
      end
      job.state =
        if succeed
          Job::STATE[:done]
        else
          Job::STATE[:failed]
        end
      job.save

      return 0
    end

    def rec_ondemand
      onsen_download
      hibiki_download
    end

    def onsen_download
      p = OnsenProgram
        .where(state: OnsenProgram::STATE[:waiting])
        .first
      unless p
        return
      end

      affected_rows_count = OnsenProgram
        .where(id: p.id, state: OnsenProgram::STATE[:waiting])
        .update_all(state: OnsenProgram::STATE[:downloading])
      unless affected_rows_count == 1
        return 0
      end
      p.reload

      succeed = Onsen::Downloading.new.download(p)
      p.state =
        if succeed
          OnsenProgram::STATE[:done]
        else
          OnsenProgram::STATE[:failed]
        end
      p.save

      return 0
    end

    def hibiki_download
      p = hibiki_program_to_download
      unless p
        return
      end

      affected_rows_count = HibikiProgram
        .where(id: p.id, state: p.state)
        .update_all(state: HibikiProgram::STATE[:downloading])
      unless affected_rows_count == 1
        return 0
      end
      p.reload

      succeed = Hibiki::Downloading.new.download(p)
      p.state =
        if succeed
          HibikiProgram::STATE[:done]
        else
          HibikiProgram::STATE[:failed]
        end
      unless succeed
        p.retry_count += 1
        if p.retry_count > HibikiProgram::RETRY_LIMIT
          Rails.logger.error "hibiki rec failed. exceeded retry_limit. #{p.id}: #{p.title}"
        end
      end
      p.save

      return 0
    end

    private

    def hibiki_program_to_download
      p = HibikiProgram
        .where(state: HibikiProgram::STATE[:waiting])
        .first
      return p if p

      HibikiProgram
        .where(state: HibikiProgram::STATE[:failed])
        .where('`retry_count` <= ?', HibikiProgram::RETRY_LIMIT)
        .where('`updated_at` <= ?', 1.day.ago)
        .first
    end
  end
end
