require 'rugged'
require 'yajl'
require 'wonkothesane/format'

module WonkoTheSane
  class Storage
    include WonkoTheSane::Format
    attr_reader :dir

    def initialize(options = {})
      @dir     = options[:dir]
      @options = options
      if Dir.exist? "#{@dir}/.git"
        @repo  = Rugged::Repository.new @dir
        @index = @repo.index
      else
        @repo = Rugged::Repository.init_at @dir
        write_json('Add repo metadata', 'wts_repo_meta.json', { wts_version: WonkoTheSane::VERSION, created: DateTime.now.iso8601 })
      end
    end

    def register_version(version)
      id             = version[:id]
      ver            = version[:version]
      version[:time] = DateTime.now.iso8601
      false if(File.exist? "#{id}/#{ver}.json")
      write_json("Add #{id} version #{ver}", "#{id}/#{ver}.json", version)
      true
    end

    def get_version(id, ver)
      File.open("#{@dir}/#{id}/#{ver}.json", 'r') do |f|
        obj = Yajl::Parser.parse(f, symbolize_keys: true)
        raise 'Invalid version format' unless verify_wonko_version(obj)
        obj
      end
    end

    private

    def write_json(msg, path, obj)
      index = @repo.index
      index.read_tree(repo.head.target.tree)
      File.open("#{@dir}/#{path}", 'w') do |f|
        Yajl::Encoder.encode(obj, f, pretty: true)
      end
      index.add(path)
      commit(msg, index)
    end

    def commit(msg, index)
      Rugged::Commit.create(@repo,
                            author:     @options[:author],
                            message:    msg,
                            committer:  @options[:author] || @options[:committer],
                            parents:    repo.empty? ? [] : [repo.head.target].compact,
                            tree:       index.write_tree(@repo),
                            update_ref: 'HEAD')
    end
  end
end