require 'sinatra/base'
require 'open-uri'

class StreamTest < Sinatra::Base

  @@streams = {}

  def self.playlist_relative_uri(u, f=nil)
    new_uri = u.dup
    path_splits = new_uri.path.split('/')
    path_splits.delete(path_splits.last)
    new_uri.path = path_splits.join("/")+'/'
    new_uri.path = new_uri.path+f if f
    new_uri
  end
  def self.load_streams()
    File.read('streams').split("\n").each do |m3u8_url|
      if m3u8_url.include?("\t")
        ln_splits = m3u8_url.split("\t")
        label, uri = ln_splits.first, URI(ln_splits.last)
      else
        uri = URI(m3u8_url)
        label = [uri.host, uri.path].join(" ")
      end
      @@streams.store( label, [] )
      m3u8_contents = open(uri).read()
      lines = m3u8_contents.split("\n")
      lines.each_with_index do |ln, index|
        if ln.include?('#EXT-X-STREAM-INF:')
          ln.gsub!('#EXT-X-STREAM-INF:', '')
          extended_info, target, misc_uri = {}, lines[index+1], uri.dup
          ln.split(",").map{ |v| v.split('=') }.each { |v| extended_info.store(v[0], v[1]) }
          extended_info.store( 'uri', self.playlist_relative_uri(uri, target))
          @@streams[ label ] << extended_info
        end
      end
    end
  end

  get '/' do
    @@streams.inspect
  end
end
