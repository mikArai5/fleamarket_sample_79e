class ItemsController < ApplicationController
  before_action :move_to_index_edit, only: [:edit]
  before_action :authenticate_user!, only: :new
  before_action :move_to_index_destroy, only: [:destroy]

  def index
    @images = ItemImage.all
    @items = Item.limit(5)
  end
  
  def show
    @item = Item.find(params[:id])
    @user = User.find(@item.seller_id)
    @category_id = @item.category_id
    @category_parent = Category.find(@category_id).parent.parent
    @category_child = Category.find(@category_id).parent
    @category_grandchild = Category.find(@category_id)
  end
  
  def new
    @item = Item.new
    @item.item_images.new
    # データベースから、親カテゴリーのみ抽出し、配列化
    @category_parent_array = Category.where(ancestry: nil)
  end

  def create
    @category_parent_array = Category.where(ancestry: nil)
    @item = Item.new(item_params)
    if @item.save
      redirect_to root_path
    else
      flash[:alert] = '必須項目を入力してください'
      redirect_to action: 'new'
    end
  end

  def edit
    @item = Item.includes(:item_images).order('created_at DESC').find(params[:id])
    
    grandchild_category = @item.category
    child_category = grandchild_category.parent


    @category_parent_array = []
    Category.where(ancestry: nil).each do |parent|
      @category_parent_array << parent
    end

    @category_children_array = []
    Category.where(ancestry: child_category.ancestry).each do |children|
      @category_children_array << children
    end

    @category_grandchildren_array = []
    Category.where(ancestry: grandchild_category.ancestry).each do |grandchildren|
      @category_grandchildren_array << grandchildren
    end
  end

  def update
    
    @item = Item.find(params[:id])
    if @item.seller_id == current_user.id
      if @item.update(item_params)
        redirect_to item_path(@item.id)
      else
        flash[:alert] = '必須項目を記載してください'
        redirect_to action: 'edit'
      end
    else
      flash[:alert] = '編集に失敗しました'
      redirect_to action: 'edit'
    end
    
  end

  def destroy
    if @item.destroy
      redirect_to root_path, notice: '削除しました'
    else
      render :edit
    end
  end

  # 親カテゴリーが選択された後に動くアクション
  def get_category_children
    # 選択された親カテゴリーに紐付く子カテゴリーの配列を取得
    @category_children = Category.find(params[:parent_id]).children
  end

  # 子カテゴリーが選択された後に動くアクション
  def get_category_grandchildren
    # 選択された子カテゴリーに紐付く孫カテゴリーの配列を取得
    @category_grandchildren = Category.find(params[:child_id]).children
  end

  private

  def item_params
    params.require(:item).permit(:name, :explanation, :brand, :category_id, :condition_id, :postage_id, :prefecture_id, :prepare_id, :price, item_images_attributes: [:image, :_destroy, :id]).merge(seller_id: current_user.id)
  end

  def move_to_index_edit
    @item = Item.find(params[:id])
    if current_user.id != @item.seller_id
      flash[:alert] = '編集する権限を持っていません'
      redirect_to root_path 
    end
  end

  def move_to_index_destroy
    @item = Item.find(params[:id])
    redirect_to root_path unless current_user.id == @item.seller_id
  end
end
