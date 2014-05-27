# Context-scope "let" for RSpec

Do you love how RSpec's `let` method allows you to DRY up your tests and
clean up your code?  Do you hate how slow your tests get when they re-run
the operation under test over, and over, and over again?  Does the conflict
between these two feelings cause you to break out in hives?

Well, put away the antihistamines, because `rspec-context-let` has the
answer to your prayers:

    require 'rspec-context-let'

    describe MyAPI do
      context "when called" do
        clet(:response) do
          MyAPI.call
        end
        
        it "makes a response" do
          expect(response).to_not be(nil)
        end
        
        it "returns a hash" do
          expect(response).to be_a(Hash)
        end
        
        it "returns at least three records" do
          expect(response.length).to be >= 3
        end
      end
    end

By wrapping your expensive operations in a `clet` ("Context LET") call,
rather than a regular `let` call, the result will be cached for the
entireity of that context's existence, rather than being recalculated for
every example.  Other than that little detail, a variable set by `clet`
should work pretty much identically to a variable set by `let` -- it's
available in all your examples, it's available in sub-contexts (and won't be
re-run in those sub-contexts), and it's available in shared example groups
(if you rely on `let`ted variables in there, which I don't really
recommend).

If you're wondering why this useful, consider what happens if the above
`MyAPI.call` takes, say, 100ms to run.  In that case, using `clet` instead
of `let` has just saved you 200ms every time you run the above test cases. 
Multiply that by the 15 or 20 examples you might actually have for a given
piece of test code, and the dozens or hundreds of times a day you run your
test suites, and damn it adds up.  As a real-world testimonial, the test
suite in which `clet` was first developed had 405 examples at the time;
before `clet`, it took an average of **20.54 seconds** to run; afterwards,
it took **7.66 seconds**.  (Averages taken from 25 runs of each suite on an
otherwise idle machine)

Despite the indisputable awesomeness of the above, everything isn't *quite*
perfection.  With the code under test only being run once, anything that
gets reset between examples can't be examined to verify the tested code did
the right thing.  Using instance variables, for example, probably won't do
what you want:

    require 'rspec-context-let'

    describe MyAPI do
      context "when called" do
        clet(:response) do
          @prev_value = MyAPI.get_value
          MyAPI.call
        end
        
        it "makes a response" do
          expect(response).to_not be(nil)
        end
        
        it "changes value" do
          # THIS WILL FAIL SPECTACULARLY
          expect(MyAPI.get_value).to_not eq(@prev_value)
        end
      end
    end

The problem here is that `@prev_value` will get set when the block passed to
`clet` runs... which will be for the `"makes a response"` example.  By the
time the `"changes value"` example runs, that instance variable is dead and
buried.

Another problem that has bitten me in the past is using DB transactions to
clean up database changes after every example:

    require 'rspec-context-let'

    RSpec.configure do |c|
      c.around do |example|
        DB.transaction(
             :rollback => :always,
             :auto_savepoint => true
           ) { example.run }
      end
    end
    
    describe MyAPI do
      context "when called" do
        clet(:response) do
          MyAPI.call
        end
        
        it "makes a response" do
          expect(response).to_not be(nil)
        end
        
        it "does something to the database" do
          # THIS WON'T END WELL EITHER
          expect(DB[:dataz].first.id).to eq("d00d")
        end
      end
    end

This fails for much the same reason as the instance variable case.  The
database got changed when `MyAPI.call` ran, but at the end of that first
example the DB transaction got rolled back and the change was no longer
there when the second example ran.

Depending on your circumstances, you should either use a regular `let` in
these circumstances, or else wrap the call to the code under test into the
same `clet` call as captures the data you wish to examine.  In the database
case, you might do that with:

    require 'rspec-context-let'

    describe MyAPI do
      context "when called" do
        clet(:response) do
          MyAPI.call
        end
        
        clet(:dbdata) do
          MyAPI.call
          DB[:dataz].first
        end
        
        it "makes a response" do
          expect(response).to_not be(nil)
        end
        
        it "does something to the database" do
          expect(dbdata.id).to eq("d00d")
        end
      end
    end
