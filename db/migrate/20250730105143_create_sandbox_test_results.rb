class CreateSandboxTestResults < ActiveRecord::Migration[8.0]
  def change
    create_table :sandbox_test_results do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :test_timestamp
      t.integer :total_tests
      t.integer :passed_tests
      t.integer :failed_tests
      t.decimal :success_rate
      t.text :test_data

      t.timestamps
    end
  end
end
