# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
Comment.destroy_all
Blog.destroy_all

10.times do |i|
  blog = Blog.create!(
    title: "Published Blog #{i}",
    body: "Content #{i}",
    published: true
  )

  2.times do
    blog.comments.create!(body: "Comment on published blog")
  end
end

10.times do |i|
  Blog.create!(
    title: "Draft Blog #{i}",
    body: "Content #{i}",
    published: false
  )
end
