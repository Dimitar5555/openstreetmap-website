require "test_helper"

module Api
  class NotesControllerTest < ActionDispatch::IntegrationTest
    def setup
      super
      # Stub nominatim response for note locations
      stub_request(:get, %r{^https://nominatim\.openstreetmap\.org/reverse\?})
        .to_return(:status => 404)
    end

    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/notes", :method => :post },
        { :controller => "api/notes", :action => "create" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/1", :method => :get },
        { :controller => "api/notes", :action => "show", :id => "1" }
      )
      assert_recognizes(
        { :controller => "api/notes", :action => "show", :id => "1", :format => "xml" },
        { :path => "/api/0.6/notes/1.xml", :method => :get }
      )
      assert_routing(
        { :path => "/api/0.6/notes/1.rss", :method => :get },
        { :controller => "api/notes", :action => "show", :id => "1", :format => "rss" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/1.json", :method => :get },
        { :controller => "api/notes", :action => "show", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/1.gpx", :method => :get },
        { :controller => "api/notes", :action => "show", :id => "1", :format => "gpx" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/1/comment", :method => :post },
        { :controller => "api/notes", :action => "comment", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/1/close", :method => :post },
        { :controller => "api/notes", :action => "close", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/1/reopen", :method => :post },
        { :controller => "api/notes", :action => "reopen", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/1", :method => :delete },
        { :controller => "api/notes", :action => "destroy", :id => "1" }
      )

      assert_routing(
        { :path => "/api/0.6/notes", :method => :get },
        { :controller => "api/notes", :action => "index" }
      )
      assert_recognizes(
        { :controller => "api/notes", :action => "index", :format => "xml" },
        { :path => "/api/0.6/notes.xml", :method => :get }
      )
      assert_routing(
        { :path => "/api/0.6/notes.rss", :method => :get },
        { :controller => "api/notes", :action => "index", :format => "rss" }
      )
      assert_routing(
        { :path => "/api/0.6/notes.json", :method => :get },
        { :controller => "api/notes", :action => "index", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/notes.gpx", :method => :get },
        { :controller => "api/notes", :action => "index", :format => "gpx" }
      )

      assert_routing(
        { :path => "/api/0.6/notes/search", :method => :get },
        { :controller => "api/notes", :action => "search" }
      )
      assert_recognizes(
        { :controller => "api/notes", :action => "search", :format => "xml" },
        { :path => "/api/0.6/notes/search.xml", :method => :get }
      )
      assert_routing(
        { :path => "/api/0.6/notes/search.rss", :method => :get },
        { :controller => "api/notes", :action => "search", :format => "rss" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/search.json", :method => :get },
        { :controller => "api/notes", :action => "search", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/notes/search.gpx", :method => :get },
        { :controller => "api/notes", :action => "search", :format => "gpx" }
      )

      assert_routing(
        { :path => "/api/0.6/notes/feed", :method => :get },
        { :controller => "api/notes", :action => "feed", :format => "rss" }
      )

      assert_recognizes(
        { :controller => "api/notes", :action => "create" },
        { :path => "/api/0.6/notes/addPOIexec", :method => :post }
      )
      assert_recognizes(
        { :controller => "api/notes", :action => "close" },
        { :path => "/api/0.6/notes/closePOIexec", :method => :post }
      )
      assert_recognizes(
        { :controller => "api/notes", :action => "comment" },
        { :path => "/api/0.6/notes/editPOIexec", :method => :post }
      )
      assert_recognizes(
        { :controller => "api/notes", :action => "index", :format => "gpx" },
        { :path => "/api/0.6/notes/getGPX", :method => :get }
      )
      assert_recognizes(
        { :controller => "api/notes", :action => "feed", :format => "rss" },
        { :path => "/api/0.6/notes/getRSSfeed", :method => :get }
      )
    end

    def test_create_success
      assert_difference "Note.count", 1 do
        assert_difference "NoteComment.count", 1 do
          post notes_path(:lat => -1.0, :lon => -1.0, :text => "This is a comment", :format => "json")
        end
      end
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal "Point", js["geometry"]["type"]
      assert_equal [-1.0, -1.0], js["geometry"]["coordinates"]
      assert_equal "open", js["properties"]["status"]
      assert_equal 1, js["properties"]["comments"].count
      assert_equal "opened", js["properties"]["comments"].last["action"]
      assert_equal "This is a comment", js["properties"]["comments"].last["text"]
      assert_nil js["properties"]["comments"].last["user"]
      id = js["properties"]["id"]

      get note_path(:id => id, :format => "json")
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal "Point", js["geometry"]["type"]
      assert_equal [-1.0, -1.0], js["geometry"]["coordinates"]
      assert_equal id, js["properties"]["id"]
      assert_equal "open", js["properties"]["status"]
      assert_equal 1, js["properties"]["comments"].count
      assert_equal "opened", js["properties"]["comments"].last["action"]
      assert_equal "This is a comment", js["properties"]["comments"].last["text"]
      assert_nil js["properties"]["comments"].last["user"]
    end

    def test_create_fail
      assert_no_difference "Note.count" do
        assert_no_difference "NoteComment.count" do
          post notes_path(:lon => -1.0, :text => "This is a comment")
        end
      end
      assert_response :bad_request

      assert_no_difference "Note.count" do
        assert_no_difference "NoteComment.count" do
          post notes_path(:lat => -1.0, :text => "This is a comment")
        end
      end
      assert_response :bad_request

      assert_no_difference "Note.count" do
        assert_no_difference "NoteComment.count" do
          post notes_path(:lat => -1.0, :lon => -1.0)
        end
      end
      assert_response :bad_request

      assert_no_difference "Note.count" do
        assert_no_difference "NoteComment.count" do
          post notes_path(:lat => -1.0, :lon => -1.0, :text => "")
        end
      end
      assert_response :bad_request

      assert_no_difference "Note.count" do
        assert_no_difference "NoteComment.count" do
          post notes_path(:lat => -100.0, :lon => -1.0, :text => "This is a comment")
        end
      end
      assert_response :bad_request

      assert_no_difference "Note.count" do
        assert_no_difference "NoteComment.count" do
          post notes_path(:lat => -1.0, :lon => -200.0, :text => "This is a comment")
        end
      end
      assert_response :bad_request

      assert_no_difference "Note.count" do
        assert_no_difference "NoteComment.count" do
          post notes_path(:lat => "abc", :lon => -1.0, :text => "This is a comment")
        end
      end
      assert_response :bad_request

      assert_no_difference "Note.count" do
        assert_no_difference "NoteComment.count" do
          post notes_path(:lat => -1.0, :lon => "abc", :text => "This is a comment")
        end
      end
      assert_response :bad_request

      assert_no_difference "Note.count" do
        assert_no_difference "NoteComment.count" do
          post notes_path(:lat => -1.0, :lon => -1.0, :text => "x\u0000y")
        end
      end
      assert_response :bad_request
    end

    def test_comment_success
      open_note_with_comment = create(:note_with_comments)
      user = create(:user)
      auth_header = basic_authorization_header user.email, "test"
      assert_difference "NoteComment.count", 1 do
        assert_no_difference "ActionMailer::Base.deliveries.size" do
          perform_enqueued_jobs do
            post comment_note_path(:id => open_note_with_comment, :text => "This is an additional comment", :format => "json"), :headers => auth_header
          end
        end
      end
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal open_note_with_comment.id, js["properties"]["id"]
      assert_equal "open", js["properties"]["status"]
      assert_equal 2, js["properties"]["comments"].count
      assert_equal "commented", js["properties"]["comments"].last["action"]
      assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
      assert_equal user.display_name, js["properties"]["comments"].last["user"]

      get note_path(:id => open_note_with_comment, :format => "json")
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal open_note_with_comment.id, js["properties"]["id"]
      assert_equal "open", js["properties"]["status"]
      assert_equal 2, js["properties"]["comments"].count
      assert_equal "commented", js["properties"]["comments"].last["action"]
      assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
      assert_equal user.display_name, js["properties"]["comments"].last["user"]

      # Ensure that emails are sent to users
      first_user = create(:user)
      second_user = create(:user)
      third_user = create(:user)

      note_with_comments_by_users = create(:note) do |note|
        create(:note_comment, :note => note, :author => first_user)
        create(:note_comment, :note => note, :author => second_user)
      end

      auth_header = basic_authorization_header third_user.email, "test"

      assert_difference "NoteComment.count", 1 do
        assert_difference "ActionMailer::Base.deliveries.size", 2 do
          perform_enqueued_jobs do
            post comment_note_path(:id => note_with_comments_by_users, :text => "This is an additional comment", :format => "json"), :headers => auth_header
          end
        end
      end
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal note_with_comments_by_users.id, js["properties"]["id"]
      assert_equal "open", js["properties"]["status"]
      assert_equal 3, js["properties"]["comments"].count
      assert_equal "commented", js["properties"]["comments"].last["action"]
      assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
      assert_equal third_user.display_name, js["properties"]["comments"].last["user"]

      email = ActionMailer::Base.deliveries.find { |e| e.to.first == first_user.email }
      assert_not_nil email
      assert_equal 1, email.to.length
      assert_equal "[OpenStreetMap] #{third_user.display_name} has commented on one of your notes", email.subject
      assert_equal first_user.email, email.to.first

      email = ActionMailer::Base.deliveries.find { |e| e.to.first == second_user.email }
      assert_not_nil email
      assert_equal 1, email.to.length
      assert_equal "[OpenStreetMap] #{third_user.display_name} has commented on a note you are interested in", email.subject

      get note_path(:id => note_with_comments_by_users, :format => "json")
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal note_with_comments_by_users.id, js["properties"]["id"]
      assert_equal "open", js["properties"]["status"]
      assert_equal 3, js["properties"]["comments"].count
      assert_equal "commented", js["properties"]["comments"].last["action"]
      assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
      assert_equal third_user.display_name, js["properties"]["comments"].last["user"]

      ActionMailer::Base.deliveries.clear
    end

    def test_comment_fail
      open_note_with_comment = create(:note_with_comments)

      user = create(:user)

      assert_no_difference "NoteComment.count" do
        post comment_note_path(:id => open_note_with_comment)
        assert_response :unauthorized
      end

      auth_header = basic_authorization_header user.email, "test"

      assert_no_difference "NoteComment.count" do
        post comment_note_path(:id => open_note_with_comment), :headers => auth_header
      end
      assert_response :bad_request

      assert_no_difference "NoteComment.count" do
        post comment_note_path(:id => open_note_with_comment, :text => ""), :headers => auth_header
      end
      assert_response :bad_request

      assert_no_difference "NoteComment.count" do
        post comment_note_path(:id => 12345, :text => "This is an additional comment"), :headers => auth_header
      end
      assert_response :not_found

      hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

      assert_no_difference "NoteComment.count" do
        post comment_note_path(:id => hidden_note_with_comment, :text => "This is an additional comment"), :headers => auth_header
      end
      assert_response :gone

      closed_note_with_comment = create(:note_with_comments, :status => "closed", :closed_at => Time.now.utc)

      assert_no_difference "NoteComment.count" do
        post comment_note_path(:id => closed_note_with_comment, :text => "This is an additional comment"), :headers => auth_header
      end
      assert_response :conflict

      assert_no_difference "NoteComment.count" do
        post comment_note_path(:id => open_note_with_comment, :text => "x\u0000y"), :headers => auth_header
      end
      assert_response :bad_request
    end

    def test_close_success
      open_note_with_comment = create(:note_with_comments)
      user = create(:user)

      post close_note_path(:id => open_note_with_comment, :text => "This is a close comment", :format => "json")
      assert_response :unauthorized

      auth_header = basic_authorization_header user.email, "test"

      post close_note_path(:id => open_note_with_comment, :text => "This is a close comment", :format => "json"), :headers => auth_header
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal open_note_with_comment.id, js["properties"]["id"]
      assert_equal "closed", js["properties"]["status"]
      assert_equal 2, js["properties"]["comments"].count
      assert_equal "closed", js["properties"]["comments"].last["action"]
      assert_equal "This is a close comment", js["properties"]["comments"].last["text"]
      assert_equal user.display_name, js["properties"]["comments"].last["user"]

      get note_path(:id => open_note_with_comment.id, :format => "json")
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal open_note_with_comment.id, js["properties"]["id"]
      assert_equal "closed", js["properties"]["status"]
      assert_equal 2, js["properties"]["comments"].count
      assert_equal "closed", js["properties"]["comments"].last["action"]
      assert_equal "This is a close comment", js["properties"]["comments"].last["text"]
      assert_equal user.display_name, js["properties"]["comments"].last["user"]
    end

    def test_close_fail
      post close_note_path(:id => 12345)
      assert_response :unauthorized

      auth_header = basic_authorization_header create(:user).email, "test"

      post close_note_path(:id => 12345), :headers => auth_header
      assert_response :not_found

      hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

      post close_note_path(:id => hidden_note_with_comment), :headers => auth_header
      assert_response :gone

      closed_note_with_comment = create(:note_with_comments, :status => "closed", :closed_at => Time.now.utc)

      post close_note_path(:id => closed_note_with_comment), :headers => auth_header
      assert_response :conflict
    end

    def test_reopen_success
      closed_note_with_comment = create(:note_with_comments, :status => "closed", :closed_at => Time.now.utc)
      user = create(:user)

      post reopen_note_path(:id => closed_note_with_comment, :text => "This is a reopen comment", :format => "json")
      assert_response :unauthorized

      auth_header = basic_authorization_header user.email, "test"

      post reopen_note_path(:id => closed_note_with_comment, :text => "This is a reopen comment", :format => "json"), :headers => auth_header
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal closed_note_with_comment.id, js["properties"]["id"]
      assert_equal "open", js["properties"]["status"]
      assert_equal 2, js["properties"]["comments"].count
      assert_equal "reopened", js["properties"]["comments"].last["action"]
      assert_equal "This is a reopen comment", js["properties"]["comments"].last["text"]
      assert_equal user.display_name, js["properties"]["comments"].last["user"]

      get note_path(:id => closed_note_with_comment, :format => "json")
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal closed_note_with_comment.id, js["properties"]["id"]
      assert_equal "open", js["properties"]["status"]
      assert_equal 2, js["properties"]["comments"].count
      assert_equal "reopened", js["properties"]["comments"].last["action"]
      assert_equal "This is a reopen comment", js["properties"]["comments"].last["text"]
      assert_equal user.display_name, js["properties"]["comments"].last["user"]
    end

    def test_reopen_fail
      hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

      post reopen_note_path(:id => hidden_note_with_comment)
      assert_response :unauthorized

      auth_header = basic_authorization_header create(:user).email, "test"

      post reopen_note_path(:id => 12345), :headers => auth_header
      assert_response :not_found

      post reopen_note_path(:id => hidden_note_with_comment), :headers => auth_header
      assert_response :gone

      open_note_with_comment = create(:note_with_comments)

      post reopen_note_path(:id => open_note_with_comment), :headers => auth_header
      assert_response :conflict
    end

    def test_show_success
      open_note = create(:note_with_comments)

      get note_path(:id => open_note, :format => "xml")
      assert_response :success
      assert_equal "application/xml", @response.media_type
      assert_select "osm", :count => 1 do
        assert_select "note[lat='#{open_note.lat}'][lon='#{open_note.lon}']", :count => 1 do
          assert_select "id", open_note.id.to_s
          assert_select "url", note_url(open_note, :format => "xml")
          assert_select "comment_url", comment_note_url(open_note, :format => "xml")
          assert_select "close_url", close_note_url(open_note, :format => "xml")
          assert_select "date_created", open_note.created_at.to_s
          assert_select "status", open_note.status
          assert_select "comments", :count => 1 do
            assert_select "comment", :count => 1
          end
        end
      end

      get note_path(:id => open_note, :format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 1 do
            assert_select "link", browse_note_url(open_note)
            assert_select "guid", note_url(open_note)
            assert_select "pubDate", open_note.created_at.to_fs(:rfc822)
            assert_select "geo|lat", open_note.lat.to_s
            assert_select "geo|long", open_note.lon.to_s
            assert_select "georss|point", "#{open_note.lon} #{open_note.lon}"
          end
        end
      end

      get note_path(:id => open_note, :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal "Point", js["geometry"]["type"]
      assert_equal open_note.lat, js["geometry"]["coordinates"][0]
      assert_equal open_note.lon, js["geometry"]["coordinates"][1]
      assert_equal open_note.id, js["properties"]["id"]
      assert_equal note_url(open_note, :format => "json"), js["properties"]["url"]
      assert_equal comment_note_url(open_note, :format => "json"), js["properties"]["comment_url"]
      assert_equal close_note_url(open_note, :format => "json"), js["properties"]["close_url"]
      assert_equal open_note.created_at.to_s, js["properties"]["date_created"]
      assert_equal open_note.status, js["properties"]["status"]

      get note_path(:id => open_note, :format => "gpx")
      assert_response :success
      assert_equal "application/gpx+xml", @response.media_type
      assert_select "gpx", :count => 1 do
        assert_select "wpt[lat='#{open_note.lat}'][lon='#{open_note.lon}']", :count => 1 do
          assert_select "time", :count => 1
          assert_select "name", "Note: #{open_note.id}"
          assert_select "desc", :count => 1
          assert_select "link[href='http://www.example.com/note/#{open_note.id}']", :count => 1
          assert_select "extensions", :count => 1 do
            assert_select "id", open_note.id.to_s
            assert_select "url", note_url(open_note, :format => "gpx")
            assert_select "comment_url", comment_note_url(open_note, :format => "gpx")
            assert_select "close_url", close_note_url(open_note, :format => "gpx")
          end
        end
      end
    end

    def test_show_hidden_comment
      note_with_hidden_comment = create(:note) do |note|
        create(:note_comment, :note => note, :body => "Valid comment for hidden note")
        create(:note_comment, :note => note, :visible => false)
        create(:note_comment, :note => note, :body => "Another valid comment for hidden note")
      end

      get note_path(:id => note_with_hidden_comment, :format => "json")
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal note_with_hidden_comment.id, js["properties"]["id"]
      assert_equal 2, js["properties"]["comments"].count
      assert_equal "Valid comment for hidden note", js["properties"]["comments"][0]["text"]
      assert_equal "Another valid comment for hidden note", js["properties"]["comments"][1]["text"]
    end

    def test_show_fail
      get note_path(:id => 12345)
      assert_response :not_found

      get note_path(:id => create(:note, :status => "hidden"))
      assert_response :gone
    end

    def test_destroy_success
      open_note_with_comment = create(:note_with_comments)
      user = create(:user)
      moderator_user = create(:moderator_user)

      delete note_path(:id => open_note_with_comment, :text => "This is a hide comment", :format => "json")
      assert_response :unauthorized

      auth_header = basic_authorization_header user.email, "test"

      delete note_path(:id => open_note_with_comment, :text => "This is a hide comment", :format => "json"), :headers => auth_header
      assert_response :forbidden

      auth_header = basic_authorization_header moderator_user.email, "test"

      delete note_path(:id => open_note_with_comment, :text => "This is a hide comment", :format => "json"), :headers => auth_header
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "Feature", js["type"]
      assert_equal open_note_with_comment.id, js["properties"]["id"]
      assert_equal "hidden", js["properties"]["status"]
      assert_equal 2, js["properties"]["comments"].count
      assert_equal "hidden", js["properties"]["comments"].last["action"]
      assert_equal "This is a hide comment", js["properties"]["comments"].last["text"]
      assert_equal moderator_user.display_name, js["properties"]["comments"].last["user"]

      get note_path(:id => open_note_with_comment, :format => "json"), :headers => auth_header
      assert_response :success

      auth_header = basic_authorization_header user.email, "test"

      get note_path(:id => open_note_with_comment, :format => "json"), :headers => auth_header
      assert_response :gone
    end

    def test_destroy_fail
      user = create(:user)
      moderator_user = create(:moderator_user)

      delete note_path(:id => 12345, :format => "json")
      assert_response :unauthorized

      auth_header = basic_authorization_header user.email, "test"

      delete note_path(:id => 12345, :format => "json"), :headers => auth_header
      assert_response :forbidden

      auth_header = basic_authorization_header moderator_user.email, "test"

      delete note_path(:id => 12345, :format => "json"), :headers => auth_header
      assert_response :not_found

      hidden_note_with_comment = create(:note_with_comments, :status => "hidden")

      delete note_path(:id => hidden_note_with_comment, :format => "json"), :headers => auth_header
      assert_response :gone
    end

    def test_index_success
      position = (1.1 * GeoRecord::SCALE).to_i
      create(:note_with_comments, :latitude => position, :longitude => position)
      create(:note_with_comments, :latitude => position, :longitude => position)

      get notes_path(:bbox => "1,1,1.2,1.2", :format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "description", :text => /1\.2/, :count => 1
          assert_select "item", :count => 2
        end
      end

      get notes_path(:bbox => "1,1,1.2,1.2", :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "FeatureCollection", js["type"]
      assert_equal 2, js["features"].count

      get notes_path(:bbox => "1,1,1.2,1.2", :format => "xml")
      assert_response :success
      assert_equal "application/xml", @response.media_type
      assert_select "osm", :count => 1 do
        assert_select "note", :count => 2
      end

      get notes_path(:bbox => "1,1,1.2,1.2", :format => "gpx")
      assert_response :success
      assert_equal "application/gpx+xml", @response.media_type
      assert_select "gpx", :count => 1 do
        assert_select "wpt", :count => 2
      end
    end

    def test_index_limit
      position = (1.1 * GeoRecord::SCALE).to_i
      create(:note_with_comments, :latitude => position, :longitude => position)
      create(:note_with_comments, :latitude => position, :longitude => position)

      get notes_path(:bbox => "1,1,1.2,1.2", :limit => 1, :format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 1
        end
      end

      get notes_path(:bbox => "1,1,1.2,1.2", :limit => 1, :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "FeatureCollection", js["type"]
      assert_equal 1, js["features"].count

      get notes_path(:bbox => "1,1,1.2,1.2", :limit => 1, :format => "xml")
      assert_response :success
      assert_equal "application/xml", @response.media_type
      assert_select "osm", :count => 1 do
        assert_select "note", :count => 1
      end

      get notes_path(:bbox => "1,1,1.2,1.2", :limit => 1, :format => "gpx")
      assert_response :success
      assert_equal "application/gpx+xml", @response.media_type
      assert_select "gpx", :count => 1 do
        assert_select "wpt", :count => 1
      end
    end

    def test_index_empty_area
      get notes_path(:bbox => "5,5,5.1,5.1", :format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 0
        end
      end

      get notes_path(:bbox => "5,5,5.1,5.1", :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "FeatureCollection", js["type"]
      assert_equal 0, js["features"].count

      get notes_path(:bbox => "5,5,5.1,5.1", :format => "xml")
      assert_response :success
      assert_equal "application/xml", @response.media_type
      assert_select "osm", :count => 1 do
        assert_select "note", :count => 0
      end

      get notes_path(:bbox => "5,5,5.1,5.1", :format => "gpx")
      assert_response :success
      assert_equal "application/gpx+xml", @response.media_type
      assert_select "gpx", :count => 1 do
        assert_select "wpt", :count => 0
      end
    end

    def test_index_large_area
      get notes_path(:bbox => "-2.5,-2.5,2.5,2.5", :format => :json)
      assert_response :success
      assert_equal "application/json", @response.media_type

      get notes_path(:l => "-2.5", :b => "-2.5", :r => "2.5", :t => "2.5", :format => :json)
      assert_response :success
      assert_equal "application/json", @response.media_type

      get notes_path(:bbox => "-10,-10,12,12", :format => :json)
      assert_response :bad_request
      assert_equal "text/plain", @response.media_type

      get notes_path(:l => "-10", :b => "-10", :r => "12", :t => "12", :format => :json)
      assert_response :bad_request
      assert_equal "text/plain", @response.media_type
    end

    def test_index_closed
      create(:note_with_comments, :status => "closed", :closed_at => Time.now.utc - 5.days)
      create(:note_with_comments, :status => "closed", :closed_at => Time.now.utc - 100.days)
      create(:note_with_comments, :status => "hidden")
      create(:note_with_comments)

      # Open notes + closed in last 7 days
      get notes_path(:bbox => "1,1,1.7,1.7", :closed => "7", :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "FeatureCollection", js["type"]
      assert_equal 2, js["features"].count

      # Only open notes
      get notes_path(:bbox => "1,1,1.7,1.7", :closed => "0", :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "FeatureCollection", js["type"]
      assert_equal 1, js["features"].count

      # Open notes + all closed notes
      get notes_path(:bbox => "1,1,1.7,1.7", :closed => "-1", :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "FeatureCollection", js["type"]
      assert_equal 3, js["features"].count
    end

    def test_index_bad_params
      get notes_path(:bbox => "-2.5,-2.5,2.5")
      assert_response :bad_request

      get notes_path(:bbox => "-2.5,-2.5,2.5,2.5,2.5")
      assert_response :bad_request

      get notes_path(:b => "-2.5", :r => "2.5", :t => "2.5")
      assert_response :bad_request

      get notes_path(:l => "-2.5", :r => "2.5", :t => "2.5")
      assert_response :bad_request

      get notes_path(:l => "-2.5", :b => "-2.5", :t => "2.5")
      assert_response :bad_request

      get notes_path(:l => "-2.5", :b => "-2.5", :r => "2.5")
      assert_response :bad_request

      get notes_path(:bbox => "1,1,1.7,1.7", :limit => "0", :format => "json")
      assert_response :bad_request

      get notes_path(:bbox => "1,1,1.7,1.7", :limit => "10001", :format => "json")
      assert_response :bad_request
    end

    def test_search_success
      create(:note_with_comments)

      get search_notes_path(:q => "note comment", :format => "xml")
      assert_response :success
      assert_equal "application/xml", @response.media_type
      assert_select "osm", :count => 1 do
        assert_select "note", :count => 1
      end

      get search_notes_path(:q => "note comment", :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "FeatureCollection", js["type"]
      assert_equal 1, js["features"].count

      get search_notes_path(:q => "note comment", :format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 1
        end
      end

      get search_notes_path(:q => "note comment", :format => "gpx")
      assert_response :success
      assert_equal "application/gpx+xml", @response.media_type
      assert_select "gpx", :count => 1 do
        assert_select "wpt", :count => 1
      end
    end

    def test_search_by_display_name_success
      user = create(:user)

      create(:note) do |note|
        create(:note_comment, :note => note, :author => user)
      end

      get search_notes_path(:display_name => user.display_name, :format => "xml")
      assert_response :success
      assert_equal "application/xml", @response.media_type
      assert_select "osm", :count => 1 do
        assert_select "note", :count => 1
      end

      get search_notes_path(:display_name => user.display_name, :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "FeatureCollection", js["type"]
      assert_equal 1, js["features"].count

      get search_notes_path(:display_name => user.display_name, :format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 1
        end
      end

      get search_notes_path(:display_name => user.display_name, :format => "gpx")
      assert_response :success
      assert_equal "application/gpx+xml", @response.media_type
      assert_select "gpx", :count => 1 do
        assert_select "wpt", :count => 1
      end
    end

    def test_search_by_user_success
      user = create(:user)

      create(:note) do |note|
        create(:note_comment, :note => note, :author => user)
      end

      get search_notes_path(:user => user.id, :format => "xml")
      assert_response :success
      assert_equal "application/xml", @response.media_type
      assert_select "osm", :count => 1 do
        assert_select "note", :count => 1
      end

      get search_notes_path(:user => user.id, :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "FeatureCollection", js["type"]
      assert_equal 1, js["features"].count

      get search_notes_path(:user => user.id, :format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 1
        end
      end

      get search_notes_path(:user => user.id, :format => "gpx")
      assert_response :success
      assert_equal "application/gpx+xml", @response.media_type
      assert_select "gpx", :count => 1 do
        assert_select "wpt", :count => 1
      end
    end

    def test_search_no_match
      create(:note_with_comments)

      get search_notes_path(:q => "no match", :format => "xml")
      assert_response :success
      assert_equal "application/xml", @response.media_type
      assert_select "osm", :count => 1 do
        assert_select "note", :count => 0
      end

      get search_notes_path(:q => "no match", :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "FeatureCollection", js["type"]
      assert_equal 0, js["features"].count

      get search_notes_path(:q => "no match", :format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 0
        end
      end

      get search_notes_path(:q => "no match", :format => "gpx")
      assert_response :success
      assert_equal "application/gpx+xml", @response.media_type
      assert_select "gpx", :count => 1 do
        assert_select "wpt", :count => 0
      end
    end

    def test_search_by_time_no_match
      create(:note_with_comments)

      get search_notes_path(:from => "01.01.2010", :to => "01.10.2010", :format => "xml")
      assert_response :success
      assert_equal "application/xml", @response.media_type
      assert_select "osm", :count => 1 do
        assert_select "note", :count => 0
      end

      get search_notes_path(:from => "01.01.2010", :to => "01.10.2010", :format => "json")
      assert_response :success
      assert_equal "application/json", @response.media_type
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal "FeatureCollection", js["type"]
      assert_equal 0, js["features"].count

      get search_notes_path(:from => "01.01.2010", :to => "01.10.2010", :format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 0
        end
      end

      get search_notes_path(:from => "01.01.2010", :to => "01.10.2010", :format => "gpx")
      assert_response :success
      assert_equal "application/gpx+xml", @response.media_type
      assert_select "gpx", :count => 1 do
        assert_select "wpt", :count => 0
      end
    end

    def test_search_bad_params
      get search_notes_path(:q => "no match", :limit => "0", :format => "json")
      assert_response :bad_request

      get search_notes_path(:q => "no match", :limit => "10001", :format => "json")
      assert_response :bad_request

      get search_notes_path(:display_name => "non-existent")
      assert_response :bad_request

      get search_notes_path(:user => "-1")
      assert_response :bad_request

      get search_notes_path(:from => "wrong-date", :to => "wrong-date")
      assert_response :bad_request

      get search_notes_path(:from => "01.01.2010", :to => "2010.01.2010")
      assert_response :bad_request
    end

    def test_feed_success
      position = (1.1 * GeoRecord::SCALE).to_i
      create(:note_with_comments, :latitude => position, :longitude => position)
      create(:note_with_comments, :latitude => position, :longitude => position)
      position = (1.5 * GeoRecord::SCALE).to_i
      create(:note_with_comments, :latitude => position, :longitude => position)
      create(:note_with_comments, :latitude => position, :longitude => position)

      get feed_notes_path(:format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "item", :count => 4
        end
      end

      get feed_notes_path(:bbox => "1,1,1.2,1.2", :format => "rss")
      assert_response :success
      assert_equal "application/rss+xml", @response.media_type
      assert_select "rss", :count => 1 do
        assert_select "channel", :count => 1 do
          assert_select "description", :text => /1\.2/, :count => 1
          assert_select "item", :count => 2
        end
      end
    end

    def test_feed_fail
      get feed_notes_path(:bbox => "1,1,1.2", :format => "rss")
      assert_response :bad_request

      get feed_notes_path(:bbox => "1,1,1.2,1.2,1.2", :format => "rss")
      assert_response :bad_request

      get feed_notes_path(:bbox => "1,1,1.2,1.2", :limit => "0", :format => "rss")
      assert_response :bad_request

      get feed_notes_path(:bbox => "1,1,1.2,1.2", :limit => "10001", :format => "rss")
      assert_response :bad_request
    end
  end
end
