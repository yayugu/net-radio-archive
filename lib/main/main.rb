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
      Settings.radiko_channels.each do |ch|
        programs = Radiko::Scraping.new.get(ch)
        programs.each do |p|
          title = p.title
          title += " #{p.performers}" if p.performers.present?
          Job.new(
            ch: ch,
            title: title.slice(0, 240),
            start: p.start_time,
            end: p.end_time
          ).schedule
        end
      end
    end

    def onsen_scrape
      program_list = Onsen::Scraping.new.main

      program_list.each do |program|
        if program.update_date.blank? || program.file_url.blank?
          next
        end
        ActiveRecord::Base.transaction do
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
        if program.rtmp_url.blank?
          next
        end
        ActiveRecord::Base.transaction do
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

    def anitama_scrape
      program_list = Anitama::Scraping.new.main

      program_list.each do |program|
        ActiveRecord::Base.transaction do
          if AnitamaProgram
              .where(book_id: program.book_id)
              .where(update_time: program.update_time)
              .first
            next
          end

          p = AnitamaProgram.new
          p.book_id = program.book_id
          p.title = program.title
          p.update_time = program.update_time
          p.state = HibikiProgram::STATE[:waiting]
          p.retry_count = 0
          p.save
        end
      end
    end

    def niconama_scrape
      program_list = NiconicoLive::Scraping.new.main

      program_list.each do |program|
        ActiveRecord::Base.transaction do
          if NiconicoLiveProgram.where(id: program.id).first
            next
          end

          p = NiconicoLiveProgram.new
          p.id = program.id
          p.title = program.title
          p.state = NiconicoLiveProgram::STATE[:waiting]
          p.retry_count = 0
          p.save
        end
      end
    end

    def rec_one
      job = nil
      ActiveRecord::Base.transaction do
        job = Job
          .where(
            "? <= `start` and `start` <= ?",
            2.minutes.ago,
            5.minutes.from_now
          )
          .where(state: Job::STATE[:scheduled])
          .order(:start)
          .lock
          .first
        unless job
          return 0
        end

        job.state = Job::STATE[:recording]
        job.save!
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
      job.save!

      return 0
    end

    def rec_ondemand
      onsen_download
      hibiki_download
      anitama_download
    end

    def rec_niconama
      p = nil
      ActiveRecord::Base.transaction do
        p = NiconicoLiveProgram
        .where(state: NiconicoLiveProgram::STATE[:waiting])
        .lock
        .first
        unless p
          return 0
        end

        p.state = NiconicoLiveProgram::STATE[:downloading]
        p.save!
      end

      p.state = NiconicoLive::Downloading.new.download(p)
      p.save!

      return 0
    end

    private

    def onsen_download
      p = nil
      ActiveRecord::Base.transaction do
        p = OnsenProgram
          .where(state: OnsenProgram::STATE[:waiting])
          .lock
          .first
        unless p
          return 0
        end

        p.state = OnsenProgram::STATE[:downloading]
        p.save!
      end

      succeed = Onsen::Downloading.new.download(p)
      p.state =
        if succeed
          OnsenProgram::STATE[:done]
        else
          OnsenProgram::STATE[:failed]
        end
      p.save!

      return 0
    end

    def hibiki_download
      p = nil
      ActiveRecord::Base.transaction do
        p = hibiki_program_to_download
        unless p
          return 0
        end

        p.state = HibikiProgram::STATE[:downloading]
        p.save!
      end

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
      p.save!

      return 0
    end

    def anitama_download
      p = nil
      ActiveRecord::Base.transaction do
        p = AnitamaProgram
          .where(state: AnitamaProgram::STATE[:waiting])
          .lock
          .first
        unless p
          return 0
        end

        p.state = AnitamaProgram::STATE[:downloading]
        p.save!
      end

      succeed = Anitama::Downloading.new.download(p)
      p.state =
        if succeed
          AnitamaProgram::STATE[:done]
        else
          AnitamaProgram::STATE[:failed]
        end
      p.save!

      return 0
    end


    def hibiki_program_to_download
      p = HibikiProgram
        .where(state: HibikiProgram::STATE[:waiting])
        .lock
        .first
      return p if p

      HibikiProgram
        .where(state: HibikiProgram::STATE[:failed])
        .where('`retry_count` <= ?', HibikiProgram::RETRY_LIMIT)
        .where('`updated_at` <= ?', 1.day.ago)
        .lock
        .first
    end
  end
end
