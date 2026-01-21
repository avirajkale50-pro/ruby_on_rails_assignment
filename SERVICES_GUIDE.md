# Services in Rails - A Comprehensive Guide

## What are Services?

Services are Plain Old Ruby Objects (POROs) that encapsulate business logic that doesn't naturally fit into models or controllers. They follow the Single Responsibility Principle and make your application more maintainable.

## Why Use Services?

### 1. **Separation of Concerns**
- Controllers should handle HTTP requests/responses
- Models should handle data persistence and validations
- Services handle complex business logic

### 2. **Testability**
- Services are easy to unit test in isolation
- No need for controller or integration tests for business logic
- Faster test execution

### 3. **Reusability**
- Business logic can be called from multiple places:
  - Controllers
  - Background jobs
  - Rake tasks
  - Console
  - Other services

### 4. **Maintainability**
- Clear, single-purpose classes
- Easier to understand and modify
- Better code organization

### 5. **Flexibility**
- Easy to swap implementations
- Can add logging, error handling, notifications
- Supports complex workflows

---

## When to Use Services

✅ **Use Services When:**
- Logic involves multiple models
- Complex business rules need to be enforced
- External APIs are called
- Background jobs need to share logic
- Operations have multiple steps
- Logic is reused across the application

❌ **Don't Use Services When:**
- Simple CRUD operations
- Logic belongs in model callbacks
- Single-model validations
- Simple data transformations

---

## Service Pattern Examples

### Basic Service Structure

```ruby
class MyService
  def self.call(*args)
    new(*args).call
  end

  def initialize(param1, param2)
    @param1 = param1
    @param2 = param2
  end

  def call
    # Business logic here
  end
end
```

### Our BlogPublishingService

```ruby
class BlogPublishingService
  class PublishError < StandardError; end

  def self.publish(blog)
    raise PublishError, "Blog not found" if blog.nil?
    raise PublishError, "Blog is already published" if blog.published?

    if blog.update(published: true)
      Rails.logger.info "Blog ##{blog.id} was published"
      true
    else
      raise PublishError, "Failed to publish: #{blog.errors.full_messages.join(', ')}"
    end
  end
end
```

**Benefits Demonstrated:**
1. **Error Handling**: Custom exception for publish errors
2. **Logging**: Tracks publishing events
3. **Validation**: Checks blog state before publishing
4. **Reusability**: Used by both controller and background job

---

## Service Organization

### Directory Structure
```
app/
  services/
    blog_publishing_service.rb
    user_registration_service.rb
    payment_processing_service.rb
    concerns/
      notifiable.rb
```

### Naming Conventions
- Use descriptive names: `BlogPublishingService`, not `BlogService`
- End with `Service`: `OrderProcessingService`
- Use verbs: `UserRegistrationService`, `EmailNotificationService`

---

## Comparison: Controller vs Model vs Service

### ❌ Fat Controller (Bad)
```ruby
class BlogsController < ApplicationController
  def publish
    @blog = Blog.find(params[:id])
    
    if @blog.published?
      redirect_to @blog, alert: "Already published"
      return
    end
    
    @blog.update(published: true)
    NotificationMailer.blog_published(@blog).deliver_later
    SlackNotifier.notify("Blog published: #{@blog.title}")
    
    redirect_to @blog, notice: "Published!"
  end
end
```

### ❌ Fat Model (Bad)
```ruby
class Blog < ApplicationRecord
  def publish!
    return false if published?
    
    update(published: true)
    NotificationMailer.blog_published(self).deliver_later
    SlackNotifier.notify("Blog published: #{title}")
    true
  end
end
```

### ✅ Service (Good)
```ruby
class BlogPublishingService
  def self.publish(blog)
    raise PublishError, "Already published" if blog.published?
    
    ActiveRecord::Base.transaction do
      blog.update!(published: true)
      NotificationMailer.blog_published(blog).deliver_later
      SlackNotifier.notify("Blog published: #{blog.title}")
    end
    
    true
  rescue => e
    Rails.logger.error "Failed to publish blog: #{e.message}"
    raise
  end
end

# Controller stays thin
class BlogsController < ApplicationController
  def publish
    BlogPublishingService.publish(@blog)
    redirect_to @blog, notice: "Published!"
  rescue BlogPublishingService::PublishError => e
    redirect_to @blog, alert: e.message
  end
end
```

---

## Testing Services

### RSpec Example
```ruby
RSpec.describe BlogPublishingService do
  describe '.publish' do
    let(:blog) { create(:blog, published: false) }
    
    it 'publishes an unpublished blog' do
      expect {
        BlogPublishingService.publish(blog)
      }.to change { blog.reload.published? }.from(false).to(true)
    end
    
    it 'raises error for already published blog' do
      blog.update(published: true)
      
      expect {
        BlogPublishingService.publish(blog)
      }.to raise_error(BlogPublishingService::PublishError)
    end
  end
end
```

---

## Advanced Patterns

### Result Object Pattern
```ruby
class BlogPublishingService
  Result = Struct.new(:success?, :blog, :error, keyword_init: true)
  
  def self.publish(blog)
    return Result.new(success?: false, error: "Already published") if blog.published?
    
    if blog.update(published: true)
      Result.new(success?: true, blog: blog)
    else
      Result.new(success?: false, error: blog.errors.full_messages.join(', '))
    end
  end
end

# Usage
result = BlogPublishingService.publish(blog)
if result.success?
  redirect_to result.blog, notice: "Published!"
else
  redirect_to @blog, alert: result.error
end
```

### Service Objects with Dry-rb
```ruby
class BlogPublishingService
  include Dry::Monads[:result]
  
  def call(blog)
    return Failure(:already_published) if blog.published?
    
    if blog.update(published: true)
      Success(blog)
    else
      Failure(:update_failed)
    end
  end
end
```

---

## Best Practices

1. **Keep Services Focused**: One service, one responsibility
2. **Use Class Methods for Simple Services**: `Service.call(args)`
3. **Use Instance Methods for Complex Services**: `Service.new(args).call`
4. **Return Meaningful Values**: Boolean, result object, or raise exceptions
5. **Add Logging**: Track important operations
6. **Handle Errors Gracefully**: Custom exceptions with clear messages
7. **Use Transactions**: For multi-step operations
8. **Document Public Methods**: Clear parameter and return descriptions

---

## Conclusion

Services are a powerful pattern for organizing business logic in Rails applications. They promote:
- **Clean architecture**
- **Testable code**
- **Reusable logic**
- **Maintainable applications**

Use them wisely to keep your controllers thin and your models focused on data.
