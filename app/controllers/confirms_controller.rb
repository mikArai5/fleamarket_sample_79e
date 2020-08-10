class ConfirmsController < ApplicationController
  require 'payjp'

  def index
    @user = current_user
    @address = DeliveryAddress.find_by(user_id: current_user.id)
    @item = Item.find_by(params[:id])
    @card = Card.find_by(user_id: current_user.id)

    if @card.blank?
      #登録された情報がない場合にカード登録画面に移動
      redirect_to new_card_path
    else
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      #保管した顧客IDでpayjpから情報取得
      customer = Payjp::Customer.retrieve(@card.customer_id)
      #保管したカードIDでpayjpから情報取得、カード情報表示のためインスタンス変数に代入
      @default_card_information = customer.cards.retrieve(@card.payjp_id)
    end
  end

  def pay
    @item = Item.find(params[:id])
    @card = Card.find_by(user_id: current_user.id)
    Payjp.api_key = ENV['PAYJP_PRIVATE_KEY']
    Payjp::Charge.create(
      amount: @item.price,
      customer: card.customer_id, #顧客ID
      currency: 'jpy', #日本円
    )
    @item_buyer = Item.find_by(params[:id])
    @item_buyer.update(buyer_id: current_user.id)
    redirect_to done_confirms_path
  end

  def done
  end
  
end