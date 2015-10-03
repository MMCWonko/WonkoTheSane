class CurseVersionList < BaseVersionList
  def initialize(uid, curse_id, file_regex)
    super uid
    @curse_id = curse_id
    @file_regex = file_regex.gsub /\?P\</, '?<'
  end

  def get_versions
    result = Oga.parse_html HTTPCache.file('http://curse.com/project/' + @curse_id, ctxt: @artifact, key: 'curse/' + @curse_id + '.html', check_stale: false)
    # start by getting rid of some elements that standard xml parsers have issues with
    result.each_node { |node| node.remove if node.is_a?(Oga::XML::Element) && ['script', 'like'].include?(node.name) }
    rows = result.xpath "html/body/#{'div/' * 14}table/tbody/tr"

    rows.map do |row|
      match = row.xpath('td/a/text()').first.text.match @file_regex
      next if match.nil?
      [
        match[:version],
        {
          url: row.xpath('td/a/@href').first.value,
          fileId: row.xpath('td/a/text()').first.text,
          type: row.xpath('td[2]/text()').first.text,
          mcVersion: row.xpath('td[3]/text()').first.text,
          timestamp: row.xpath('td[5]/@data-sort-value').first.value.to_i / 1000,
          version: match[:version]
        }
      ]
    end
  end

  def get_version(id)
    url_id = id[1][:url].match(/\/(\d*)$/)[1]
    dl = FileDownload.new
    dl.internal_url = "http://addons-origin.cursecdn.com/files/#{url_id[0...4]}/#{url_id[4...7]}/#{id[1][:fileId]}"
    dl.url = "http://curse.com" + id[1][:url]
    dl.destination = "mods/#{@artifact}-#{id.first}.jar"

    file = WonkoVersion.new
    file.uid = @artifact
    file.version = id.first
    file.type =  id[1][:type]
    file.time = id[1][:timestamp]
    file.requires << Referenced.new('net.minecraft', id[1][:mcVersion])
    file.common.downloads << dl
    BaseSanitizer.sanitize file
  end
end
