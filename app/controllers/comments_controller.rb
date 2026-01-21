class CommentsController < ApplicationController
  before_action :set_blog

  def index
    @comments = @blog.comments
  end

  def create
    @comment = @blog.comments.build(comment_params)

    if @comment.save
      redirect_to @blog, notice: "Comment added"
    else
      redirect_to @blog, alert: @comment.errors.full_messages.join(", ")
    end
  end

  def destroy
    @comment = @blog.comments.find(params[:id])
    @comment.destroy
    redirect_to @blog, notice: "Comment deleted"
  end

  private

  def set_blog
    @blog = Blog.find(params[:blog_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
