# frozen_string_literal: true

class BlogsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]
  before_action :set_blog, only: %i[edit update destroy]

  def index
    @blogs = Blog.search(params[:term]).published.default_order
  end

  def show
    # @blog = Blog.find(params[:id])
    user_requested_id = params[:id]

    blogs = if user_signed_in?
              (Blog.keep_secret.find_by(id: user_requested_id, user_id: current_user.id) || Blog.published.find_by(id: user_requested_id))
            else
              Blog.published.find_by(id: user_requested_id)
            end

    raise ActiveRecord::RecordNotFound, 'Blog not found' if blogs.nil?

    @blog = blogs
  end

  def new
    @blog = Blog.new
  end

  def edit; end

  def create
    @blog = current_user.blogs.new(blog_params)

    if @blog.save
      redirect_to blog_url(@blog), notice: 'Blog was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if current_user.premium? || blog_params[:random_eyecatch] == '0'
      if @blog.update(blog_params)
        redirect_to blog_url(@blog), notice: 'Blog was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    else
      flash[:alert] = 'Random eyecatch can only be enabled by premium users.'
      redirect_to blog_url(@blog), status: :found
    end
  end

  def destroy
    @blog.destroy!

    redirect_to blogs_url, notice: 'Blog was successfully destroyed.', status: :see_other
  end

  private

  def set_blog
    @blog = current_user.blogs.find(params[:id])
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :secret, :random_eyecatch)
  end
end
