require 'grit'

# A singleton refreshes on every request in development but
# caches in environments where class caching is enabled.
require 'singleton'

class GritWrapper
  include Singleton

  def repository
    @repository ||= Grit::Repo.new(Rails.root)
  rescue Grit::InvalidGitRepositoryError
    # not in a directory that contains .git
    @repository = :invalid
  end

  def repository?
    !repository.nil? && repository != :invalid
  end

  def head
    @head ||= repository.head
  end

  def last_commit_hash
    @last_commit_hash ||= head.commit.to_s
  end

  def last_commit
    @last_commit ||= repository.commit(last_commit_hash)
  end

  def to_hash
    return {
      :branch => 'Not currently on a branch.',
      :commit => (File.read(Rails.root + "/REVISION").strip rescue nil)
    } if head.nil?

    @hash ||= {
      :branch => head.name,
      :commit => last_commit_hash,
      :last_author => last_commit.try(:author),
      :message => last_commit.try(:message),
      :date => last_commit.try(:authored_date)
    }
  end

  def [](key)
    to_hash[key]
  end
end
