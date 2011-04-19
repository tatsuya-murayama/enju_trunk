require 'spec_helper'

describe TagsController do

  describe "GET index" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      it "assigns all tags as @tags" do
        get :index
        assigns(:tags).should_not be_nil
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      it "assigns all tags as @tags" do
        get :index
        assigns(:tags).should_not be_nil
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      it "assigns all tags as @tags" do
        get :index
        assigns(:tags).should_not be_nil
      end
    end

    describe "When not logged in" do
      it "assigns all tags as @tags" do
        get :index
        assigns(:tags).should_not be_nil
      end
    end
  end

  describe "GET show" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      it "assigns the requested tag as @tag" do
        tag = Factory.create(:tag)
        get :show, :id => tag.id
        assigns(:tag).should eq(tag)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      it "assigns the requested tag as @tag" do
        tag = Factory.create(:tag)
        get :show, :id => tag.id
        assigns(:tag).should eq(tag)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      it "assigns the requested tag as @tag" do
        tag = Factory.create(:tag)
        get :show, :id => tag.id
        assigns(:tag).should eq(tag)
      end
    end

    describe "When not logged in" do
      it "assigns the requested tag as @tag" do
        tag = Factory.create(:tag)
        get :show, :id => tag.id
        assigns(:tag).should eq(tag)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      it "assigns the requested tag as @tag" do
        tag = Factory.create(:tag)
        get :edit, :id => tag.id
        assigns(:tag).should eq(tag)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      it "assigns the requested tag as @tag" do
        tag = Factory.create(:tag)
        get :edit, :id => tag.id
        assigns(:tag).should eq(tag)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      it "assigns the requested tag as @tag" do
        tag = Factory.create(:tag)
        get :edit, :id => tag.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested tag as @tag" do
        tag = Factory.create(:tag)
        get :edit, :id => tag.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @tag = Factory(:tag)
      @attrs = Factory.attributes_for(:tag)
      @invalid_attrs = {:name => ''}
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      describe "with valid params" do
        it "updates the requested tag" do
          put :update, :id => @tag.id, :tag => @attrs
        end

        it "assigns the requested tag as @tag" do
          put :update, :id => @tag.id, :tag => @attrs
          assigns(:tag).should eq(@tag)
          response.should redirect_to(assigns(:tag))
        end
      end

      describe "with invalid params" do
        it "assigns the requested tag as @tag" do
          put :update, :id => @tag.id, :tag => @invalid_attrs
        end

        it "re-renders the 'edit' template" do
          put :update, :id => @tag.id, :tag => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      describe "with valid params" do
        it "updates the requested tag" do
          put :update, :id => @tag.id, :tag => @attrs
        end

        it "assigns the requested tag as @tag" do
          put :update, :id => @tag.id, :tag => @attrs
          assigns(:tag).should eq(@tag)
          response.should redirect_to(assigns(:tag))
        end
      end

      describe "with invalid params" do
        it "assigns the tag as @tag" do
          put :update, :id => @tag.id, :tag => @invalid_attrs
          assigns(:tag).should_not be_valid
        end

        it "re-renders the 'edit' template" do
          put :update, :id => @tag.id, :tag => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      describe "with valid params" do
        it "updates the requested tag" do
          put :update, :id => @tag.id, :tag => @attrs
        end

        it "assigns the requested tag as @tag" do
          put :update, :id => @tag.id, :tag => @attrs
          assigns(:tag).should eq(@tag)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested tag as @tag" do
          put :update, :id => @tag.id, :tag => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested tag" do
          put :update, :id => @tag.id, :tag => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @tag.id, :tag => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested tag as @tag" do
          put :update, :id => @tag.id, :tag => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @tag = Factory(:tag)
    end

    describe "When logged in as Administrator" do
      before(:each) do
        sign_in Factory(:admin)
      end

      it "destroys the requested tag" do
        delete :destroy, :id => @tag.id
      end

      it "redirects to the tags list" do
        delete :destroy, :id => @tag.id
        response.should redirect_to(tags_url)
      end
    end

    describe "When logged in as Librarian" do
      before(:each) do
        sign_in Factory(:librarian)
      end

      it "destroys the requested tag" do
        delete :destroy, :id => @tag.id
      end

      it "redirects to the tags list" do
        delete :destroy, :id => @tag.id
        response.should redirect_to(tags_url)
      end
    end

    describe "When logged in as User" do
      before(:each) do
        sign_in Factory(:user)
      end

      it "destroys the requested tag" do
        delete :destroy, :id => @tag.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @tag.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested tag" do
        delete :destroy, :id => @tag.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @tag.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end