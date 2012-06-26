# This migration comes from refinery_synchronizations (originally 1)
class CreateSynchronizationsSynchronizations < ActiveRecord::Migration

  def up
    create_table :refinery_synchronizations do |t|
      t.string :model_name
      t.string :method_name
      t.datetime :model_updated_at
      t.integer :position

      t.timestamps
    end

  end

  def down
    if defined?(::Refinery::UserPlugin)
      ::Refinery::UserPlugin.destroy_all({:name => "refinerycms-synchronizations"})
    end

    if defined?(::Refinery::Page)
      ::Refinery::Page.delete_all({:link_url => "/synchronizations/synchronizations"})
    end

    drop_table :refinery_synchronizations

  end

end
