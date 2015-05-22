require 'time'
require 'mechanize'

module Anitama
  class Program < Struct.new(:book_id, :title, :update_time)
  end

  class Scraping
    URL_BASE = "http://www.weeeef.com/weeeefww1"

    def initialize
      @a = Mechanize.new
      @a.user_agent_alias = 'Windows Chrome'
    end

    def main
      create_session
      program_list
      filter_program(program_list)
    end

    def download(book_id, path)
      create_session
      node_id = media_file_node_id(book_id)
      _download(node_id, path)
    end

    private

    def create_session
      @a.get(URL_BASE + "/Transition?command=top&group=G0000049")
      unixtime = Time.now.to_i
      @a.get(URL_BASE + "/CategoryServlet?groupId=null&time=#{unixtime}")
    end

    def program_list
      res = @a.get(URL_BASE + "/BookServlet")
      res.xml.css('Books Book').map do |book|
        book_id = book.attr('id')
        title = book.attr('label')
        update_time = Time.parse(book.attr('updateTime'))
        Program.new(book_id, title, update_time)
      end
    end

    def filter_program(list)
      list.reject do |program|
        # mp3が複数含まれていて扱いが面倒なのでとりあえず取得対象からはずしておく
        program.title.include?('校内放送マイクバトル')
      end
    end

    def media_file_node_id(book_id)
      res = @a.get(URL_BASE + "/BookXmlGet?BookId=#{book_id}&time=897")
      nodes = res.xml.xpath('./Node/Node/Node').select do |node|
        !!node.xpath('./Sound/Title').first
      end
      if nodes.size == 0
        raise "Undefined media file."
      end
      if nodes.size >= 2
        raise "Multiple media files in 1 program. Should fix code."
      end

      nodes.first.xpath('./Id').text
    end

    def _download(media_file_node_id, path)
      res = @a.post(URL_BASE + "/OriginalGet", {
        nodeId: media_file_node_id,
        type: 'S',
        time: 6405,
      })
      unless res.code.to_i == 200
        raise "response code is not 200: #{res.code}"
      end
      if res.body.bytesize < 1024 * 1024 # 1M
        raise "file size too small maybe failed"
      end
      File.binwrite(path, res.body)
    end
  end
end
