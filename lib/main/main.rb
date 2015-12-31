module Main
  class Main
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
          p.retry_count = 0
          p.save
        end
      end
    end

    def hibiki_scrape
      program_list = Hibiki::Scraping.new.main

      program_list.each do |program|
        ActiveRecord::Base.transaction do
          if HibikiProgramV2
              .where(access_id: program.access_id)
              .where(episode_id: program.episode_id)
              .first
            next
          end

          p = HibikiProgramV2.new
          p.access_id = program.access_id
          p.episode_id = program.episode_id
          p.title = program.title
          p.episode_name = program.episode_name
          p.cast = program.cast
          p.state = HibikiProgramV2::STATE[:waiting]
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
      unless Settings.niconico
        exit 0
      end

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
          p.cannot_recovery = false
          p.memo = ''
          p.retry_count = 0
          p.save
        end
      end
    end

    def agon_scrape
      unless Settings.agon
        exit 0
      end

      program_list = Agon::Scraping.new.main

      program_list.each do |program|
        ActiveRecord::Base.transaction do
          if AgonProgram.where(episode_id: program.episode_id).first
            next
          end

          p = AgonProgram.new
          p.title = program.title
          p.personality = program.personality
          p.episode_id = program.episode_id
          p.page_url = program.page_url
          p.state = HibikiProgram::STATE[:waiting]
          p.retry_count = 0
          p.save
        end
      end
    end

    def wikipedia_scrape
      unless Settings.try(:niconico).try(:live).try(:keyword_wikipedia_categories)
        exit 0
      end

      Settings.niconico.live.keyword_wikipedia_categories.each do |category|
        items = Wikipedia::Scraping.new.main(category)
        items = items.map do |item|
          [category, item]
        end
        WikipediaCategoryItem.import(
          [:category, :title],
          items,
          on_duplicate_key_update: [:title]
        )
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
      agon_download
    end

    def niconama_download
      unless Settings.niconico
        exit 0
      end

      p = nil
      ActiveRecord::Base.transaction do
        # ニコ生は検索オプションで「タイムシフト視聴可」を付けても
        # 実際にはまだタイムシフトが用意されていない場合がある
        # これに対応するため検索で発見しても一定時間待つ
        p = NiconicoLiveProgram
          .where(state: NiconicoLiveProgram::STATE[:waiting])
          .where('`created_at` <= ?', 2.hours.ago)
          .lock
          .first
        unless p
          return 0
        end

        p.state = NiconicoLiveProgram::STATE[:downloading]
        p.save!
      end

      NiconicoLive::Downloading.new.download(p)
      p.save!

      return 0
    end

    private

    def onsen_download
      download(OnsenProgram, Onsen::Downloading.new)
    end

    def hibiki_download
      download2(HibikiProgramV2, Hibiki::Downloading.new)
    end

    def anitama_download
      download(AnitamaProgram, Anitama::Downloading.new)
    end

    def agon_download
      unless Settings.agon
        exit 0
      end
      download(AgonProgram, Agon::Downloading.new)
    end

    def download(model_klass, downloader)
      p = nil
      ActiveRecord::Base.transaction do
        p = fetch_downloadable_program(model_klass)
        unless p
          return 0
        end

        p.state = model_klass::STATE[:downloading]
        p.save!
      end

      succeed = downloader.download(p)
      p.state =
        if succeed
          model_klass::STATE[:done]
        else
          model_klass::STATE[:failed]
        end
      unless succeed
        p.retry_count += 1
        if p.retry_count > model_klass::RETRY_LIMIT
          Rails.logger.error "#{model_klass.name} rec failed. exceeded retry_limit. #{p.id}: #{p.title}"
        end
      end
      p.save!

      return 0
    end

    def download2(model_klass, downloader)
      p = nil
      ActiveRecord::Base.transaction do
        # Hibikiで古いデータのキャッシュが残っているのかepisode_idが一致せず
        # outdatedと誤判定してしまうケースがあった
        # 対策として時間を置くことでprograms APIと各個別program APIのepisode_idが一致すること狙う
        p = fetch_downloadable_program(model_klass, 30.minutes.ago)
        unless p
          return 0
        end

        p.state = model_klass::STATE[:downloading]
        p.save!
      end

      downloader.download(p)
      if p.state == model_klass::STATE[:failed]
        p.retry_count += 1
        if p.retry_count > model_klass::RETRY_LIMIT
          Rails.logger.error "#{model_klass.name} rec failed. exceeded retry_limit. #{p.id}: #{p.title}"
        end
      end
      p.save!

      return 0
    end

    def fetch_downloadable_program(klass, older_than = nil)
      p = klass
        .where(state: klass::STATE[:waiting])
      if older_than
        p = p.where('`created_at` <= ?', older_than)
      end
      p = p
        .lock
        .first
      return p if p

      klass
        .where(state: [
               klass::STATE[:failed],
               klass::STATE[:downloading],
        ])
        .where('`retry_count` <= ?', klass::RETRY_LIMIT)
        .where('`updated_at` <= ?', 1.day.ago)
        .lock
        .first
    end
  end
end
