require 'test_helper'

class TableT  est < ActiveSupport::TestCase
  # include AppMockHelper
  # mock_app

  def test_columns
    table = ActiveList::Definition::Table.new(:contacts)
    assert_equal 0, table.columns.size

    table.column :address
    assert_equal 1, table.columns.size
  end
end
