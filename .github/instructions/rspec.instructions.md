---
applyTo: "spec/**/*_spec.rb"
---

# RSpec Testing Instructions

When writing or modifying RSpec tests in this project, follow these guidelines:

## Test Structure - 4-Phase Pattern

Always use the 4-phase test pattern to organize your tests:

1. **Setup** - Prepare test data and dependencies
2. **Exercise** - Execute the code under test
3. **Verify** - Assert the expected outcomes
4. **Teardown** - Clean up (usually handled by RSpec automatically)

## Required Patterns

### Named Subjects

Always use named subjects instead of anonymous ones:

```ruby
# Good
subject(:config) { described_class.new }

# Avoid
subject { described_class.new }
```

### Aggregate Failures

Use `aggregate_failures` for multiple related assertions to see all failures at once:

```ruby
it "validates all attributes" do
  aggregate_failures do
    expect(object.name).to eq("expected name")
    expect(object.age).to eq(25)
    expect(object.email).to eq("email@example.com")
  end
end
```

### Let Blocks for Test Data

Use `let` for defining test data that may be reused:

```ruby
let(:username) { "testuser" }
let(:config) { build_config(username: username) }
```

## Ruby Testing Best Practices

- Use descriptive test names that explain the behavior being tested
- Keep tests focused on a single behavior
- Use `context` blocks to group related scenarios
- Prefer `describe` for methods and `context` for different states/conditions
- Use `before` blocks sparingly and only for essential setup
- Mock external dependencies to keep tests fast and isolated
- Aim for test coverage above 80%
- Use `expect` syntax (not `should`)
- Be explicit with expectations - avoid implicit subject when possible

## Example Test Structure

```ruby
RSpec.describe MyClass do
  subject(:my_instance) { described_class.new(attribute: value) }
  
  let(:value) { "test value" }
  
  describe "#method_name" do
    context "when condition is true" do
      let(:condition) { true }
      
      it "performs expected behavior" do
        # Setup (if needed beyond let/subject)
        additional_setup if needed
        
        # Exercise
        result = my_instance.method_name
        
        # Verify
        aggregate_failures do
          expect(result).to eq(expected_value)
          expect(my_instance.state).to eq(expected_state)
        end
        
        # Teardown (usually automatic)
      end
    end
    
    context "when condition is false" do
      let(:condition) { false }
      
      it "handles the alternative case" do
        # ...
      end
    end
  end
end
```

## Coverage Requirements

- Maintain minimum 80% line coverage (enforced by SimpleCov)
- Test both happy paths and error cases
- Include edge cases and boundary conditions
