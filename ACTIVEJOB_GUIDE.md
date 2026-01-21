# ActiveJob Guide - perform_now vs perform_later

## What is ActiveJob?

ActiveJob is a framework for declaring jobs and making them run on a variety of queuing backends. It provides a unified interface for background job processing in Rails.

## perform_now vs perform_later

### perform_now

**Executes the job immediately** in the current process, blocking until completion.

```ruby
PublishBlogJob.perform_now(blog.id)
# Code waits here until job completes
puts "Job finished!"
```

**Use Cases:**
- ✅ Testing jobs in development/test environments
- ✅ When you need immediate execution
- ✅ Debugging job logic
- ✅ Simple scripts or rake tasks

**Characteristics:**
- Synchronous execution
- Blocks the current thread
- No queue backend needed
- Immediate error feedback
- No retry mechanism

### perform_later

**Enqueues the job** to be executed asynchronously by a background worker.

```ruby
PublishBlogJob.perform_later(blog.id)
# Code continues immediately
puts "Job enqueued!"
```

**Use Cases:**
- ✅ Production environments
- ✅ Long-running tasks
- ✅ Email sending
- ✅ External API calls
- ✅ Image processing
- ✅ Scheduled tasks

**Characteristics:**
- Asynchronous execution
- Non-blocking
- Requires queue backend (Sidekiq, Resque, etc.)
- Supports retries
- Can be scheduled for later

---

## Scheduling Jobs

### Immediate Execution
```ruby
PublishBlogJob.perform_later(blog.id)
```

### Delayed Execution
```ruby
# Execute in 1 hour
PublishBlogJob.set(wait: 1.hour).perform_later(blog.id)

# Execute at specific time
PublishBlogJob.set(wait_until: Date.tomorrow.noon).perform_later(blog.id)
```

### Our Implementation
```ruby
# In blogs_controller.rb create action
if !@blog.published?
  PublishBlogJob.set(wait: 1.hour).perform_later(@blog.id)
  Rails.logger.info "Scheduled auto-publish for blog ##{@blog.id} in 1 hour"
end
```

---

## Queue Adapters

Rails supports multiple queue backends:

### Development (Default: Async)
```ruby
# config/environments/development.rb
config.active_job.queue_adapter = :async
```
- Runs jobs in-process using thread pool
- Jobs lost on server restart
- Good for development

### Test (Default: Test)
```ruby
# config/environments/test.rb
config.active_job.queue_adapter = :test
```
- Jobs stored in array for testing
- Not executed automatically
- Access via `ActiveJob::Base.queue_adapter.enqueued_jobs`

### Production Options

#### Sidekiq (Recommended)
```ruby
# Gemfile
gem 'sidekiq'

# config/application.rb
config.active_job.queue_adapter = :sidekiq
```
- Redis-backed
- Fast and reliable
- Web UI for monitoring
- Supports retries and scheduling

#### Resque
```ruby
config.active_job.queue_adapter = :resque
```
- Redis-backed
- Fork-based workers
- Good for memory-intensive jobs

#### Delayed Job
```ruby
config.active_job.queue_adapter = :delayed_job
```
- Database-backed
- No external dependencies
- Slower than Redis-based options

---

## Job Structure

### Basic Job
```ruby
class PublishBlogJob < ApplicationJob
  queue_as :default
  
  def perform(blog_id)
    blog = Blog.find(blog_id)
    # Do work here
  end
end
```

### With Error Handling
```ruby
class PublishBlogJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 3
  
  def perform(blog_id)
    blog = Blog.find_by(id: blog_id)
    return if blog.nil?
    
    BlogPublishingService.publish(blog)
  rescue BlogPublishingService::PublishError => e
    Rails.logger.error "Failed to publish: #{e.message}"
    raise # Re-raise to trigger retry
  end
end
```

### With Callbacks
```ruby
class PublishBlogJob < ApplicationJob
  before_perform :log_start
  after_perform :log_completion
  around_perform :benchmark
  
  def perform(blog_id)
    # Job logic
  end
  
  private
  
  def log_start
    Rails.logger.info "Starting PublishBlogJob for blog ##{arguments.first}"
  end
  
  def log_completion
    Rails.logger.info "Completed PublishBlogJob"
  end
  
  def benchmark
    time = Benchmark.measure { yield }
    Rails.logger.info "Job took #{time.real}s"
  end
end
```

---

## Testing Jobs

### RSpec Examples

#### Test Job Enqueuing
```ruby
RSpec.describe "Blog creation" do
  it "enqueues publish job for unpublished blog" do
    expect {
      post blogs_path, params: { blog: { title: "Test", body: "Body", published: false } }
    }.to have_enqueued_job(PublishBlogJob)
  end
end
```

#### Test Job Execution
```ruby
RSpec.describe PublishBlogJob do
  it "publishes the blog" do
    blog = create(:blog, published: false)
    
    PublishBlogJob.perform_now(blog.id)
    
    expect(blog.reload).to be_published
  end
end
```

#### Test Scheduled Jobs
```ruby
it "schedules job for 1 hour later" do
  blog = create(:blog, published: false)
  
  expect {
    described_class.set(wait: 1.hour).perform_later(blog.id)
  }.to have_enqueued_job.at(1.hour.from_now)
end
```

---

## Monitoring and Debugging

### Check Enqueued Jobs (Development)
```ruby
# Rails console
ActiveJob::Base.queue_adapter.enqueued_jobs
```

### Sidekiq Web UI
```ruby
# config/routes.rb
require 'sidekiq/web'
mount Sidekiq::Web => '/sidekiq'
```

### Logging
```ruby
# Our implementation includes comprehensive logging
Rails.logger.info "PublishBlogJob: Successfully published blog ##{blog_id}"
Rails.logger.error "PublishBlogJob: Failed to publish blog ##{blog_id}: #{e.message}"
```

---

## Best Practices

1. **Keep Jobs Idempotent**: Jobs should be safe to run multiple times
2. **Handle Missing Records**: Use `find_by` instead of `find`
3. **Add Logging**: Track job execution and errors
4. **Use Retries Wisely**: Configure appropriate retry strategies
5. **Pass IDs, Not Objects**: Pass `blog.id`, not `blog`
6. **Set Appropriate Queues**: Separate critical and non-critical jobs
7. **Monitor Job Performance**: Use tools like Sidekiq Pro or New Relic
8. **Test Thoroughly**: Test both enqueuing and execution

---

## Comparison Table

| Feature | perform_now | perform_later |
|---------|-------------|---------------|
| Execution | Synchronous | Asynchronous |
| Blocking | Yes | No |
| Queue Backend | Not needed | Required |
| Retries | No | Yes (configurable) |
| Scheduling | No | Yes |
| Use in Production | Rarely | Always |
| Testing | Easy | Requires setup |
| Error Handling | Immediate | Delayed |

---

## Conclusion

- Use **perform_now** for testing and immediate execution
- Use **perform_later** for production background processing
- Always handle errors gracefully
- Log important events
- Choose the right queue adapter for your needs
- Test both enqueuing and execution
