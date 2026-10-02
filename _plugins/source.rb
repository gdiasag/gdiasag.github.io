Jekyll::Hooks.register [:pages, :posts], :pre_render do |page, payload|
  path = pages.site.in_source_dir(page.relative_path)
  next unless File.file?(path)

  source = File.read(path)
  payload["page"]["source"] = {
    "name" => File.basename(path),
    "front_matter" => source[/\A---[ \t]*\n.*?\n---[ \t]*\n/m].to_s,
  }
end
