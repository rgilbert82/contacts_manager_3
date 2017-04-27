ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require "fileutils"

require_relative "../contact"

class ContactTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    File.truncate(contacts_list, 0)
  end

  def teardown
    File.truncate(contacts_list, 0)
  end

  def session
    last_request.env["rack.session"]
  end

  def test_add_category
    post "/add_category", { new_category: "New Category" }

    assert_equal 302, last_response.status
    assert_equal "You have added the 'NEW CATEGORY' category.", session[:success]

    get "/contacts/new+category"

    assert_equal 200, last_response.status
  end

  def test_add_invalid_category
    post "/add_category", { new_category: "  " }

    assert_equal 302, last_response.status
    assert_equal "Category Must Have a Valid Name", session[:error]
  end

  def test_delete_category
    post "/add_category", { new_category: "New Category" }

    post "/contacts/new+category/delete"

    assert_equal 302, last_response.status
    assert_equal "You have deleted the 'NEW CATEGORY' category.", session[:success]
  end

  def test_add_contact_to_category
    post "/add_category", { new_category: "New Category" }

    post "/contacts/new+category/add", { name: "Joe Smith", email: "joe@gmail.com", phone: "555-5555" }

    assert_equal 302, last_response.status
    assert_equal "You have added Joe Smith.", session[:success]
  end

  def test_delete_contact
    post "/add_category", { new_category: "New Category" }
    post "/contacts/new+category/add", { name: "Joe Smith", email: "joe@gmail.com", phone: "555-5555" }

    post "/contacts/new+category/joe+smith/delete"

    assert_equal 302, last_response.status
    assert_equal "You have deleted Joe Smith.", session[:success]
  end

  def test_edit_contact
    post "/add_category", { new_category: "New Category" }
    post "/contacts/new+category/add", { name: "Joe Smith", email: "joe@gmail.com", phone: "555-5555" }

    post "/contacts/new+category/joe+smith/edit", { name: "Bob Smith", email: "bob@gmail.com", phone: "555-5555" }

    assert_equal 302, last_response.status
    assert_equal "You have edited Bob Smith.", session[:success]
  end
end
