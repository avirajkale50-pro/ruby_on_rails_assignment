# Create Admin User
admin = User.find_or_create_by!(email: 'admin@blog.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.admin = true
end
# Ensure admin privileges if user already existed
admin.update(admin: true) unless admin.admin?
puts "Admin user created/found: #{admin.email}"

# Backfill existing blobs and comments (in case we didn't destroy them, or if running on existing db)
Blog.where(user_id: nil).update_all(user_id: admin.id)
puts "Assigned orphan blogs to admin"

Comment.where(user_id: nil).update_all(user_id: admin.id)
puts "Assigned orphan comments to admin"

# Ensure we have some data
if Blog.count == 0
  10.times do |i|
    blog = Blog.create!(
      title: "Published Blog #{i}",
      body: "Content #{i}",
      published: true,
      user: admin
    )

    2.times do
      blog.comments.create!(
        body: "Comment on published blog",
        user: admin
      )
    end
  end

  10.times do |i|
    Blog.create!(
      title: "Draft Blog #{i}",
      body: "Content #{i}",
      published: false,
      user: admin
    )
  end
  puts "Created sample blogs and comments"
end
