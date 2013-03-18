# -*- encoding : utf-8 -*-
require 'spec_helper'

module Refinery
  module Synchronizations
    describe Synchronization do
      describe "validations" do
        subject do
          @sync = FactoryGirl.create(:synchronization, :model_name => "Synchronization", :method_name => "update")
        end

        it { should be_valid }
        its(:errors) { should be_empty }
        its(:model_name) { should == "Synchronization" }
        its(:method_name) { should == "update" }
      end
      
      describe "validate as_json" do
        subject do
          @sync = FactoryGirl.create(:synchronization, :model_name => "Synchronization", :method_name => "update")
          @sync.as_json["synchronization"]
        end
        
        it { should have(5).things }
        it { should == { "method_name" => "update",  "model_name" => "Synchronization", "id" => 1, "updated_at" => @sync.updated_at, "model_updated_at" => @sync.model_updated_at }  }
        it { should_not have_key(:position) }
      end
      
      describe "validation should fail" do
        subject do
          Synchronization.new()
        end

        it { should_not be_valid }
        #its(:errors) { should have(3).things }
      end
    end
  end
end
