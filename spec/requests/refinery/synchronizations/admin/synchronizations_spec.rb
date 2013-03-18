# -*- encoding : utf-8 -*-
require "spec_helper"

describe Refinery do
  describe "Synchronizations" do
    describe "Admin" do
      describe "synchronizations" do
        login_refinery_user

        describe "synchronizations list" do
          before(:each) do
            FactoryGirl.create(:synchronization, :model_name => "UniqueTitleOne")
            FactoryGirl.create(:synchronization, :model_name => "UniqueTitleTwo")
          end

          it "shows two items" do
            visit refinery.synchronizations_admin_synchronizations_path
            page.should have_content("UniqueTitleOne")
            page.should have_content("UniqueTitleTwo")
          end
        end

        #describe "create" do
        #  before(:each) do
        #    visit refinery.synchronizations_admin_synchronizations_path

        #    click_link "Add New Synchronization"
        #  end

        #  context "valid data" do
        #    it "should succeed" do
        #      fill_in "Model Name", :with => "This is a test of the first string field"
        #      click_button "Save"

        #      page.should have_content("'This is a test of the first string field' was successfully added.")
        #      Refinery::Synchronizations::Synchronization.count.should == 1
        #    end
        #  end

        #  context "invalid data" do
        #    it "should fail" do
        #      click_button "Save"

        #      page.should have_content("Model Name can't be blank")
        #      Refinery::Synchronizations::Synchronization.count.should == 0
        #    end
        #  end

        #  #context "duplicate" do
        #  #  before(:each) { FactoryGirl.create(:synchronization, :model_name => "UniqueTitle") }

        #  #  it "should fail" do
        #  #    visit refinery.synchronizations_admin_synchronizations_path

        #  #    click_link "Add New Synchronization"

        #  #    fill_in "Model Name", :with => "UniqueTitle"
        #  #    click_button "Save"

        #  #    page.should have_content("There were problems")
        #  #    Refinery::Synchronizations::Synchronization.count.should == 1
        #  #  end
        #  #end

        #end

        #describe "edit" do
        #  before(:each) { FactoryGirl.create(:synchronization, :model_name => "A model_name") }

        #  it "should succeed" do
        #    visit refinery.synchronizations_admin_synchronizations_path

        #    within ".actions" do
        #      click_link "Edit this synchronization"
        #    end

        #    fill_in "Model Name", :with => "A different model_name"
        #    click_button "Save"

        #    page.should have_content("'A different model_name' was successfully updated.")
        #    page.should have_no_content("A model_name")
        #  end
        #end

        #describe "destroy" do
        #  before(:each) { FactoryGirl.create(:synchronization, :model_name => "UniqueTitleOne") }

        #  it "should succeed" do
        #    visit refinery.synchronizations_admin_synchronizations_path

        #    click_link "Remove this synchronization forever"

        #    page.should have_content("'UniqueTitleOne' was successfully removed.")
        #    Refinery::Synchronizations::Synchronization.count.should == 0
        #  end
        #end

      end
    end
  end
end
