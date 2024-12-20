class UserController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:login, :register, :out_login]

  def login
    user = User.find_by(username: params[:username])
    puts "User found: #{user.inspect}" if user

    if user && user.authenticate(params[:password])
      puts "Password matched"
      token = generate_token(user.id)
      render json: { status: 'ok', message: '登录成功', data: { userId: user.id, username: user.username, token: token } }, status: :ok
    else
      puts "Password did not match"
      render json: { status: 'error', message: '用户名或密码错误' }, status: :unauthorized
    end
  end

  def register
    # 获取前端传来的参数
    username = params[:username]
    password = params[:password]
    confirm_password = params[:confirmPassword]
    auto_login = params[:autoLogin]
    type = params[:type]
    user = User.find_by(username: params[:username])

    if user
      # 如果用户名已存在，返回422错误
      Rails.logger.error("Username already exists: #{username}") #to_delete
      render json: { error: 'Username already exists' }, status: :unprocessable_entity
      return
    end
    # 验证密码是否一致
    if password != confirm_password
      Rails.logger.error("Passwords do not match: #{password} != #{confirm_password}") #to_delete
      render json: { error: "Passwords do not match" }, status: :unprocessable_entity
      return
    end

    # 创建新用户
    user = User.new(username: username, password: password, password_confirmation: confirm_password)

    # 保存用户到数据库
    if user.save
      # 如果 auto_login 为 true，可以在这里处理自动登录逻辑
      if auto_login
        # 这里可以生成一个 session 或者 token 来实现自动登录
        # session[:user_id] = user.id
      end

      render json: { message: "User registered successfully", user: user }, status: :created
    else
      error_messages = user.errors.full_messages.join(', ')
      Rails.logger.error("User registration failed: #{error_messages}") #to_delete
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def out_login
    # 你可以在这里添加任何你需要在退出登录时执行的逻辑
    # 例如，清除用户的会话或令牌
    render json: { status: 'ok', message: '退出登录成功' }, status: :ok
  end

  # 获取当前用户接口
  def current_user
    token = request.headers['Authorization']&.split(' ')&.last
    if token
      begin
        decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')
        user_id = decoded_token.first['user_id']
        user = User.find_by(id: user_id)

        if user
          # 构建用户详细信息
          user_data = {
            name: user.username,
            access: "guest",
            userid: user.id.to_s
          }

          render json: { success: true, data: user_data }, status: :ok
        else
          render json: { success: false, message: '用户不存在' }, status: :not_found
        end
      rescue JWT::DecodeError
        render json: { success: false, message: '无效的令牌' }, status: :unauthorized
      end
    else
      render json: { success: false, message: '缺少令牌' }, status: :unauthorized
    end
  end

  private

  def generate_token(user_id)
    payload = { user_id: user_id }
    JWT.encode(payload, Rails.application.secret_key_base)
  end
end