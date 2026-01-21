class BlogsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :published, :unpublished]
  load_and_authorize_resource
  skip_authorize_resource only: [:index, :published, :unpublished] # We'll handle collection authorization manually if needed or rely on index logic
  before_action :set_blog, only: %i[ show edit update destroy publish ]

  # GET /blogs or /blogs.json
  def index
    benchmark_result = Benchmark.measure do
      # IMPROVEMENT: Use eager loading for user associations to prevent N+1 queries
      @blogs = Blog.includes(:user, comments: :user).all
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

  # GET /blogs/published
  def published
    @blogs = Blog.published
    render :index
  end

  # GET /blogs/unpublished
  def unpublished
    @blogs = Blog.unpublished
    render :index
  end

  # GET /blogs/1 or /blogs/1.json
  def show
    respond_to do |format|
      format.html
      format.json { render json: BlogBlueprint.render(@blog, view: :with_comments) }
    end
  end

  # GET /blogs/new
  def new
    @blog = Blog.new
  end

  # GET /blogs/1/edit
  def edit
  end

  # POST /blogs or /blogs.json
  def create
    @blog = Blog.new(blog_params)
    @blog.user = current_user

    respond_to do |format|
      if @blog.save
        # Schedule auto-publish job for unpublished blogs (1 hour delay)
        if !@blog.published?
          PublishBlogJob.set(wait: 1.hour).perform_later(@blog.id)
          Rails.logger.info "Scheduled auto-publish for blog ##{@blog.id} in 1 hour"
        end
        
        format.html { redirect_to @blog, notice: "Blog was successfully created." }
        format.json { render json: BlogBlueprint.render(@blog), status: :created, location: @blog }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /blogs/1 or /blogs/1.json
  def update
    respond_to do |format|
      if @blog.update(blog_params)
        format.html { redirect_to @blog, notice: "Blog was successfully updated.", status: :see_other }
        format.json { render json: BlogBlueprint.render(@blog), status: :ok, location: @blog }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /blogs/1/publish
  def publish
    begin
      BlogPublishingService.toggle_publish(@blog)
      status_text = @blog.published? ? "published" : "unpublished"
      
      respond_to do |format|
        format.html { redirect_to @blog, notice: "Blog was successfully #{status_text}.", status: :see_other }
        format.json { render json: BlogBlueprint.render(@blog), status: :ok, location: @blog }
      end
    rescue BlogPublishingService::PublishError => e
      respond_to do |format|
        format.html { redirect_to @blog, alert: e.message, status: :see_other }
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /blogs/1 or /blogs/1.json
  def destroy
    @blog.destroy!

    respond_to do |format|
      format.html { redirect_to blogs_path, notice: "Blog was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_blog
      @blog = Blog.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def blog_params
      params.require(:blog).permit(:title, :body)
    end
end
