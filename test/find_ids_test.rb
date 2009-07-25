require 'test/unit'

require 'rubygems'
require 'active_record'
require 'mocha'

require File.join(File.dirname(__FILE__), '../lib/find_ids')
require File.join(File.dirname(__FILE__), '../init')

class FindIdsTest < Test::Unit::TestCase
    
  def test_find__all_ids
    ActiveRecord::Base.expects(:find_every_id).with(:conditions => "1").once
    ActiveRecord::Base.expects(:find_without_find_ids).never
    ActiveRecord::Base.find(:all_ids, :conditions => "1")
  end

  def test_find__first_id
    ActiveRecord::Base.expects(:find_initial_id).with(:conditions => "1").once
    ActiveRecord::Base.expects(:find_without_find_ids).never
    ActiveRecord::Base.find(:first_id, :conditions => "1")
  end

  def test_find__last_id
    ActiveRecord::Base.expects(:find_last_id).with(:conditions => "1").once
    ActiveRecord::Base.expects(:find_without_find_ids).never
    ActiveRecord::Base.find(:last_id, :conditions => "1")
  end

  def test_find__falls_through_to_original_method
    ActiveRecord::Base.expects(:find_every_id).never
    ActiveRecord::Base.expects(:find_without_find_ids).with(:all, :conditions => "1").once
    ActiveRecord::Base.find(:all, :conditions => "1")
  end

end
