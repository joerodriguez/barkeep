require 'json'
require 'grit_wrapper'

module Barkeep
  def render_barkeep
    return unless grit_info.repository?

    @@barkeep_config ||= JSON.parse(File.read("#{Rails.root}/config/barkeep.json"))

    content_tag(:dl, :id => 'barkeep') do
      @@barkeep_config['panes'].map do |name|
        if name =~ /^(p|partial) (.*)/
          render :partial => $2
        else
          send(name)
        end
      end <<
      content_tag(:dd, :class => 'close') do
        content_tag(:a, "&times;", :href => '#', :onclick => "c = document.getElementById('barkeep'); c.parentNode.removeChild(c); return false", :title => 'Close me!')
      end
    end
  end

  def branch_info
    content_tag(:dt, 'Branch:') +
      content_tag(:dd, content_tag(:a, grit_info[:branch], branch_link_attributes))
  end

  def commit_sha_info
    content_tag(:dt, 'Commit:') +
      content_tag(:dd, content_tag(:a, grit_info[:commit].try(:slice, 0,8), commit_link_attributes))
  end

  def commit_author_info
    content_tag(:dt, 'Who:') + content_tag(:dd, grit_info[:last_author])
  end

  def commit_date_info
    content_tag(:dt, 'When:') + content_tag(:dd, grit_info[:date].try(:to_s, :short), :title => grit_info[:date].to_s)
  end

  def rpm_request_info
    if rpm_enabled?
      content_tag(:dt, link_to('RPM', '/newrelic', :target => 'blank') + ':') <<
        content_tag(:dd, link_to('request', rpm_url, :target => 'blank'))
    end
  end

  def github_url
    @@barkeep_config['github_url']
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
      :title => "committed #{grit_info[:date]}"
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

  def rpm_url
    rpm_id = NewRelic::Agent.instance.transaction_sampler.current_sample_id
    "/newrelic/show_sample_detail/#{rpm_id}"
  end
end
