# -*- encoding : utf-8 -*-
require "spec_helper"

describe Refinery do
  describe "Synchronizations" do
    describe "Public" do
      describe "synchronizations" do

        describe "synchronizations list as json" do
          before(:each) do
            FactoryGirl.create(:synchronization, :model_name => "WalkIn", :method_name => "update")
            FactoryGirl.create(:synchronization, :model_name => "WalkIn", :method_name => "delete")
          end

          it "shows two items" do
            visit "/synchronizations.json"
            page.should have_content("\"model_name\":\"WalkIn\"")
            page.should have_content("\"method_name\":\"update\"")
            page.should have_content("\"model_updated_at\":\"")
            json = JSON.parse(page.source)
            json.should have(2).things
          end
        end

      end
    end
  end
end
