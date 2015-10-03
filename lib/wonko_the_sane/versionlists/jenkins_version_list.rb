class JenkinsVersionList < BaseVersionList
  def initialize(artifact, base_url, job, file_regex)
    super(artifact)
    @base_url = base_url
    @job = job
    @input = JenkinsInput.new(artifact, file_regex)

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
