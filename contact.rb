require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "yaml"

configure do        # lets the project use sessions
  enable :sessions
  set :session_secret, 'super secret'
end

def contacts_list
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/contacts.yaml", __FILE__)
  else
    File.expand_path("../contacts.yaml", __FILE__)
  end
end

def load_contacts_list
  YAML.load_file(contacts_list) || {}
end

def write_contacts_list(list)
  File.open(contacts_list, 'w') {|file| file.write list.to_yaml}
end

def add_category
  list = load_contacts_list
  list[params[:new_category].downcase.gsub(/\s+/, "+")] = {}
  write_contacts_list(list)
end

def delete_category
  list = load_contacts_list
  list.delete(params[:category])
  write_contacts_list(list)
end

def write_contact
  list = load_contacts_list
  list[params[:category]] ||= {}
  list[params[:category]][params[:name].downcase.gsub(/\s+/, "+")] = {
    name: params[:name],
    email: params[:email],
    phone: params[:phone]
  }

  write_contacts_list(list)
end

def delete_contact(contact)
  list = load_contacts_list
  list[params[:category]].delete(contact)
  write_contacts_list(list)
end

# Index
get "/" do
  @list = load_contacts_list
  erb :index
end

# Add a category
post "/add_category" do
  if params[:new_category].strip.empty?
    session[:error] = "Category Must Have a Valid Name"
  else
    add_category
    session[:success] = "You have added the '#{params[:new_category].upcase}' category."
  end
  redirect "/"
end

# Show all contacts
get "/contacts/all" do
  @list = load_contacts_list
  erb :all_contacts
end

get "/contacts" do
  redirect "/contacts/all"
end

# Show contacts for a specific category
get "/contacts/:category" do
  @category = params[:category].capitalize.gsub("+", " ")
  @list = load_contacts_list
  @sub_list = @list[params[:category]]
  erb :contacts
end

# Delete a category
post "/contacts/:category/delete" do
  @category = params[:category].upcase.gsub("+", " ")
  session[:success] = "You have deleted the '#{@category}' category."
  delete_category
  redirect "/"
end

# Form for adding a contact to a category
get "/contacts/:category/add" do
  @category = params[:category].capitalize.gsub("+", " ")
  erb :add
end

# Writes a contact to a category
post "/contacts/:category/add" do
  write_contact
  session[:success] = "You have added #{params[:name]}."
  redirect "/contacts/#{params[:category]}"
end

# Shows details for a contact
get "/contacts/:category/:contact" do
  list = load_contacts_list
  @contact_info = list[params[:category]][params[:contact]]
  @category = params[:category].capitalize.gsub("+", " ")
  erb :contact
end

# Form for editing a contact
get "/contacts/:category/:contact/edit" do
  @category = params[:category].capitalize.gsub("+", " ")
  list = load_contacts_list
  @contact_info = list[params[:category]][params[:contact]]

  erb :edit
end

# Edits a contact
post "/contacts/:category/:contact/edit" do
  delete_contact(params[:contact])
  write_contact

  session[:success] = "You have edited #{params[:name]}."
  name = params[:name].downcase.gsub(/\s+/, "+")
  redirect "/contacts/#{params[:category]}/#{name}"
end

# Deletes a contact
post "/contacts/:category/:contact/delete" do
  list = load_contacts_list
  name = list[params[:category]][params[:contact]][:name]
  session[:success] = "You have deleted #{name}."
  delete_contact(params[:contact])

  redirect "/contacts/#{params[:category]}"
end
