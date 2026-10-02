require "cgi"
require "json"
require "open3"

module NeovimHighlighter
  @cache = {}

  def self.call(converter, text, lang, type, _opts)
    return nil unless lang

    html = highlight(converter.options.dig(:syntax_highlighter_opts, :command), lang, text)
    return nil unless html

    type == :block ? block(html) : %(<span class="highlight">#{html}</span>)
  end

  def self.command(config)
    opts = config.dig("kramdown", "syntax_highlighter_opts") || {}
    opts[:command] || opts["command"]
  end

  def self.block(html)
    %(<div class="highlight"><pre class="highlight"><code>#{html}</code></pre></div>)
  end

  def self.highlight(command, lang, text)
    unless command
      Jekyll.logger.warn "Neovim:", "no highlight command configured, build through the flake" unless @warned
      @warned = true
      return nil
    end

    @cache[[lang, text]] ||= render(captures(command, lang, text))
  end

  def self.captures(command, lang, text)
    output, error, status = Open3.capture3(command, lang, stdin_data: text)
    raise "Neovim failed to highlight #{lang}: #{error}" unless status.success?

    JSON.parse(output)
  end

  def self.render(runs)
    lines = [[]]
    runs.each do |text, captures|
      text.split("\n", -1).each_with_index do |part, i|
        lines << [] if i.positive?
        lines.last << [part, captures.split] unless part.empty?
      end
    end
    lines.pop if lines.last.empty?
    lines.map { |line| %(<span class="line">#{spans(line)}</span>) }.join
  end

  def self.spans(runs)
    html = +""
    open = []
    runs.each do |text, stack|
      shared = open.zip(stack).take_while { |a, b| a == b }.size
      html << "</span>" * (open.size - shared)
      stack.drop(shared).each { |capture| html << %(<span class="#{capture.tr(".", "-")}">) }
      html << CGI.escapeHTML(text)
      open = stack
    end
    html << "</span>" * open.size
  end

  module Filter
    def neovim(text, lang)
      command = NeovimHighlighter.command(@context.registers[:site].config)
      html = NeovimHighlighter.highlight(command, lang, text.to_s)
      NeovimHighlighter.block(html || CGI.escapeHTML(text.to_s))
    end
  end
end

Kramdown::Converter.add_syntax_highlighter(:treesitter, NeovimHighlighter)

Liquid::Template.register_filter(NeovimHighlighter::Filter)
