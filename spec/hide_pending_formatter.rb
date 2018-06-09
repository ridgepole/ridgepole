class HidePendingFormatter < RSpec::Core::Formatters::ProgressFormatter
  RSpec::Core::Formatters.register self, :example_pending
  RSpec::Core::Formatters.register self, :dump_pending
  def example_pending(notification); end

  def dump_pending(notification); end
end
