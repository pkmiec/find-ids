module FindIds
  
  def self.included(base)
    base.send(:extend, ClassMethods)
    base.class_eval do
      class << self
        alias_method_chain :find, :find_ids
        alias_method_chain :method_missing, :find_ids
      end
    end
  end

  module ClassMethods
    
    def find_with_find_ids(*args)
      if ![ :all_ids, :first_id, :last_id ].include?(args.first)
        return find_without_find_ids(*args)
      end
      
      options = args.extract_options!
      validate_find_options(options)
        
      case args.first
        when :first_id then find_initial_id(options)
        when :last_id  then find_last_id(options)
        when :all_ids  then find_every_id(options)
      end
    end

    def method_missing_with_find_ids(method_id, *arguments)
      if match = matches_dynamic_ids_finder?(method_id)
        finder = determine_ids_finder(match)
        
        attribute_names = extract_attribute_names_from_match(match)
        method_missing_without_find_ids(method_id, *arguments) unless all_attributes_exists?(attribute_names)
        
        self.class_eval %{
          def self.#{method_id}(*args)
            options = args.extract_options!
            attributes = construct_attributes_from_arguments([:#{attribute_names.join(',:')}], args)
            finder_options = { :conditions => attributes }
            validate_find_options(options)

            if options[:conditions]
              with_scope(:find => finder_options) do
                ActiveSupport::Deprecation.silence { send(:#{finder}, options) }
              end
            else
              ActiveSupport::Deprecation.silence { send(:#{finder}, options.merge(finder_options)) }
            end
          end
        }, __FILE__, __LINE__
        send(method_id, *arguments)
      else
        method_missing_without_find_ids(method_id, *arguments)
      end
    end

    private

    def find_initial_id(options)
      options.update(:limit => 1)
      find_every_id(options).first
    end

    def find_last_id(options)
      order = options[:order]

      if order
        order = reverse_sql_order(order)
      elsif !scoped?(:find, :order)
        order = "#{table_name}.#{primary_key} DESC"
      end

      if scoped?(:find, :order)
        scoped_order = reverse_sql_order(scope(:find, :order))
        scoped_methods.select { |s| s[:find].update(:order => scoped_order) }
      end

      find_initial_id(options.merge({ :order => order }))
    end

    def find_every_id(options)
      options[:select] = "#{quoted_table_name}.#{primary_key}"
      connection.select_values(sanitize_sql(construct_finder_sql(options)), "#{name} Load Ids").map(&:to_i)
    end

    def matches_dynamic_ids_finder?(method_id)
      /^find_(all_ids_by|id_by)_([_a-zA-Z]\w*)$/.match(method_id.to_s)
    end
    
    def determine_ids_finder(match)
      match.captures.first == 'all_ids_by' ? :find_every_id : :find_initial_id
    end

  end
  
end