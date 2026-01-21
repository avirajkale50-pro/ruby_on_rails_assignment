# Rake Tasks Guide

## What are Rake Tasks?

Rake is a build automation tool for Ruby. Rake tasks are Ruby scripts that automate common administrative and maintenance tasks in Rails applications.

## How Rake Tasks are Loaded

### Automatic Loading
Rails automatically loads all `.rake` files from:
```
lib/tasks/**/*.rake
```

When you run `rails -T` or any rake command, Rails:
1. Loads the Rails environment
2. Scans `lib/tasks/` directory
3. Loads all `.rake` files
4. Makes tasks available via command line

### No Configuration Needed
- No need to require files
- No need to register tasks
- Just create a `.rake` file in `lib/tasks/`

---

## Basic Rake Task Structure

### Simple Task
```ruby
# lib/tasks/hello.rake
task :hello do
  puts "Hello, World!"
end
```

Run with:
```bash
rails hello
```

### Task with Description
```ruby
desc "Say hello to the world"
task :hello do
  puts "Hello, World!"
end
```

The `desc` makes it appear in `rails -T` listing.

### Task with Environment
```ruby
desc "Access Rails models"
task :hello => :environment do
  puts "Total users: #{User.count}"
end
```

The `:environment` dependency loads Rails and all models.

---

## Our Blog Stats Task

### Implementation
```ruby
# lib/tasks/blog_stats.rake
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
```

### Usage
```bash
rails blogs:stats
```

### Output
```
==================================================
                 Blog Statistics                  
==================================================
Total Blogs:       19
Published:         9
Unpublished:       10
==================================================
```

---

## Namespaces

Namespaces organize related tasks together.

### Creating Namespaces
```ruby
namespace :db do
  desc "Seed database"
  task :seed => :environment do
    # Seeding logic
  end
  
  desc "Reset database"
  task :reset => :environment do
    # Reset logic
  end
end
```

### Running Namespaced Tasks
```bash
rails db:seed
rails db:reset
```

### Nested Namespaces
```ruby
namespace :db do
  namespace :migrate do
    task :status => :environment do
      # Show migration status
    end
  end
end

# Run with:
# rails db:migrate:status
```

---

## Task Dependencies

### Single Dependency
```ruby
task :second => :first do
  puts "Second task"
end

task :first do
  puts "First task"
end

# Running 'rails second' executes both tasks in order
```

### Multiple Dependencies
```ruby
task :deploy => [:test, :migrate, :restart] do
  puts "Deployment complete"
end
```

### Environment Dependency
```ruby
# Always add :environment to access Rails
task :my_task => :environment do
  User.all.each { |u| puts u.email }
end
```

---

## Passing Arguments

### Single Argument
```ruby
desc "Greet a user"
task :greet, [:name] => :environment do |t, args|
  puts "Hello, #{args[:name]}!"
end
```

Run with:
```bash
rails "greet[John]"
```

### Multiple Arguments
```ruby
desc "Create user"
task :create_user, [:name, :email] => :environment do |t, args|
  User.create(name: args[:name], email: args[:email])
  puts "Created user: #{args[:name]}"
end
```

Run with:
```bash
rails "create_user[John,john@example.com]"
```

### With Defaults
```ruby
task :greet, [:name] => :environment do |t, args|
  args.with_defaults(name: "Guest")
  puts "Hello, #{args[:name]}!"
end
```

---

## Common Rake Task Patterns

### Data Migration
```ruby
namespace :data do
  desc "Migrate old blog format to new format"
  task :migrate_blogs => :environment do
    Blog.where(format: 'old').find_each do |blog|
      blog.update(format: 'new', content: transform_content(blog.content))
      print "."
    end
    puts "\nMigration complete!"
  end
end
```

### Cleanup Task
```ruby
namespace :cleanup do
  desc "Delete old unpublished blogs"
  task :old_drafts => :environment do
    count = Blog.unpublished
                .where("created_at < ?", 30.days.ago)
                .delete_all
    puts "Deleted #{count} old drafts"
  end
end
```

### Report Generation
```ruby
namespace :reports do
  desc "Generate monthly blog report"
  task :monthly => :environment do
    start_date = 1.month.ago.beginning_of_month
    end_date = 1.month.ago.end_of_month
    
    blogs = Blog.where(created_at: start_date..end_date)
    
    puts "Monthly Report: #{start_date.strftime('%B %Y')}"
    puts "Total Blogs: #{blogs.count}"
    puts "Published: #{blogs.published.count}"
    puts "Unpublished: #{blogs.unpublished.count}"
  end
end
```

### Batch Processing
```ruby
namespace :process do
  desc "Process all blogs"
  task :blogs => :environment do
    Blog.find_in_batches(batch_size: 100) do |batch|
      batch.each do |blog|
        # Process blog
        ProcessBlogJob.perform_later(blog.id)
      end
      puts "Processed batch of #{batch.size} blogs"
    end
  end
end
```

---

## Listing Available Tasks

### All Tasks
```bash
rails -T
```

### Tasks in Namespace
```bash
rails -T blogs
```

### Task Details
```bash
rails -D blogs:stats
```

---

## Invoking Tasks from Code

### From Another Task
```ruby
task :deploy => :environment do
  Rake::Task['db:migrate'].invoke
  Rake::Task['assets:precompile'].invoke
  puts "Deployment complete"
end
```

### From Rails Console
```ruby
Rake::Task['blogs:stats'].invoke
```

### From Controller/Model (Not Recommended)
```ruby
# Generally avoid this - use services instead
Rake::Task['some:task'].invoke
```

---

## Testing Rake Tasks

### RSpec Example
```ruby
# spec/tasks/blog_stats_spec.rb
require 'rails_helper'
require 'rake'

RSpec.describe "blogs:stats" do
  before do
    Rails.application.load_tasks
  end
  
  it "displays blog statistics" do
    create_list(:blog, 5, published: true)
    create_list(:blog, 3, published: false)
    
    expect {
      Rake::Task['blogs:stats'].invoke
    }.to output(/Total Blogs:\s+8/).to_stdout
  end
end
```

---

## Best Practices

1. **Always Use Descriptions**: Makes tasks discoverable with `rails -T`
2. **Use Namespaces**: Organize related tasks together
3. **Add :environment**: When accessing Rails models/constants
4. **Provide Feedback**: Use `puts` to show progress
5. **Handle Errors**: Add error handling for production tasks
6. **Make Idempotent**: Tasks should be safe to run multiple times
7. **Use Batch Processing**: For large datasets
8. **Add Logging**: Log important operations
9. **Document Arguments**: Explain required arguments in description
10. **Test Your Tasks**: Write specs for complex tasks

---

## Built-in Rails Tasks

Rails provides many useful built-in tasks:

```bash
rails db:migrate          # Run migrations
rails db:seed             # Seed database
rails db:reset            # Drop, create, migrate, seed
rails assets:precompile   # Compile assets
rails routes              # Show all routes
rails stats               # Show code statistics
rails notes               # Show TODO/FIXME comments
rails about               # Show Rails version info
```

---

## Scheduling Rake Tasks

### Cron
```bash
# crontab -e
0 2 * * * cd /path/to/app && rails blogs:stats >> log/cron.log 2>&1
```

### Whenever Gem
```ruby
# Gemfile
gem 'whenever', require: false

# config/schedule.rb
every 1.day, at: '2:00 am' do
  rake 'blogs:stats'
end
```

### Heroku Scheduler
```bash
# Add-on in Heroku dashboard
# Command: rails blogs:stats
```

---

## Conclusion

Rake tasks are powerful tools for:
- Automating repetitive tasks
- Data migrations
- Batch processing
- Report generation
- Maintenance operations

They're automatically loaded from `lib/tasks/`, easy to create, and integrate seamlessly with Rails.
