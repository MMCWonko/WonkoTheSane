require_relative 'base_version_list'
require 'date'
require 'time'

class CurseVersionList < BaseVersionList
  def initialize(uid, curseId, fileRegex)
    super(uid)
    @curseId = curseId
    @fileRegex = fileRegex.gsub /\?P\</, '?<'
  end

  def get_versions
    result = Oga.parse_html HTTPCatcher.file('http://curse.com/project/' + @curseId, 'curse/' + @curseId + '.html')
    # start by getting rid of some elements that standard xml parsers have issues with
    result.each_node do |node| node.remove if node.is_a? Oga::XML::Element and ['script', 'like'].include? node.name end
    rows = result.xpath("html/body/#{'div/' * 14}table/tbody/tr")

    return rows.map do |row|
      match = row.xpath('td/a/text()').first.text.match @fileRegex
      next if not match
      version = match[:version]
      [
        version,
        {
          url: row.xpath('td/a/@href').first.value,
          fileId: row.xpath('td/a/text()').first.text,
          type: row.xpath('td[2]/text()').first.text,
          mcVersion: row.xpath('td[3]/text()').first.text,
          timestamp: row.xpath('td[5]/@data-sort-value').first.value.to_i / 1000,
          version: version
        }
      ]
    end
  end

  def get_version(id)
    urlId = id[1][:url].match(/\/(\d*)$/)[1]
    dl = FileDownload.new
    dl.internalUrl = "http://addons-origin.cursecdn.com/files/#{urlId[0...4]}/#{urlId[4...7]}/#{id[1][:fileId]}"
    dl.url = "http://curse.com" + id[1][:url]
    dl.destination = "mods/#{@artifact}-#{id.first}.jar"

    file = Version.new
    file.uid = @artifact
    file.version = id.first
    file.type =  id[1][:type]
    file.time = id[1][:timestamp]
    file.requires << Referenced.new('net.minecraft', id[1][:mcVersion])
    file.downloads << dl
    return BaseSanitizer.sanitize file
  end
end
