require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'pg' 

enable :sessions

client = PG::connect(
    :host => "localhost",
    :user => ENV.fetch("USER", "akarimaeda"), :password => '',
    :dbname => "bookmemory"
)

get '/signin' do
    return erb :signin
end

post '/signin' do
    email = params[:email]
    password = params[:password]
    
    user = client.exec_params("SELECT * FROM users WHERE email = '#{email}' AND password = '#{password}'").to_a.first
    
    if user.nil?
        return erb :signin
        else
        session[:user] = user
        return redirect '/posts'
    end
end

get '/posts' do
    if session[:user].nil?
        redirect '/signin'
    end
    @posts = client.exec_params("SELECT * FROM posts")
    return erb :posts
end

post '/posts' do
    title = params[:title]
    content = params[:content]
    
    img = params[:img]
    
    if !params[:img].nil? # データがあれば処理を続行する
        tempfile = params[:img][:tempfile] # ファイルがアップロードされた場所
        save_to = "./public/images/#{params[:img][:filename]}" # ファイルを保存したい場所
        FileUtils.mv(tempfile, save_to)
        img = params[:img][:filename]
    end
    
    client.exec_params(
        "INSERT INTO posts(title, content, image_path) VALUES($1, $2, $3)",
        [title, content, img]
    )
    redirect '/posts'
end

delete '/signout' do
    session[:user] = nil
    return redirect '/signin'
end 
