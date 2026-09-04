class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: [:edit, :update, :destroy, :move_up, :move_down]

  def index
    @categories = Category.all
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      log_admin_action!("create_category", @category)
      redirect_to admin_categories_path, notice: "Category created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      log_admin_action!("update_category", @category, details: { changes: category_params.to_h })
      redirect_to admin_categories_path, notice: "Category updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroyable?
      name = @category.name_en
      @category.destroy
      log_admin_action!("delete_category", nil, details: { name: name })
      redirect_to admin_categories_path, notice: "Category deleted."
    else
      redirect_to admin_categories_path, alert: "Category is in use by existing tasks and cannot be deleted. Mark it inactive instead."
    end
  end

  def move_up
    swap_with(Category.where("position < ?", @category.position).order(position: :desc).first)
  end

  def move_down
    swap_with(Category.where("position > ?", @category.position).order(position: :asc).first)
  end

  private

  def swap_with(other)
    return redirect_to(admin_categories_path) unless other

    ActiveRecord::Base.transaction do
      current_position = @category.position
      @category.update!(position: other.position)
      other.update!(position: current_position)
    end
    log_admin_action!("reorder_category", @category, details: { new_position: @category.position })
    redirect_to admin_categories_path, notice: "Category order updated."
  end

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name_en, :name_ne, :active)
  end
end
