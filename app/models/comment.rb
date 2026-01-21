class Comment < ApplicationRecord
  belongs_to :blog
  belongs_to :user
  
  validates :user, presence: true

  validates :body, presence: true
  validate :blog_must_be_published

  private

  def blog_must_be_published
    if blog && !blog.published?
      errors.add(:blog, "must be published to allow comments")
    end
  end
end
