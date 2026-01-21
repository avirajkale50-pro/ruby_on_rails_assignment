class CommentsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource
  before_action :set_blog

  def index
    @comments = @blog.comments
    
    respond_to do |format|
      format.html
      format.json { render json: CommentBlueprint.render(@comments) }
    end
  end

  def create
    @comment = @blog.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        format.html { redirect_to @blog, notice: "Comment added" }
        format.json { render json: CommentBlueprint.render(@comment), status: :created }
      else
        format.html { redirect_to @blog, alert: @comment.errors.full_messages.join(", ") }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
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
