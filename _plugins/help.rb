require "cgi"

module Jekyll
  module Converters
    # Help files (`.txt`), highlighted as `:help` shows them, with each *tag*
    # an anchor and each |link| or 'option' naming one a jump to it.
    class Help < Converter
      TAG = %r{<span class="label">(?=<span class="concealed">\*</span>([^<]+)<span class="concealed">\*</span></span>)}
      LINK = %r{<span class="markup-link">(<span class="concealed">\|</span>([^<]+)<span class="concealed">\|</span>)</span>}
      OPTION = %r{(?<=&#39;)<span class="markup-link">([^<]+)</span>(?=&#39;)}
      CONCEAL = %(<span class="concealed">)

      def matches(ext)
        ext.casecmp?(".txt")
      end

      def output_ext(_ext)
        ".html"
      end

      def convert(content)
        html = NeovimHighlighter.highlight(NeovimHighlighter.command(@config), "help", content)
        NeovimHighlighter.block(html ? collapse(link(html)) : CGI.escapeHTML(content))
      end

      private

      # A tab ends where it would with nothing concealed before it, so only
      # what is concealed after the last tab of a line takes no room.
      def collapse(html)
        html.split(/(?=<span class="line">)/).map do |line|
          tab = line.rindex("\t") || 0
          line[0...tab] + line[tab..].gsub(CONCEAL, %(<span class="concealed collapsed">))
        end.join
      end

      def link(html)
        tags = html.scan(TAG).flatten
        html
          .gsub(TAG) { %(<span class="label" id="#{$1}">) }
          .gsub(LINK) { tags.include?($2) ? jump($2, $1) : $& }
          .gsub(OPTION) { tags.include?("&#39;#{$1}&#39;") ? jump("&#39;#{$1}&#39;", $1) : $& }
      end

      def jump(tag, html)
        %(<a class="markup-link" href="##{fragment(tag)}">#{html}</a>)
      end

      # {tag} after a "#", escaped as a browser escapes one typed there.
      def fragment(tag)
        CGI.escapeHTML(CGI.unescapeHTML(tag).gsub(/[\s"<>`]/) { |c| format("%%%02X", c.ord) })
      end
    end
  end
end
