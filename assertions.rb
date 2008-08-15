# Useful w/ Rails
def assert_invalid(record, message=nil)
  full_msg = build_message(message, "<?> is valid.", record)
  assert_block(full_msg) { !record.valid? }
end
