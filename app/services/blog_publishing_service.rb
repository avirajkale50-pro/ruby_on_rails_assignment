class BlogPublishingService
  class PublishError < StandardError; end

  # Publishes a blog post
  # @param blog [Blog] the blog to publish
  # @return [Boolean] true if successful
  # @raise [PublishError] if blog cannot be published
  def self.publish(blog)
    raise PublishError, "Blog not found" if blog.nil?
    raise PublishError, "Blog is already published" if blog.published?

    if blog.update(published: true)
      Rails.logger.info "Blog ##{blog.id} '#{blog.title}' was published successfully"
      true
    else
      raise PublishError, "Failed to publish blog: #{blog.errors.full_messages.join(', ')}"
    end
  end

  # Unpublishes a blog post
  # @param blog [Blog] the blog to unpublish
  # @return [Boolean] true if successful
  # @raise [PublishError] if blog cannot be unpublished
  def self.unpublish(blog)
    raise PublishError, "Blog not found" if blog.nil?
    raise PublishError, "Blog is already unpublished" if !blog.published?

    if blog.update(published: false)
      Rails.logger.info "Blog ##{blog.id} '#{blog.title}' was unpublished successfully"
      true
    else
      raise PublishError, "Failed to unpublish blog: #{blog.errors.full_messages.join(', ')}"
    end
  end

  # Toggles the published status of a blog
  # @param blog [Blog] the blog to toggle
  # @return [Boolean] true if successful
  def self.toggle_publish(blog)
    if blog.published?
      unpublish(blog)
    else
      publish(blog)
    end
  end
end
