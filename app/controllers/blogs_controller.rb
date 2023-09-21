# frozen_string_literal: true

class BlogsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]
  before_action :set_blog, only: %i[edit update destroy]

  def index
    @blogs = Blog.search(params[:term]).published.default_order
  end

  def show
    user_requested_id = params[:id]

    blog = if user_signed_in?
             Blog.where(id: user_requested_id)
                 .where('(secret = ? AND user_id = ?) OR secret = ?', true, current_user.id, false)
                 .take!
           else
             Blog.published.find(user_requested_id)
           end

    @blog = blog
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
    random_eyecatch_value = current_user.premium? ? blog_params[:random_eyecatch] : false

    if @blog.update(blog_params.merge(random_eyecatch: random_eyecatch_value))
      redirect_to blog_url(@blog), notice: 'Blog was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
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
