module TimecopHelpers
  def freeze_time!
    send(:before) { Timecop.freeze(Time.local(2014)) }
    send(:after) { Timecop.return }
  end
end
