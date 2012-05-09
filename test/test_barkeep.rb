require 'helper'

class TestBarkeep < Test::Unit::TestCase
  include Barkeep

  attr_accessor :output_buffer

  def setup
    @barkeep = barkeep
    @barkeep.stubs({
      :config => {'github_url' => 'http://github.com/project_name', 'panes' => ['branch_info', 'commit_sha_info'], 'environments' => ['development']},
      :load? => true
    })
  end

  should "render a style tag filled with css" do
    css = File.read(File.expand_path(File.dirname(__FILE__) + "/../lib/default.css"))
    assert_equal "<style>#{css}</style>", barkeep.styles
  end

  should "render the barkeep bar" do
    GritWrapper.instance.stubs(:repository? => true, :to_hash => {:branch => 'new_branch', :commit => 'abcdef', :last_author => 'Johnny', :date => '2/11/2012'})
    expected = %(
      <dl id="barkeep">
        <dt>Branch:</dt>
        <dd><a href="http://github.com/project_name/tree/new_branch">new_branch</a></dd>
        <dt>Commit:</dt>
        <dd><a href="http://github.com/project_name/commit/abcdef" title="committed 2/11/2012 by Johnny">abcdef</a></dd>
        <dd class="close"><a href="#" onclick="c = document.getElementById('barkeep'); c.parentNode.removeChild(c); return false" title="Close me!">&times;</a></dd>
      </dl>
    )
    assert_equal expected.gsub(/\s+/, ''), barkeep.render.gsub(/\s+/, '')
  end
end

