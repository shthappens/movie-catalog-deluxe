require "sinatra"
require "pg"
require "pry"

set :bind, '0.0.0.0'  # bind to all interfaces

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

def actors_list
  @actors = db_connection { |conn| conn.exec(
    "SELECT actors.id, actors.name
    FROM actors
    ORDER BY name ASC"
    ) }.to_a
end

def actors_info
  @actor_id = params[:id]
  @actor_info = db_connection { |conn| conn.exec(
   "SELECT movies.title, actors.name, movies.id, movies.year, cast_members.character AS role
   FROM cast_members
   JOIN movies ON cast_members.movie_id=movies.id
   JOIN actors ON cast_members.actor_id=actors.id
   WHERE actors.id='#{@actor_id}'"
   ) }.to_a
 end

def movies_list
  @movies = db_connection { |conn| conn.exec(
    "SELECT movies.id, movies.title, movies.rating, movies.year, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres ON movies.genre_id=genres.id
    LEFT JOIN studios ON movies.studio_id=studios.id
    ORDER BY title ASC"
    ) }.to_a
end

def movies_info
  @movie_id = params[:id]
  @movie_info = db_connection { |conn| conn.exec(
    "SELECT movies.id, movies.title, movies.year, movies.rating,
    genres.name AS genre, studios.name AS studio, actors.name, actors.id,
    cast_members.character AS role
    FROM cast_members
    JOIN movies ON cast_members.movie_id=movies.id
    JOIN actors ON cast_members.actor_id=actors.id
    JOIN genres ON movies.genre_id=genres.id
    JOIN studios ON movies.studio_id=studios.id
    WHERE movies.id='#{@movie_id}'"
    ) }.to_a
end

get "/" do
  redirect "/movies"
end

get "/actors" do
  actors_list
  erb :"actors/index"
end

get "/actors/:id" do
  actors_info
  erb :"actors/show"
end

get "/movies" do
  movies_list
  erb :"movies/index"
end

get "/movies/:id" do
  movies_info
  erb :"movies/show"
end
