require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'pp'
require 'BCrypt'

enable :sessions

#global variables
db = SQLite3::Database.new("db/chinook.db")
db.results_as_hash = true

get('/')  do
    slim(:index)
  end 

get('/mypage') do

    slim(:mypage)  
end

get('/logout') do
    session.destroy
    redirect('/')
end

post('/register') do
    username = params[:username]
    password = params[:password]
    passwordConfirm = params[:passwordConfirm]
    if password != passwordConfirm
      "passorden matchade inte"
      redirect('/users/new')
    else
        passwordDigest = BCrypt::Password.create(password)
        db.execute('INSERT INTO users (username,password) VALUES (?,?)',username,passwordDigest)
        redirect('/')
    end
  end

get('/users/new') do
    slim(:'users/new')
end

post('/login_form') do
    username = params[:username]
    password = params[:password]
    result = db.execute('SELECT * FROM users WHERE username = ?',username).first
    pwdigest = result['password']
    id = result['id']
    if BCrypt::Password.new(pwdigest) != password
      "fel passord"
    end
    adminResult = db.execute('SELECT * FROM admins WHERE userId = ?',id).first
    if adminResult
        session[:admin] = id
    end
    session[:id] = id
    redirect('/')
  end  

get('/login') do
    slim(:'login')
end

get('/users') do
    result = db.execute("SELECT * FROM users")
    session[:allUsers] = result
    slim(:"/users/index")
end

post('/users/delete/:id') do
    id = params[:id]
    db.execute("DELETE FROM users WHERE id = ?",id)
    redirect('/users')
end

get('/users/:id') do
    id = params[:id].to_i
end

get('/travels') do
    result = db.execute("SELECT * FROM travels")
    session[:travels] = result
    slim(:"/travels/index")
end

post('/travels/new') do
    session[:from] = params[:from]
    session[:to] = params[:to]
    session[:time] = params[:time]
    #result = db.execute("INSERT INTO travels (creator_id, from_id, to_id, time) VALUES (#{session[:from]}, #{session[:to]},#{session[:time]}")

    redirect('travels/index')
end
