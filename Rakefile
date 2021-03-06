require 'haml'
require 'redcarpet'
require 'aws'
require 'mime/types'
require 'fileutils'
require 'securerandom'

task :start do
  exec 'ruby app.rb'
end

desc 'Render all haml files and copy public files to output'
task :render => :clean do
  FileUtils.cp_r 'public/.', 'output', preserve: true

  haml_options = { format: :html5, ugly: true }
  haml_layout = File.read('views/layout.haml')
  layout = Haml::Engine.new(haml_layout, haml_options)
  Dir['views/*.haml'].each do |f|
    name = File.basename(f, '.haml')
    next if name == 'layout' or name.start_with? '_'

    haml_view = File.read(f)
    view = Haml::Engine.new(haml_view, haml_options)
    ctx = ViewCtx.new(haml_options)
    inner = view.to_html(ctx, {name: name})
    html = layout.to_html(ctx, {name: name}) do
      inner
    end
    outf = "output/#{name}.html"
    File.open(outf, 'w+') {|o| o.write html}
    File.utime(File.atime(outf), File.mtime(f), outf)
  end
end

class ViewCtx
  def initialize(opts)
    @opts = opts

    rnder = Redcarpet::Render::HTML.new(prettify: true)
    @markdown = Redcarpet::Markdown.new(rnder, {
      :autolink => true,
      :space_after_headers => true,
      :no_intra_emphasis => true,
      :fenced_code_blocks => true,
      :space_after_headers => true
    })
  end

  def haml(view_sym, opts)
    haml_view = File.read("views/#{view_sym}.haml")
    engine = Haml::Engine.new(haml_view, @opts.merge(opts))
    engine.to_html(ViewCtx.new(@opts), opts[:locals])
  end

  def markdown(view_sym)
    view = File.read("views/#{view_sym}.md")
    html = @markdown.render(view)
    html.gsub(/(\<code class=")/, '\1prettyprint ')
  end
end

desc 'Recreate the output folder'
task :clean do
  FileUtils.rm_rf 'output'
  FileUtils.mkdir_p 'output'
end

task :gzip => :render do
  files = Dir['output/**/*'].select{ |f| File.file? f }
  files.each do |f|
    ct = MIME::Types.of(f).first.to_s
    next unless ct =~ /^text|javascript$|xml$/

    Zlib::GzipWriter.open("#{f}.gz") do |gz|
      gz.mtime = File.mtime f
      gz.write IO.binread(f)
    end
    size = File.size f
    gzip_size = File.size "#{f}.gz"
    puts "Compressing: #{f} saving #{(size - gzip_size)/1024} KB"
    FileUtils.rm f
    FileUtils.mv "#{f}.gz", f
  end
end

desc 'Sync output with S3 bucket'
task :upload => :gzip do
  AWS.config YAML.load(File.read('aws.yml'))

  s3 = AWS::S3.new
  objects = s3.buckets['www.cloudmqtt.com'].objects
  files = Dir['output/**/*'].select{ |f| File.file? f }

  changed = []
  objects.each do |obj|
    if f = files.find {|fn| fn == "output/#{obj.key}" }
      md5 = Digest::MD5.file(f).to_s
      if not obj.etag[1..-2] == md5
        ct = MIME::Types.of(f).first.to_s
        ct = "text/html;charset=utf-8" if ct == "text/html"
        ce = 'gzip' if ct =~ /^text|javascript$|xml$/
        puts "Updating: #{f} Content-type: #{ct} Content-encoding: #{ce}"
        objects[f.sub(/output\//,'')].write(:file => f, :content_type => ct, content_encoding: ce)
        changed << "/#{obj.key}"
      else
        puts "Not changed: #{f}"
      end
      files.delete f
    else
      obj.delete
      puts "Deleting: #{obj.key}"
    end
  end

  if changed.length > 0
    cf = AWS::CloudFront.new
    resp = cf.client.create_invalidation({
      distribution_id: 'E1GY9WL1URNZDH',
      invalidation_batch: {
        paths: {
          items: changed,
          quantity: changed.length,
        },
        caller_reference: SecureRandom.uuid,
      }
    })
    puts "Invalidating items in CloudFront: #{resp.data}"
  end

  files.each do |f|
    ct = MIME::Types.of(f).first.to_s
    ct += ";charset=utf-8" if ct == "text/html"
    ce = 'gzip' if ct =~ /^text|javascript$|xml$/
    puts "Uploading: #{f} Content-type: #{ct} Content-encoding: #{ce}"
    objects[f.sub(/output\//,'')].write(:file => f, :content_type => ct, content_encoding: ce)
  end
end
