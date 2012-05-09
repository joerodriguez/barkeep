require 'json'
require 'grit_wrapper'

module Barkeep

  def barkeep
    @@barkeep ||= Barkeeper.new
  end

end

class Barkeeper

  def config
    @config ||= JSON.parse(File.read("config/barkeep.json"))
  end

  def load?
    if defined?(Rails)
      this_env = Rails.env
    elsif defined?(Sinatra)
      this_env = Sinatra::Application.settings.environment
    end
    config['environments'].include?(this_env.to_s)
  end

  def styles
    return unless load?
    %(<style>#{File.read(File.expand_path(File.dirname(__FILE__) + "/default.css"))}</style>)
  end

  def render
    return unless load? && grit_info.repository?

    %(
      <dl id="barkeep">
      #{
        config['panes'].map do |name|
          if name =~ /^(p|partial) (.*)/
            render :partial => $2
          else
            send(name)
          end
        end.join('')
      }
      <dd class="close">
        <a href="#" onclick="c = document.getElementById('barkeep'); c.parentNode.removeChild(c); return false" title="Close me!">&times;</a>
      </dd>
      </dl>
    )
  end

  def branch_info
    %(<dt>Branch:</dt><dd><a href="#{branch_link_attributes[:href]}">#{grit_info[:branch]}</a></dd>)
  end

  def commit_sha_info
    %(<dt>Commit:</dt><dd><a href="#{commit_link_attributes[:href]}" title="#{commit_link_attributes[:title]}">#{(grit_info[:commit] || "").slice(0,8)}</a></dd>)
  end

  def commit_author_info
    %(<dt>Who:</dt><dd>#{grit_info[:last_author]}</dd>)
  end

  def commit_date_info
    short_date = (grit_info[:date].respond_to?(:strftime) ? grit_info[:date].strftime("%d %B, %H:%M") : short_date.to_s)
    %(<dt>When:</dt><dd title="#{grit_info[:date].to_s}">#{short_date}</dd>)
  end

  def rpm_request_info
    if rpm_enabled?
      %(<dt><a href="/newrelic">RPM:</a></dt><dd><a href="#{rpm_url}">request</a></dd>)
    end
  end

  def github_url
    config['github_url']
  end

  def grit_info
    GritWrapper.instance
  end

  def branch_link_attributes
    {
      :href => "#{github_url}/tree/#{grit_info[:branch]}",
      :title => grit_info[:message]
    }
  end

  def commit_link_attributes
    {
      :href => "#{github_url}/commit/#{grit_info[:commit]}",
      :title => "committed #{grit_info[:date]} by #{grit_info[:last_author]}"
    }
  end

  def rpm_enabled?
    if defined?(NewRelic)
      if defined?(NewRelic::Control)
        !NewRelic::Control.instance['skip_developer_route']
      else
        !NewRelic::Config.instance['skip_developer_route']
      end
    end
  end

  def rpm_sample_id
    NewRelic::Agent.instance.transaction_sampler.current_sample_id
  end

  def rpm_url
    "/newrelic/show_sample_detail/#{rpm_sample_id}"
  end
end
