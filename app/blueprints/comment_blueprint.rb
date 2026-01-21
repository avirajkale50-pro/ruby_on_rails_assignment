class CommentBlueprint < Blueprinter::Base
  identifier :id

  fields :body, :created_at, :updated_at

  field :author do |comment|
    comment.user.email
  end

  field :blog_id
end
