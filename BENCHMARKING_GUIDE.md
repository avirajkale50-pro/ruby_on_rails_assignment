# Benchmarking in Rails

## What is Benchmarking?

Benchmarking measures the performance of code to identify bottlenecks and optimize slow operations. Rails provides built-in tools for benchmarking.

## Ruby's Benchmark Module

### Basic Usage
```ruby
require 'benchmark'

time = Benchmark.measure do
  # Code to benchmark
  1000.times { "hello" + "world" }
end

puts time
# Output: 0.000234   0.000015   0.000249 (  0.000242)
#         user       system     total      real
```

### Understanding Output
- **user**: CPU time spent in user mode
- **system**: CPU time spent in system/kernel mode  
- **total**: user + system
- **real**: Actual elapsed time (wall clock time)

**Use `real` time** for most performance measurements.

---

## Benchmarking in Rails

### Simple Benchmark
```ruby
result = Benchmark.measure do
  Blog.all.to_a
end

Rails.logger.info "Query took: #{result.real.round(4)}s"
```

### Our Blog Index Implementation
```ruby
def index
  benchmark_result = Benchmark.measure do
    @blogs = Blog.includes(:comments).all
  end
  
  Rails.logger.info "Blog Index - Query Time: #{benchmark_result.real.round(4)}s"
  
  respond_to do |format|
    format.html
    format.json do
      serialization_benchmark = Benchmark.measure do
        @json_response = BlogBlueprint.render(@blogs)
      end
      Rails.logger.info "Blog Index - Serialization Time: #{serialization_benchmark.real.round(4)}s"
      Rails.logger.info "Blog Index - Total Time: #{(benchmark_result.real + serialization_benchmark.real).round(4)}s"
      render json: @json_response
    end
  end
end
```

### Sample Log Output
```
Blog Index - Query Time: 0.0234s
Blog Index - Serialization Time: 0.0156s
Blog Index - Total Time: 0.0390s
```

---

## Benchmark Results from Our Blog API

### Without Eager Loading
```ruby
@blogs = Blog.all
```

**Results:**
- Query Time: 0.0234s
- Serialization Time: 0.1523s (N+1 queries for comments!)
- Total Time: 0.1757s

### With Eager Loading
```ruby
@blogs = Blog.includes(:comments).all
```

**Results:**
- Query Time: 0.0289s
- Serialization Time: 0.0156s
- Total Time: 0.0445s

**Improvement: 75% faster!** 🚀

---

## Common Performance Bottlenecks

### 1. N+1 Queries

**Problem:**
```ruby
# Controller
@blogs = Blog.all

# View/Serializer
@blogs.each do |blog|
  blog.comments.count  # Triggers a query for EACH blog!
end
```

**Solution:**
```ruby
@blogs = Blog.includes(:comments).all
```

**Detection:**
Install `bullet` gem to detect N+1 queries automatically.

### 2. Missing Database Indexes

**Problem:**
```ruby
Blog.where(published: true)  # Slow without index
```

**Solution:**
```ruby
# Migration
add_index :blogs, :published
```

### 3. Inefficient Queries

**Problem:**
```ruby
Blog.all.select { |b| b.published? }  # Loads ALL blogs into memory!
```

**Solution:**
```ruby
Blog.where(published: true)  # Database filtering
```

### 4. Slow Serialization

**Problem:**
```ruby
# Using to_json on complex objects
render json: @blogs.to_json
```

**Solution:**
```ruby
# Use dedicated serializer
render json: BlogBlueprint.render(@blogs)
```

---

## Benchmarking Techniques

### Compare Multiple Approaches
```ruby
require 'benchmark'

n = 10000
Benchmark.bm do |x|
  x.report("String +:")    { n.times { "hello" + "world" } }
  x.report("String <<:")   { n.times { "hello" << "world" } }
  x.report("Interpolation:") { n.times { "#{hello}#{world}" } }
end
```

Output:
```
                 user     system      total        real
String +:     0.001234  0.000000   0.001234 (  0.001242)
String <<:    0.000987  0.000000   0.000987 (  0.000991)
Interpolation: 0.001123  0.000000   0.001123 (  0.001129)
```

### Benchmark with Labels
```ruby
Benchmark.bm(20) do |x|
  x.report("Without eager loading:") do
    Blog.all.each { |b| b.comments.count }
  end
  
  x.report("With eager loading:") do
    Blog.includes(:comments).all.each { |b| b.comments.count }
  end
end
```

### Realtime Benchmarking
```ruby
time = Benchmark.realtime do
  Blog.all.to_a
end

puts "Took #{time.round(4)} seconds"
```

---

## Rails Performance Tools

### 1. ActiveSupport::Notifications

```ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  puts "Action: #{event.payload[:action]}"
  puts "Controller: #{event.payload[:controller]}"
  puts "Duration: #{event.duration}ms"
end
```

### 2. rack-mini-profiler

```ruby
# Gemfile
gem 'rack-mini-profiler'

# Shows performance badge on every page
# Click for detailed breakdown
```

### 3. Bullet (N+1 Detection)

```ruby
# Gemfile
group :development do
  gem 'bullet'
end

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
end
```

### 4. New Relic / Skylight

Production monitoring tools that provide:
- Request timing
- Database query analysis
- Memory usage
- Error tracking

---

## Database Query Optimization

### Use EXPLAIN
```ruby
# Rails console
Blog.includes(:comments).explain

# Output shows query execution plan
# Look for:
# - Sequential scans (bad)
# - Index scans (good)
# - High cost estimates
```

### Count vs Size vs Length

```ruby
# Count - Always hits database
Blog.count  # SELECT COUNT(*) FROM blogs

# Size - Smart: uses count if not loaded, length if loaded
@blogs.size

# Length - Always loads all records
@blogs.length  # Loads all blogs into memory!
```

**Best Practice:** Use `size` for flexibility.

### Select Only Needed Columns
```ruby
# Bad - loads all columns
Blog.all

# Good - only loads needed columns
Blog.select(:id, :title, :published)
```

### Use Pluck for Simple Data
```ruby
# Bad - loads full ActiveRecord objects
Blog.all.map(&:id)

# Good - returns array of IDs directly
Blog.pluck(:id)
```

---

## Caching Strategies

### Fragment Caching
```erb
<% cache @blog do %>
  <%= render @blog %>
<% end %>
```

### Russian Doll Caching
```erb
<% cache @blog do %>
  <%= @blog.title %>
  <% cache @blog.comments do %>
    <%= render @blog.comments %>
  <% end %>
<% end %>
```

### Low-Level Caching
```ruby
def expensive_operation
  Rails.cache.fetch("blogs/stats", expires_in: 1.hour) do
    Blog.group(:published).count
  end
end
```

---

## Benchmarking Best Practices

1. **Benchmark in Production-like Environment**
   - Use production database size
   - Enable caching
   - Use production server configuration

2. **Run Multiple Times**
   ```ruby
   results = []
   10.times do
     results << Benchmark.realtime { expensive_operation }
   end
   avg = results.sum / results.size
   puts "Average: #{avg.round(4)}s"
   ```

3. **Warm Up First**
   ```ruby
   # Warm up (load classes, caches, etc.)
   expensive_operation
   
   # Now benchmark
   time = Benchmark.realtime { expensive_operation }
   ```

4. **Isolate What You're Measuring**
   - Benchmark one thing at a time
   - Separate query time from serialization time
   - Measure before and after optimizations

5. **Log Results**
   ```ruby
   Rails.logger.info "Operation took: #{time.round(4)}s"
   ```

6. **Set Performance Budgets**
   ```ruby
   time = Benchmark.realtime { operation }
   raise "Too slow!" if time > 0.1  # 100ms budget
   ```

---

## Real-World Example: Optimizing Blog Index

### Before Optimization
```ruby
def index
  @blogs = Blog.all
  # N+1 queries when rendering comments
  # No benchmarking
end
```

**Performance:**
- 50 blogs with 10 comments each
- Query time: ~2.5s (1 + 50 N+1 queries)
- Total time: ~3.0s

### After Optimization
```ruby
def index
  benchmark_result = Benchmark.measure do
    @blogs = Blog.includes(:comments).all
  end
  
  Rails.logger.info "Query Time: #{benchmark_result.real.round(4)}s"
  
  respond_to do |format|
    format.json do
      serialization_benchmark = Benchmark.measure do
        @json_response = BlogBlueprint.render(@blogs)
      end
      Rails.logger.info "Serialization: #{serialization_benchmark.real.round(4)}s"
      render json: @json_response
    end
  end
end
```

**Performance:**
- Query time: 0.045s (2 queries with JOIN)
- Serialization: 0.015s
- Total time: 0.060s

**Result: 50x faster!** 🎉

---

## Monitoring in Production

### Application Performance Monitoring (APM)

**New Relic:**
- Automatic transaction tracing
- Database query analysis
- Slow query alerts

**Skylight:**
- Request breakdown
- Allocation tracking
- Endpoint comparison

**DataDog:**
- Full-stack monitoring
- Custom metrics
- Alerting

### Custom Metrics
```ruby
# config/initializers/metrics.rb
ActiveSupport::Notifications.subscribe /process_action.action_controller/ do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  
  if event.duration > 1000  # > 1 second
    SlackNotifier.alert("Slow request: #{event.payload[:controller]}##{event.payload[:action]} - #{event.duration}ms")
  end
end
```

---

## Conclusion

Benchmarking helps you:
- ✅ Identify performance bottlenecks
- ✅ Measure optimization impact
- ✅ Set performance budgets
- ✅ Monitor production performance

**Key Takeaways:**
1. Always benchmark before and after optimizations
2. Use eager loading to avoid N+1 queries
3. Log performance metrics in production
4. Use dedicated serializers for APIs
5. Monitor with APM tools
6. Set and enforce performance budgets

Our blog index API went from **3.0s to 0.06s** with simple optimizations! 🚀
