require_relative './racktest_helper'

class CmsTest < RackTestCase

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def test_rake_test_have_run
    puts "Rake tests running"
  end

  def test_home_page
    create_document "about.txt"
    create_document "changes.txt"
    create_document "history.txt"

    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes(last_response.body, "about.txt")
    assert_includes(last_response.body, "changes.txt")
    assert_includes(last_response.body, "history.txt")
  end

  def test_file_page_file_renders_as_plain_tekst
    create_document "about.txt", "Ruby was influenced by Perl"

    get "/about.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain;charset=utf-8", last_response["Content-Type"]
    assert_includes(last_response.body, "Ruby was influenced by Perl")
  end

  def test_file_page_gives_error_when_file_does_not_exist
    get "/nonexisting.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]  # follow redirect
    assert_equal 200, last_response.status
    assert_includes last_response.body, "nonexisting.txt does not exist"

    get "/"
    refute_includes(last_response.body, "nonexisting.txt does not exist")
  end

  def test_markdown_file_renders_as_html
    create_document "requirement6.md", "<em>Gemfile</em>"

    get "/requirement6.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<em>Gemfile</em>"
  end

  def test_edit_text
    create_document "test.txt"

    get "/test.txt/edit"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Edit content of test.txt"
    assert_includes last_response.body, "Documents can be edited now"
  end

  def test_update_text
    create_document "test.txt"

    post "/test.txt/edit", edit_box: "Did it!"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "test.txt has been updated"
    assert_equal 200, last_response.status

    get "/test.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Did it!"
  end

  def test_view_new_document_form
    get "/files/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type='submit')
  end

  def test_create_new_document
    post "/files", document_name: "test.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "test.txt was created"

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_create_new_document_without_filename
    post "/files", document_name: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_valid_document_name
    name = 'test.txt'
    assert_equal(true, valid_doc_name?(name))
  end

  def test_invalid_document_name
    name = ''
    assert_equal(false, valid_doc_name?(name))
    name = '   '
    assert_equal(false, valid_doc_name?(name))
  end

  def test_delete_document
    create_document 'test.txt'

    post '/test.txt/delete', document_name: "test.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "test.txt was deleted"

    get "/"
    refute_includes last_response.body, "test.txt"
  end

  def test_sign_in_form_exists
    get '/sign_in'

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Username"
    assert_includes last_response.body, %q(type='submit')
  end

  def test_user_can_sign_in
    post '/sign_in', username: 'admin', password: 'secret'
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, 'Welcome!'
    assert_includes last_response.body, 'Signed in as admin.'

    get "/"
    refute_includes last_response.body, "Welcome!"
  end

  def test_invalid_user_sign_in_fails
    post '/sign_in', username: '', password: ''
    assert_equal 422, last_response.status

    assert_includes last_response.body, 'Invalid Credentials'

    get "/sign_in"
    refute_includes last_response.body, "Invalid Credentials"
  end

  def test_user_can_sign_out
    post '/sign_in', username: 'admin', password: 'secret'
    post '/sign_out'
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, 'You have been signed out.'

    get "/"
    refute_includes last_response.body, "You have been signed out."
    assert_includes last_response.body, "Sign In"
  end
end
