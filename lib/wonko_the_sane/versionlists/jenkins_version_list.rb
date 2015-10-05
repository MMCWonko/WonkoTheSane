class JenkinsVersionList < BaseVersionList
  def initialize(uid, name, base_url, job, file_regex)
    super(uid, name)
    @base_url = base_url
    @job = job
    @input = JenkinsInput.new(uid, name, file_regex)

    if @base_url[@base_url.length - 1] == '/'
      @base_url[@base_url.length - 1] = ''
    end
  end

  def get_versions
    get_json("#{@base_url}/job/#{@job}/api/json")[:builds].map { |build| [build[:number], build[:url]] }
  end

  def get_version(id)
    @input.parse get_json_cached id[1] + 'api/json'
  end
end
