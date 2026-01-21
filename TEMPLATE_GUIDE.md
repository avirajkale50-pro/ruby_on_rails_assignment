# Ruby Template Embedding Guide

This guide explores how Ruby code is embedded in templates, comparing ERB and HAML approaches, and demonstrating Rails view helpers.

## Table of Contents
1. [ERB (Embedded Ruby)](#erb-embedded-ruby)
2. [HAML (HTML Abstraction Markup Language)](#haml-html-abstraction-markup-language)
3. [Partials and Locals](#partials-and-locals)
4. [Rails Form Helpers](#rails-form-helpers)
5. [Comparison Table](#comparison-table)

---

## ERB (Embedded Ruby)

ERB is the default templating engine in Rails. It allows you to embed Ruby code directly into HTML.

### Basic Syntax

```erb
<!-- Output Ruby expression -->
<%= ruby_expression %>

<!-- Execute Ruby code without output -->
<% ruby_code %>

<!-- Comments (not rendered in HTML) -->
<%# This is a comment %>
```

### Examples

#### 1. Variables and Expressions
```erb
<h1><%= @blog.title %></h1>
<p>Created <%= time_ago_in_words(@blog.created_at) %> ago</p>
```

#### 2. Conditionals
```erb
<% if @blog.published? %>
  <span class="published">Published</span>
<% else %>
  <span class="unpublished">Unpublished</span>
<% end %>
```

#### 3. Loops
```erb
<% @blogs.each do |blog| %>
  <div class="blog">
    <h2><%= blog.title %></h2>
    <p><%= blog.body %></p>
  </div>
<% end %>
```

#### 4. Form Helpers
```erb
<%= form_with(model: @blog, local: true) do |form| %>
  <%= form.label :title %>
  <%= form.text_field :title %>
  
  <%= form.label :body %>
  <%= form.text_area :body %>
  
  <%= form.submit "Save" %>
<% end %>
```

---

## HAML (HTML Abstraction Markup Language)

HAML is a cleaner, more concise alternative to ERB. It uses indentation instead of closing tags.

### Basic Syntax

```haml
-# Output Ruby expression
= ruby_expression

-# Execute Ruby code without output
- ruby_code

-# Comments (not rendered in HTML)
-# This is a comment

-# HTML elements
%tag content
%tag{ attribute: "value" } content
```

### Examples

#### 1. Variables and Expressions
```haml
%h1= @blog.title
%p
  Created
  = time_ago_in_words(@blog.created_at)
  ago
```

#### 2. Conditionals
```haml
- if @blog.published?
  %span.published Published
- else
  %span.unpublished Unpublished
```

#### 3. Loops
```haml
- @blogs.each do |blog|
  .blog
    %h2= blog.title
    %p= blog.body
```

#### 4. Form Helpers
```haml
= form_with(model: @blog, local: true) do |form|
  = form.label :title
  = form.text_field :title
  
  = form.label :body
  = form.text_area :body
  
  = form.submit "Save"
```

---

## Partials and Locals

Partials allow you to extract reusable view components. Locals pass variables to partials.

### ERB Partials

#### Defining a Partial (`_blog_card.html.erb`)
```erb
<div class="blog-card">
  <h2><%= link_to blog.title, blog %></h2>
  <p><%= truncate(blog.body, length: 200) %></p>
</div>
```

#### Rendering with Locals
```erb
<!-- Single render -->
<%= render partial: "blogs/blog_card", locals: { blog: @blog } %>

<!-- Collection render -->
<%= render partial: "blogs/blog_card", collection: @blogs, as: :blog %>

<!-- Shorthand for collections -->
<%= render @blogs %>
```

### HAML Partials

#### Defining a Partial (`_blog_card.html.haml`)
```haml
.blog-card
  %h2= link_to blog.title, blog
  %p= truncate(blog.body, length: 200)
```

#### Rendering with Locals
```haml
-# Single render
= render partial: "blogs/blog_card", locals: { blog: @blog }

-# Collection render
= render partial: "blogs/blog_card", collection: @blogs, as: :blog
```

---

## Rails Form Helpers

Rails provides powerful form helpers that work with both ERB and HAML.

### `form_with` Helper

#### ERB Example
```erb
<%= form_with(model: [@blog, @comment], local: true) do |form| %>
  <div class="field">
    <%= form.label :body, "Comment:" %>
    <%= form.text_area :body, rows: 4, placeholder: "Your comment..." %>
  </div>
  
  <%= form.submit "Post Comment", class: "btn" %>
<% end %>
```

#### HAML Example
```haml
= form_with(model: [@blog, @comment], local: true) do |form|
  .field
    = form.label :body, "Comment:"
    = form.text_area :body, rows: 4, placeholder: "Your comment..."
  
  = form.submit "Post Comment", class: "btn"
```

### Common Form Helpers

| Helper | Purpose | Example |
|--------|---------|---------|
| `text_field` | Single-line text input | `form.text_field :title` |
| `text_area` | Multi-line text input | `form.text_area :body` |
| `password_field` | Password input | `form.password_field :password` |
| `email_field` | Email input | `form.email_field :email` |
| `number_field` | Number input | `form.number_field :age` |
| `check_box` | Checkbox | `form.check_box :published` |
| `radio_button` | Radio button | `form.radio_button :status, "active"` |
| `select` | Dropdown | `form.select :category, options` |
| `submit` | Submit button | `form.submit "Save"` |

---

## Comparison Table

| Feature | ERB | HAML |
|---------|-----|------|
| **Syntax** | HTML-like with `<% %>` tags | Indentation-based |
| **Output** | `<%= %>` | `=` |
| **Execute** | `<% %>` | `-` |
| **Comments** | `<%# %>` | `-#` |
| **HTML Tags** | `<div class="box">` | `.box` or `%div.box` |
| **Attributes** | `<div id="main" class="box">` | `%div#main.box` or `%div{ id: "main", class: "box" }` |
| **Readability** | More verbose | More concise |
| **Learning Curve** | Easier (familiar HTML) | Steeper (new syntax) |
| **Whitespace** | Not significant | Significant (indentation) |

---

## Render Options Explored

### 1. Render Partial with Locals
```erb
<%= render partial: "comments/comment", locals: { comment: @comment } %>
```

### 2. Render Collection
```erb
<%= render partial: "comments/comment", collection: @comments %>
```

### 3. Render with Custom Variable Name
```erb
<%= render partial: "comments/comment", collection: @comments, as: :item %>
```

### 4. Render Shorthand
```erb
<!-- Automatically looks for _blog.html.erb partial -->
<%= render @blog %>

<!-- For collections -->
<%= render @blogs %>
```

### 5. Render with Layout
```erb
<%= render partial: "comment", layout: "comment_wrapper", locals: { comment: @comment } %>
```

---

## Best Practices

### ERB
- ✅ Use `<%= %>` for output, `<% %>` for logic
- ✅ Keep logic minimal in views
- ✅ Extract complex logic to helpers or presenters
- ✅ Use partials for reusable components

### HAML
- ✅ Maintain consistent indentation (2 spaces)
- ✅ Use `.class` and `#id` shortcuts
- ✅ Leverage HAML's conciseness for cleaner code
- ✅ Be careful with whitespace sensitivity

### General
- ✅ Prefer `form_with` over older `form_for` and `form_tag`
- ✅ Use locals to make partials reusable
- ✅ Keep views focused on presentation
- ✅ Use helpers for complex view logic

---

## Project Examples

### Comment Form (ERB)
File: `app/views/comments/_form.html.erb`

### Comment Form (HAML)
File: `app/views/comments/_form.html.haml`

### Blog Card Partial (ERB)
File: `app/views/blogs/_blog_card.html.erb`

### Blog Card Partial (HAML)
File: `app/views/blogs/_blog_card.html.haml`

Both versions produce identical HTML output but use different syntaxes.

---

## Conclusion

- **ERB** is the Rails default and familiar to those who know HTML
- **HAML** offers cleaner, more maintainable code but requires learning new syntax
- **Partials with locals** promote DRY (Don't Repeat Yourself) principles
- **Form helpers** simplify form creation and handle security automatically
- Choose the templating engine that best fits your team's preferences and project needs
