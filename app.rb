require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'pp'
require 'BCrypt'
require_relative './model.rb'

enable :sessions

#global variables
db = SQLite3::Database.new("db/chinook.db")
db.results_as_hash = true

before do
    if (session[:id] == nil) && (request.path_info != '/' && request.path_info != '/login' && request.path_info != '/login_form' && request.path_info != '/register' && request.path_info != '/users/new')
        session[:error] = "Log in to access this page."
        redirect('/error')
    end
end

get('/error') do
    slim(:error)
end

get('/')  do
    slim(:index)
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
    session[:friends] = db.execute("SELECT users.id, users.username FROM users INNER JOIN friends ON users.id = friends.friend2 WHERE friend1 = ?",id)
    session[:userTravels] = db.execute("SELECT * FROM travels WHERE creator_id = ?",id)
    session[:placeNames] = db.execute("SELECT place FROM places")
    session[:currentUser] = id
    slim(:"/users/user")
end

post('/change_username/:id') do
    id = params[:id]
    username = params[:newUsername]
    db.execute("UPDATE users SET username = ? WHERE id = ?",username,id)
    redirect('/users/#{session[:id]}')
end

post('/change_password/:id') do
    id = params[:id]
    password = params[:newPassword]
    db.execute("UPDATE users SET password = ? WHERE id = ?",password,id)
    redirect('/users/#{session[:id]}')
end

post('/add_friend/:id') do
    id = params[:id].to_i
    friend = params[:friend]
    friendId = db.execute("SELECT id FROM users WHERE username = ?",friend).first
    db.execute("INSERT INTO friends (friend1,friend2) VALUES (?,?)",id,friendId['id'])
    redirect('/users/#{session[:id]}')
end

get('/users/friends/:id') do
    id = params[:id].to_i
    session[:friendsTravels] = db.execute("SELECT travels.* FROM (users INNER JOIN friends ON users.id = friends.friend2) INNER JOIN travels ON users.id = travels.creator_id WHERE friends.friend1 = ?",id)
    slim(:"users/friends")
end

get('/places') do
    result = getNamesOfPlaces()
    session[:places] = result
    slim(:"/places/index")
end

post('/places/new') do
    newPlace = params[:newPlace]
    db.execute("INSERT INTO places (place) VALUES (?)",newPlace)
    redirect('/places')
end

get('/travels') do
    result = db.execute("SELECT * FROM travels")
    session[:travels] = result
    slim(:"/travels/index")
end

post('/travels/new/:id') do
    id = params[:id]
    from = params[:from]
    to = params[:to]
    time= params[:time]
    db.execute("INSERT INTO travels (creator_id, from_id, to_id, time) VALUES (?,?,?,?)",id,from,to,time)

    redirect('/travels')
end
