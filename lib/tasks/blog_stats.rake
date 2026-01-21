namespace :blogs do
  desc "Display blog statistics (total, published, and unpublished counts)"
  task stats: :environment do
    total_count = Blog.count
    published_count = Blog.published.count
    unpublished_count = Blog.unpublished.count

    puts "\n" + "=" * 50
    puts "Blog Statistics".center(50)
    puts "=" * 50
    puts "Total Blogs:       #{total_count}"
    puts "Published:         #{published_count}"
    puts "Unpublished:       #{unpublished_count}"
    puts "=" * 50
    puts "\n"
  end
end
