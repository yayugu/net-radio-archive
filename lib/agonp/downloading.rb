module Agonp
  class Downloading
    CH_NAME = 'agonp'

    def initialize
      @a = Mechanize.new
      @a.user_agent_alias = 'Windows Chrome'
    end

    def download(program)
      login
      program_id = get_program_id(program)
      url = get_video_url(program)
      nazo_auth(program, program_id)
      save_video(program, url)
      true
    end

    def login
      page = @a.get('https://agonp.jp/auth/login')
      form = page.forms.first
      form.email = Settings.agonp.mail
      form.password = Settings.agonp.password
      form.submit
    end

    def get_program_id(program)
      page = @a.get("https://agonp.jp/episodes/view/#{program.episode_id}")
      page.search('a.btn-see-program-detail').first.attr('href')
          .match(%r{programs/view/(\d+)})[1]
    end

    def get_video_url(program)
      res = @a.get("https://agonp.jp/api/v1/episodes/media_url.json?episode_id=#{program.episode_id}&format=mp4&size=small")
      resj = JSON.parse(res.body)
      resj['data']['url']
    end

    def nazo_auth(program, program_id)
      res = @a.post("https://agonp.jp/api/v1/programs/episodes/view.json", {
          format: 'mp4',
          program_id: program_id,
          episode_id: program.episode_id,
          time: '-1',
          fuel_csrf_token: '',
      })
      fuel_csrf_token = @a.cookie_jar.jar['agonp.jp']['/']['fuel_csrf_token'].value
      res = @a.post("https://agonp.jp/api/v1/programs/episodes/view.json", {
          format: 'mp4',
          program_id: program_id,
          episode_id: program.episode_id,
          time: '-1',
          fuel_csrf_token: fuel_csrf_token,
      })
      fuel_csrf_token = @a.cookie_jar.jar['agonp.jp']['/']['fuel_csrf_token'].value
      res = @a.get("https://agonp.jp/api/v1/slices/own/#{program.episode_id}.json?fuel_csrf_token=#{fuel_csrf_token}")
      fuel_csrf_token = @a.cookie_jar.jar['agonp.jp']['/']['fuel_csrf_token'].value
      res = @a.post("https://agonp.jp/api/v1/programs/episodes/view.json", {
          format: 'mp4',
          program_id: program_id,
          episode_id: program.episode_id,
          time: '0',
          see_rate: '0',
          fuel_csrf_token: fuel_csrf_token,
      })
    end

    def save_video(program, url)
      file_path = Main::file_path_working(CH_NAME, title(program), 'mp4')
      Main::prepare_working_dir(CH_NAME)
      @a.get(url, [], "https://agonp.jp/episodes/view/#{program.episode_id}").save_as(file_path)
      Main::move_to_archive_dir(CH_NAME, program.created_at, file_path)
    end

    def title(program)
      date = program.created_at.strftime('%Y_%m_%d')
      title = "#{date}_#{program.title}"
      if program.personality
        title += "_#{program.personality}"
      end
      title
    end
  end
end

