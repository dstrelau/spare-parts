require 'try'
require 'test/unit'
require 'pretty_tests'

class TryTest < Test::Unit::TestCase
  test "should succeed when trying method on object" do
    assert_equal 5, "hello".try(:length)
  end

  test "should fail when trying non-method on object" do
    assert_raises(NoMethodError) { "hello".try(:does_not_exist) }
  end

  test "should return nil when trying non-method on nil" do
    assert_nil nil.try(:does_not_exist)
  end

  test "return nil when calling any method on nil" do
    assert_nil nil.try(:to_s)
  end
end