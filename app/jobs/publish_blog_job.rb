class PublishBlogJob < ApplicationJob
  queue_as :default

  # Automatically publishes a blog after a delay
  # @param blog_id [Integer] the ID of the blog to publish
  def perform(blog_id)
    blog = Blog.find_by(id: blog_id)
    
    if blog.nil?
      Rails.logger.warn "PublishBlogJob: Blog with ID #{blog_id} not found"
      return
    end

    if blog.published?
      Rails.logger.info "PublishBlogJob: Blog ##{blog_id} is already published"
      return
    end

    begin
      BlogPublishingService.publish(blog)
      Rails.logger.info "PublishBlogJob: Successfully published blog ##{blog_id} '#{blog.title}'"
    rescue BlogPublishingService::PublishError => e
      Rails.logger.error "PublishBlogJob: Failed to publish blog ##{blog_id}: #{e.message}"
      raise # Re-raise to allow job retry mechanisms
    end
  end
end
