class MessagesController < ApplicationController
  # before_action :authenticate_user!  # 如果你有身份验证需求
  # 更新消息的 is_collected 字段
  def collect_message
    # 根据 params[:ansid] 获取对应的消息
    message = Message.find_by(id: params[:answerId])

    if message
      # 根据传入的 is_collected 状态来更新收藏状态
      new_status = params[:is_collected] === 1 ? true : false  # '1' 转换为 false, '0' 转换为 true
      # new_status = params[:is_collected]
      puts "传入的当前状态是#{params[:is_collected]}, 变更为: #{new_status}"
      if message.update(is_collected: new_status)
        render json: { message: "消息已#{new_status ? '收藏' : '取消收藏'}" }, status: :ok
        puts "消息已#{new_status ? '收藏' : '取消收藏'}"
      else
        render json: { error: '更新失败' }, status: :unprocessable_entity
      end
    else
      render json: { error: '消息未找到' }, status: :not_found
    end
  end


  # 删除收藏状态
  def delete
    @message = Message.find(params[:answerId])
    puts "************************************************"
    puts @message
    if @message.update(is_collected: 0)  # 假设 0 表示取消收藏
      puts "后端删除成功"
      render json: { success: true, message: '收藏已删除' }
    else
      puts "后端删除失败"
      render json: { success: false, message: '删除失败' }, status: :unprocessable_entity
    end
  end


  # 用户认证
  def authenticate_user!
    unless current_user
      render json: { error: '请先登录' }, status: :unauthorized
    end
  end
  # 解析 JWT 令牌
  def decoded_token
    token = request.headers['Authorization']&.split(' ')&.last
    JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256').first
  rescue JWT::DecodeError
    {}
  end


  def current_user
    decoded_token = decode_token(request.headers['Authorization'])
    Rails.logger.debug "Decoded Token: #{decoded_token['user_id']}"
    puts "验证后的用户id:" +decoded_token['user_id']
    @current_user ||= User.find_by(id: decoded_token['user_id'])
  end
end
