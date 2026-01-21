class BlogBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :body, :published, :created_at, :updated_at

  field :author do |blog|
    blog.user.email
  end

  # Default view - basic blog information
  view :default do
    field :comments_count do |blog|
      blog.comments.count
    end
  end

  # Extended view - includes associated comments
  view :with_comments do
    field :comments_count do |blog|
      blog.comments.count
    end
    
    association :comments, blueprint: CommentBlueprint do |blog|
      blog.comments.order(created_at: :desc)
    end
  end
end
