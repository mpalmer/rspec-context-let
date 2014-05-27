require 'rspec/core'

module RSpec
	module ContextLet
		module ClassMethods
			class UnevaluatedValue; end
		
			def clet(name, &block)
				raise "#clet called without a block" if block.nil?
				name = name.to_sym
				
				RSpec::Core::MemoizedHelpers.module_for(self).send(:define_method, name, &block)
				
				@__context_memo ||= {}
				@__context_memo[name] = [UnevaluatedValue, block]
				
				define_method(name) do
					klass = self.class

					until klass.nil?
						cm = klass.instance_variable_get(:@__context_memo)
						if cm.is_a?(Hash) and cm.has_key?(name)
							if cm[name].is_a?(Array) and cm[name][0] == UnevaluatedValue
								cm[name] = super(&nil)
								return cm[name]
							else
								return cm[name]
							end
						else
							rklass = klass.name.reverse.split("::", 2)[1]
							klass = rklass.nil? ? nil : eval(rklass.reverse)
						end
					end
				end
			end
		end
	end
end
